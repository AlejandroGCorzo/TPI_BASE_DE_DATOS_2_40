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
    
    DECLARE @id_pago_a_desactivar INT = NULL;

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

    -- Si el socio tiene un plan complementario activo, pasa automáticamente a Plan Libre (id_plan = 3)
    IF @id_plan = 1 -- Intenta comprar Plan Musculación
    BEGIN
        SELECT TOP 1 @id_pago_a_desactivar = id_pago
        FROM PAGO
        WHERE id_socio = @id_socio
          AND id_plan = 2 -- Tiene Plan Crossfit activo
          AND fecha_vencimiento >= @fecha_pago
        ORDER BY fecha_vencimiento DESC;

        IF @id_pago_a_desactivar IS NOT NULL
        BEGIN
            SET @id_plan = 3; -- Cambia automáticamente a Plan Libre
        END
    END
    ELSE IF @id_plan = 2 -- Intenta comprar Plan Crossfit
    BEGIN
        SELECT TOP 1 @id_pago_a_desactivar = id_pago
        FROM PAGO
        WHERE id_socio = @id_socio
          AND id_plan = 1 -- Tiene Plan Musculación activo
          AND fecha_vencimiento >= @fecha_pago
        ORDER BY fecha_vencimiento DESC;

        IF @id_pago_a_desactivar IS NOT NULL
        BEGIN
            SET @id_plan = 3; -- Cambia automáticamente a Plan Libre
        END
    END

    -- Obtener datos del plan (ya resuelto, sea el original o el Libre tras la conversión)
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
        
        -- Si hay un plan complementario anterior que desactivar, lo vencemos ayer para evitar solapamientos
        IF @id_pago_a_desactivar IS NOT NULL
        BEGIN
            UPDATE PAGO 
            SET fecha_vencimiento = DATEADD(day, -1, @fecha_pago) 
            WHERE id_pago = @id_pago_a_desactivar;
        END
        
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
-- 1.2. PROCEDIMIENTO ALMACENADO: sp_InscribirSocioClase
-- ==========================================================================================
IF OBJECT_ID('sp_InscribirSocioClase', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_InscribirSocioClase;
END
GO

CREATE PROCEDURE sp_InscribirSocioClase
    @id_socio INT,
    @id_clase INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que el socio exista
    IF NOT EXISTS (SELECT 1 FROM SOCIO WHERE id_socio = @id_socio)
    BEGIN
        RAISERROR('Error: El socio especificado no existe.', 16, 1);
        RETURN;
    END

    -- Validar que la clase exista
    IF NOT EXISTS (SELECT 1 FROM CLASE WHERE id_clase = @id_clase)
    BEGIN
        RAISERROR('Error: La clase especificada no existe.', 16, 1);
        RETURN;
    END

    -- Validar que el socio no esté inscripto previamente en la misma clase
    IF EXISTS (SELECT 1 FROM INSCRIPTOACLASE WHERE id_socio = @id_socio AND id_clase = @id_clase)
    BEGIN
        RAISERROR('Error: El socio ya se encuentra inscripto en esta clase.', 16, 1);
        RETURN;
    END

    -- Validar que el socio tenga un plan activo vigente que cubra la clase (a través de la tabla PLANES_CLASES)
    IF NOT EXISTS (
        SELECT 1
        FROM PAGO p
        JOIN PLANES_CLASES pc ON p.id_plan = pc.id_plan
        WHERE p.id_socio = @id_socio
          AND pc.id_clase = @id_clase
          AND p.fecha_vencimiento >= CAST(GETDATE() AS DATE)
    )
    BEGIN
        RAISERROR('Error: El socio no posee un plan activo y vigente que incluya esta clase.', 16, 1);
        RETURN;
    END

    -- Inserción dentro de bloque transaccional
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO INSCRIPTOACLASE (id_socio, id_clase, fecha_inscripcion)
        VALUES (@id_socio, @id_clase, GETDATE());

        COMMIT TRANSACTION;
        PRINT 'Inscripción realizada con éxito.';
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
-- 1.3. PROCEDIMIENTO ALMACENADO: sp_CancelarInscripcion
-- ==========================================================================================
IF OBJECT_ID('sp_CancelarInscripcion', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_CancelarInscripcion;
END
GO

CREATE PROCEDURE sp_CancelarInscripcion
    @id_socio INT,
    @id_clase INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que el socio exista
    IF NOT EXISTS (SELECT 1 FROM SOCIO WHERE id_socio = @id_socio)
    BEGIN
        RAISERROR('Error: El socio especificado no existe.', 16, 1);
        RETURN;
    END

    -- Validar que la clase exista
    IF NOT EXISTS (SELECT 1 FROM CLASE WHERE id_clase = @id_clase)
    BEGIN
        RAISERROR('Error: La clase especificada no existe.', 16, 1);
        RETURN;
    END

    -- Validar que el socio realmente esté inscripto
    IF NOT EXISTS (SELECT 1 FROM INSCRIPTOACLASE WHERE id_socio = @id_socio AND id_clase = @id_clase)
    BEGIN
        RAISERROR('Error: El socio no se encuentra inscripto en esta clase.', 16, 1);
        RETURN;
    END

    -- Regla de negocio: Validar anticipación de cancelación (mínimo 2 horas antes de la clase si es hoy)
    DECLARE @diasemana VARCHAR(15);
    DECLARE @hora_inicio TIME;
    
    SELECT @diasemana = diasemana, @hora_inicio = hora_inicio
    FROM CLASE
    WHERE id_clase = @id_clase;

    -- Obtener día de hoy en español de forma independiente a la configuración regional
    DECLARE @dia_hoy VARCHAR(15);
    DECLARE @dw INT = (DATEPART(dw, GETDATE()) + @@DATEFIRST - 1) % 7;
    SET @dia_hoy = CASE @dw
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miercoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sabado'
    END;

    IF @diasemana = @dia_hoy
    BEGIN
        -- Si la clase es hoy y falta menos de 2 horas (120 minutos) o ya comenzó/pasó
        IF DATEDIFF(minute, CAST(GETDATE() AS TIME), @hora_inicio) < 120
        BEGIN
            RAISERROR('Error: No se puede cancelar la inscripción con menos de 2 horas de anticipación.', 16, 1);
            RETURN;
        END
    END

    -- Proceso de eliminación transaccional
    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM INSCRIPTOACLASE
        WHERE id_socio = @id_socio AND id_clase = @id_clase;

        COMMIT TRANSACTION;
        PRINT 'Inscripción cancelada con éxito.';
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
-- 1.4. PROCEDIMIENTO ALMACENADO: sp_RegistrarIngreso
-- ==========================================================================================
IF OBJECT_ID('sp_RegistrarIngreso', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_RegistrarIngreso;
END
GO

CREATE PROCEDURE sp_RegistrarIngreso
    @dni INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @id_socio INT;
    
    -- Validar que la persona con ese DNI exista y sea un Socio registrado
    SELECT @id_socio = s.id_socio
    FROM PERSONA p
    JOIN SOCIO s ON p.id_persona = s.id_persona
    WHERE p.dni = @dni;

    IF @id_socio IS NULL
    BEGIN
        RAISERROR('Error: El DNI ingresado no corresponde a ningún socio registrado.', 16, 1);
        RETURN;
    END

    -- Insertar el intento de ingreso
    -- El trigger trg_ValidarIngreso evaluará el horario y la vigencia del plan de forma automática
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO INGRESO (id_socio, fecha_hora, estado)
        VALUES (@id_socio, GETDATE(), 'Pendiente');

        COMMIT TRANSACTION;
        
        -- Mostrar el resultado final del ingreso tras la evaluación del trigger
        DECLARE @estado_resultado VARCHAR(100);
        SELECT @estado_resultado = estado 
        FROM INGRESO 
        WHERE id_asistencia = SCOPE_IDENTITY();
        
        PRINT 'Ingreso registrado. Estado: ' + @estado_resultado;
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
-- 2. TRIGGER: trg_ValidarPlanActivo (en PAGO)
-- ==========================================================================================
IF OBJECT_ID('trg_ValidarPlanActivo', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER trg_ValidarPlanActivo;
END
GO

CREATE TRIGGER trg_ValidarPlanActivo
ON PAGO
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Validar si el socio ya tiene un plan vigente al momento de registrar el nuevo pago que cubra la misma disciplina
    IF EXISTS (
        SELECT 1
        FROM inserted ins
        JOIN [PLAN] new_p ON ins.id_plan = new_p.id_plan
        JOIN PAGO p ON ins.id_socio = p.id_socio
        JOIN [PLAN] old_p ON p.id_plan = old_p.id_plan
        WHERE p.id_pago <> ins.id_pago
          AND p.fecha_vencimiento >= ins.fecha_pago
          AND (
              -- Colisión de disciplina Musculación
              ((new_p.nombre LIKE '%Musculación%' OR new_p.nombre LIKE '%Libre%') AND 
               (old_p.nombre LIKE '%Musculación%' OR old_p.nombre LIKE '%Libre%'))
              OR
              -- Colisión de disciplina Crossfit
              ((new_p.nombre LIKE '%Crossfit%' OR new_p.nombre LIKE '%Libre%') AND 
               (old_p.nombre LIKE '%Crossfit%' OR old_p.nombre LIKE '%Libre%'))
          )
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Error: El socio ya posee un plan activo y vigente que cubre una o más de las disciplinas seleccionadas.', 16, 1);
        RETURN;
    END
END;
GO


-- ==========================================================================================
-- 3. TRIGGER: trg_ControlCupoClase (en INSCRIPTOACLASE)
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
-- 4. TRIGGER: trg_ValidarIngreso (en INGRESO)
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

    -- Actualiza el estado del ingreso según tenga o no un pago vigente y si está en el horario permitido (6:00 a 23:00)
    UPDATE i
    SET estado = CASE 
        -- Validar horario de apertura del gimnasio
        WHEN CAST(ins.fecha_hora AS TIME) < '06:00:00' OR CAST(ins.fecha_hora AS TIME) > '23:00:00' 
            THEN 'Denegado: Fuera de horario de apertura (06:00 - 23:00)'
        
        -- Validar plan vigente
        WHEN NOT EXISTS (
            SELECT 1 
            FROM PAGO p
            WHERE p.id_socio = ins.id_socio
              AND p.fecha_vencimiento >= CAST(ins.fecha_hora AS DATE)
        ) THEN 'Denegado: Socio sin plan activo o vigente'
        
        ELSE 'Autorizado'
    END
    FROM INGRESO i
    JOIN inserted ins ON i.id_asistencia = ins.id_asistencia;
END;
GO


-- ==========================================================================================
-- 5. TRIGGER: trg_ValidarTurnoProfesor (en CLASE)
-- ==========================================================================================
IF OBJECT_ID('trg_ValidarTurnoProfesor', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER trg_ValidarTurnoProfesor;
END
GO

CREATE TRIGGER trg_ValidarTurnoProfesor
ON CLASE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- Validar que la clase esté programada dentro del horario de apertura del gimnasio (06:00 a 23:00)
    IF EXISTS (
        SELECT 1
        FROM inserted ins
        WHERE ins.hora_inicio < '06:00:00' OR ins.hora_fin > '23:00:00'
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Error: Las clases deben programarse dentro del horario de apertura del gimnasio (06:00 a 23:00).', 16, 1);
        RETURN;
    END

    -- Verifica si alguna clase no tiene un turno del profesor asignado que la cubra por completo
    IF EXISTS (
        SELECT 1
        FROM inserted ins
        WHERE NOT EXISTS (
            SELECT 1
            FROM TURNOS_PROFESOR t
            WHERE t.id_profesor = ins.id_profesor
              AND t.dia_semana = ins.diasemana
              AND t.hora_inicio <= ins.hora_inicio
              AND t.hora_fin >= ins.hora_fin
        )
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Error: El profesor no tiene un turno de trabajo registrado que cubra el día y horario de esta clase.', 16, 1);
        RETURN;
    END
END;
GO


-- ==========================================================================================
-- 5. SCRIPTS DE PRUEBA (Para verificación manual en SQL Server)
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
-- PRUEBA 1.1: Trigger trg_ValidarPlanActivo
---------------------------------------------------------------------------------------------
-- Intentamos registrar otro pago para el mismo socio 1 (debería fallar porque su plan sigue activo):
EXEC sp_RegistrarPago @id_socio = 1, @id_plan = 1, @id_metodo = 1, @descuento = 0;


---------------------------------------------------------------------------------------------
-- PRUEBA 1.2: Procedimiento sp_InscribirSocioClase
---------------------------------------------------------------------------------------------
-- Intentamos inscribir al socio 1 a la clase 1:
EXEC sp_InscribirSocioClase @id_socio = 1, @id_clase = 1;

-- Intentamos inscribir de nuevo al socio 1 a la clase 1 (debería fallar por duplicado):
EXEC sp_InscribirSocioClase @id_socio = 1, @id_clase = 1;

-- Verificamos la inscripción en la tabla:
SELECT * FROM INSCRIPTOACLASE WHERE id_socio = 1 AND id_clase = 1;


---------------------------------------------------------------------------------------------
-- PRUEBA 1.3: Procedimiento sp_CancelarInscripcion
---------------------------------------------------------------------------------------------
-- Intentamos cancelar la inscripción del socio 1 a la clase 1 (que creamos en la prueba anterior):
EXEC sp_CancelarInscripcion @id_socio = 1, @id_clase = 1;

-- Intentamos cancelar una inscripción que no existe (debería fallar):
EXEC sp_CancelarInscripcion @id_socio = 1, @id_clase = 999;


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


---------------------------------------------------------------------------------------------
-- PRUEBA 4: Trigger trg_ValidarTurnoProfesor
---------------------------------------------------------------------------------------------
-- Profesor 1 trabaja Lunes y Miercoles de 06:00:00 a 12:00:00 en las semillas.

-- 1. Intentamos crear una clase para Profesor 1 en su horario laboral (debería funcionar):
INSERT INTO CLASE (id_profesor, diasemana, hora_inicio, hora_fin, cupomax)
VALUES (1, 'Lunes', '09:00:00', '10:00:00', 10);

-- 2. Intentamos crear una clase para Profesor 1 fuera de su horario laboral (debería fallar por el trigger):
INSERT INTO CLASE (id_profesor, diasemana, hora_inicio, hora_fin, cupomax)
VALUES (1, 'Lunes', '13:00:00', '14:00:00', 10);

-- 3. Intentamos crear una clase para Profesor 1 en un día que no trabaja (debería fallar por el trigger):
INSERT INTO CLASE (id_profesor, diasemana, hora_inicio, hora_fin, cupomax)
VALUES (1, 'Martes', '09:00:00', '10:00:00', 10);
*/
