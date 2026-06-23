USE GimnasioDB;
GO

-- ==========================================================================================
-- 1. PROCEDIMIENTO ALMACENADO: sp_RegistrarPago
-- ==========================================================================================
IF OBJECT_ID('sp_RegistrarPago', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_RegistrarPago;
END
GO

CREATE PROCEDURE sp_RegistrarPago
    @id_socio INT,
    @id_plan INT,
    @id_metodo INT,
    @descuento INT = 0,
    @motivo_descuento VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @precio_plan DECIMAL(10, 2);
    DECLARE @duracion_meses INT;
    DECLARE @fecha_pago DATE = CAST(GETDATE() AS DATE);
    DECLARE @fecha_vencimiento DATE;
    DECLARE @precio_con_IVA DECIMAL(10, 2);
    DECLARE @precio_sin_IVA DECIMAL(10, 2);
    DECLARE @pago_final DECIMAL(10, 2);

    -- Validaciones de existencia de claves foráneas
    IF NOT EXISTS (SELECT 1 FROM SOCIO WHERE id_socio = @id_socio)
    BEGIN
        RAISERROR('Error: El socio especificado no existe.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM [PLAN] WHERE id_plan = @id_plan)
    BEGIN
        RAISERROR('Error: El plan especificado no existe.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM METODO_PAGO WHERE id_metodo = @id_metodo)
    BEGIN
        RAISERROR('Error: El método de pago especificado no existe.', 16, 1);
        RETURN;
    END

    -- Validación del rango de descuento
    IF @descuento < 0 OR @descuento > 100
    BEGIN
        RAISERROR('Error: El porcentaje de descuento debe estar comprendido entre 0 y 100.', 16, 1);
        RETURN;
    END

    -- Obtener datos del plan
    SELECT @precio_plan = precio_plan, @duracion_meses = duracion_meses
    FROM [PLAN]
    WHERE id_plan = @id_plan;

    -- Cálculos de facturación
    SET @precio_con_IVA = @precio_plan;
    SET @precio_sin_IVA = ROUND(@precio_con_IVA / 1.21, 2);
    SET @pago_final = ROUND(@precio_con_IVA * (1.0 - (@descuento / 100.0)), 2);
    SET @fecha_vencimiento = DATEADD(month, @duracion_meses, @fecha_pago);

    -- Inserción del pago dentro de bloque transaccional
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO PAGO (id_plan, id_metodo, id_socio, fecha_pago, fecha_vencimiento, precio_con_IVA, precio_sin_IVA, pago_final, descuento, motivo_descuento)
        VALUES (@id_plan, @id_metodo, @id_socio, @fecha_pago, @fecha_vencimiento, @precio_con_IVA, @precio_sin_IVA, @pago_final, @descuento, @motivo_descuento);

        COMMIT TRANSACTION;
        PRINT 'Pago registrado con éxito.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO


-- ==========================================================================================
-- 2. TRIGGER: trg_ControlCupoClase (en INSCRIPTOACLASE)
-- ==========================================================================================
IF OBJECT_ID('trg_ControlCupoClase', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER trg_ControlCupoClase;
END
GO

CREATE TRIGGER trg_ControlCupoClase
ON INSCRIPTOACLASE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Si no hay registros afectados, salimos prematuramente
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Evaluar si alguna clase superó su capacidad máxima
    IF EXISTS (
        SELECT 1
        FROM (
            SELECT id_clase, COUNT(id_socio) AS total_inscriptos
            FROM INSCRIPTOACLASE
            WHERE id_clase IN (SELECT id_clase FROM inserted)
            GROUP BY id_clase
        ) AS cont
        JOIN CLASE c ON cont.id_clase = c.id_clase
        WHERE cont.total_inscriptos > c.cupomax
    )
    BEGIN
        -- Deshacer la transacción para impedir la inscripción
        ROLLBACK TRANSACTION;
        RAISERROR('Error: No se puede completar la inscripción. Se alcanzó el cupo máximo permitido para esta clase.', 16, 1);
        RETURN;
    END
END;
GO


-- ==========================================================================================
-- 3. TRIGGER: trg_ValidarIngreso (en INGRESO)
-- ==========================================================================================
IF OBJECT_ID('trg_ValidarIngreso', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER trg_ValidarIngreso;
END
GO

CREATE TRIGGER trg_ValidarIngreso
ON INGRESO
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Prevenir bucles infinitos en el trigger
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    -- Actualiza el estado del ingreso según tenga o no un pago cuya fecha de vencimiento siga vigente
    UPDATE i
    SET estado = CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM PAGO p
            WHERE p.id_socio = ins.id_socio
              AND p.fecha_vencimiento >= CAST(ins.fecha_hora AS DATE)
        ) THEN 'Autorizado'
        ELSE 'Denegado'
    END
    FROM INGRESO i
    JOIN inserted ins ON i.id_asistencia = ins.id_asistencia;
END;
GO


-- ==========================================================================================
-- 4. SCRIPTS DE PRUEBA (Para verificación manual en SQL Server)
-- ==========================================================================================
/*
-- NOTA: Asegurate de haber ejecutado previamente 01_DDL_Estructura.sql y 02_DML_Datos.sql.

USE GimnasioDB;
GO

---------------------------------------------------------------------------------------------
-- PRUEBA 1: Procedimiento sp_RegistrarPago
---------------------------------------------------------------------------------------------
-- Intentamos registrar un pago con descuento del 10% para el socio 1 en el plan 1 (Musculación, con id_plan = 1)
EXEC sp_RegistrarPago @id_socio = 1, @id_plan = 1, @id_metodo = 1, @descuento = 10, @motivo_descuento = 'Descuento Alumno';

-- Verificamos que se haya calculado bien el precio final e IVA:
SELECT * FROM PAGO WHERE id_socio = 1;


---------------------------------------------------------------------------------------------
-- PRUEBA 2: Trigger trg_ControlCupoClase
---------------------------------------------------------------------------------------------
-- Verificamos el cupo de una clase (por ejemplo, id_clase = 1 tiene cupomax = 15 en las semillas)
SELECT id_clase, cupomax FROM CLASE WHERE id_clase = 1;

-- Intentamos inscribir socios hasta llenar y desbordar la clase
-- Si intentamos meter inscripciones masivas que superen el cupo de 15, SQL Server arrojará un error
-- y deshará el INSERT.

-- Ejemplo de inserción que debería fallar si sobrepasa el cupo:
-- INSERT INTO INSCRIPTOACLASE (id_socio, id_clase) VALUES (2, 1);


---------------------------------------------------------------------------------------------
-- PRUEBA 3: Trigger trg_ValidarIngreso
---------------------------------------------------------------------------------------------
-- Socio 1 (con plan vigente recién pagado en la Prueba 1):
INSERT INTO INGRESO (id_socio, estado) VALUES (1, 'Pendiente');

-- Socio 2 (sin pagos registrados en las semillas):
INSERT INTO INGRESO (id_socio, estado) VALUES (2, 'Pendiente');

-- Chequeamos los estados asignados por el trigger trg_ValidarIngreso:
SELECT * FROM INGRESO;
-- Deberías ver que el socio 1 quedó 'Autorizado' y el socio 2 quedó 'Denegado'.
*/
