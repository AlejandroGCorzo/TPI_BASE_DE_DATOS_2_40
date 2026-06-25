USE GimnasioDB;
GO

--RECAUDACIÓN MENSUAL
CREATE VIEW recaudacion_mensual AS
SELECT SUM(pago_final) AS recaudacion_total,MONTH(fecha_pago) AS mes, YEAR(fecha_pago) AS año FROM PAGO
GROUP BY MONTH(fecha_pago), YEAR(fecha_pago);

GO

SELECT * FROM recaudacion_mensual;

GO

--PÉRDIDAS MENSUALES
CREATE VIEW perdida_mensual AS
SELECT SUM(precio_con_IVA - pago_final) AS diferencia_total, MONTH(fecha_pago) AS Mes, YEAR(fecha_pago) AS Año FROM PAGO
GROUP BY MONTH(fecha_pago), YEAR(fecha_pago);

GO

SELECT * FROM perdida_mensual;

GO

--RECAUDACIÓN POR MÉTODO DE PAGO
CREATE VIEW recaudacion_metodo_pago AS
SELECT SUM(p.pago_final) AS recaudacion_total, mp.nombre_metodo
FROM PAGO p
INNER JOIN METODO_PAGO mp ON p.id_metodo = mp.id_metodo
GROUP BY mp.nombre_metodo;

GO

SELECT * FROM recaudacion_metodo_pago;

GO


--SOCIOS CON PLAN PRÓXIMO A VENCER (EN LOS PRÓXIMOS 7 DÍAS) (muestra el estado del ultimo plan pagado)
CREATE VIEW socio_proximo_a_vencer AS
SELECT p.fecha_vencimiento, CONCAT(pe.nombre, ' ', pe.apellido) AS nombre_apellido, pe.dni, pe.telefono, pe.email
FROM PAGO p
INNER JOIN SOCIO s ON s.id_socio = p.id_socio
INNER JOIN PERSONA pe ON pe.id_persona = s.id_persona
WHERE DATEDIFF(DAY, GETDATE(), fecha_vencimiento) <= 7 AND DATEDIFF(DAY, GETDATE(), fecha_vencimiento) >= 0 AND
p.fecha_pago = (
    SELECT MAX(fecha_pago) 
    FROM PAGO 
    WHERE id_socio = p.id_socio
);

GO

SELECT * FROM socio_proximo_a_vencer;

GO

--ESTADO DE PLAN DE LOS SOCIOS (muestra el estado del ultimo plan pagado)
CREATE VIEW socio_estado_plan AS
SELECT p.fecha_vencimiento, CONCAT(pe.nombre, ' ', pe.apellido) AS nombre_apellido, pe.dni, pe.telefono, pe.email,
    CASE WHEN DATEDIFF(DAY, GETDATE(), fecha_vencimiento) < 0 THEN 'VENCIDO'
    ELSE 'VIGENTE'
    END AS estado_plan
FROM PAGO p
INNER JOIN SOCIO s ON s.id_socio = p.id_socio
INNER JOIN PERSONA pe ON pe.id_persona = s.id_persona
WHERE p.fecha_pago = (
    SELECT MAX(fecha_pago) 
    FROM PAGO 
    WHERE id_socio = p.id_socio
);

GO

SELECT * FROM socio_estado_plan ORDER BY estado_plan DESC; --muestra primero los vigentes, luego los vencidos

GO

CREATE VIEW disponibilidad_clases AS
SELECT c.dia_semana, CONCAT(CONVERT(VARCHAR(5), c.hora_inicio, 108), ' - ', CONVERT(VARCHAR(5), c.hora_fin, 108)) AS horario, CONCAT(pe.nombre, ' ', pe.apellido) AS profesor, c.cupomax - COUNT(ic.id_inscripto) AS cupos_disponibles
FROM CLASE c  
INNER JOIN PROFESOR p ON p.id_profesor = c.id_profesor
INNER JOIN PERSONA pe ON pe.id_persona = p.id_persona
LEFT JOIN INSCRIPTOACLASE ic ON ic.id_clase = c.id_clase
GROUP BY c.dia_semana, c.hora_inicio, c.hora_fin, pe.nombre, pe.apellido, c.cupomax

GO

SELECT * FROM disponibilidad_clases;

GO

