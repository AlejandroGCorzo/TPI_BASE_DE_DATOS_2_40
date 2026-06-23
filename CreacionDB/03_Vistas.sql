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

--SOCIOS CON PLAN PRÓXIMO A VENCER (EN LOS PRÓXIMOS 7 DÍAS)
CREATE VIEW socio_proximo_a_vencer AS
SELECT p.fecha_vencimiento, CONCAT(pe.nombre, ' ', pe.apellido) AS nombre_apellido, pe.dni, pe.telefono, pe.email
FROM PAGO p
INNER JOIN SOCIO s ON s.id_socio = p.id_socio
INNER JOIN PERSONA pe ON pe.id_persona = s.id_persona
WHERE DATEDIFF(DAY, GETDATE(), fecha_vencimiento) <= 7 AND DATEDIFF(DAY, GETDATE(), fecha_vencimiento) >= 0;

GO

SELECT * FROM socio_proximo_a_vencer;

GO

--SOCIOS CON PLAN VENCIDO
CREATE VIEW socio_plan_vencido AS
SELECT p.fecha_vencimiento, CONCAT(pe.nombre, ' ', pe.apellido) AS nombre_apellido, pe.dni, pe.telefono, pe.email
FROM PAGO p
INNER JOIN SOCIO s ON s.id_socio = p.id_socio
INNER JOIN PERSONA pe ON pe.id_persona = s.id_persona
WHERE DATEDIFF(DAY, GETDATE(), fecha_vencimiento) < 0;

GO

SELECT * FROM socio_plan_vencido;

GO
