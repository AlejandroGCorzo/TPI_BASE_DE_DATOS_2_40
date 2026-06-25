USE GimnasioDB;
GO

-- SUCURSAL
INSERT INTO SUCURSAL (nombre, direccion, hora_inicio, hora_fin) VALUES
('EPYC GYM', 'Calle Falsa 123', '06:00:00', '23:00:00');

-- PERSONA
INSERT INTO PERSONA (id_sucursal, nombre, apellido, fecha_nacimiento, dni, telefono, email) VALUES
(1, 'Arnold', 'Schwarzenegger', '1947-07-30', 12345678, '1155550001', 'arnold@gym.com'),   -- Profesor
(1, 'Ronnie', 'Coleman', '1964-05-13', 23456789, '1155550002', 'ronnie@gym.com'),           -- Profesor
(1, 'Pepe', 'Honguito', '1995-10-10', 34567890, '1155550003', 'pepe@hotmail.com'),          -- Socio plan proximo a vencer
(1, 'Cacho', 'Castaña', '1980-06-11', 45678901, '1155550004', 'cacho@gmail.com'),           -- Socio plan vencido
(1, 'Mariela', 'Funes', '1990-03-22', 56789012, '1155550005', 'mariela@gmail.com'),         -- Socio plan vigente
(1, 'Diego', 'Roldan', '1988-12-01', 67890123, '1155550006', 'diego@gmail.com');            -- Socio plan vigente con descuento

-- PROFESOR
INSERT INTO PROFESOR (id_persona) VALUES
(1), -- Arnold
(2); -- Ronnie

-- SOCIO
INSERT INTO SOCIO (id_persona) VALUES
(3), -- Pepe      → id_socio = 1
(4), -- Cacho     → id_socio = 2
(5), -- Mariela   → id_socio = 3
(6); -- Diego     → id_socio = 4

-- METODO_PAGO
INSERT INTO METODO_PAGO (tipo_metodo, nombre_metodo) VALUES
('Físico', 'Efectivo'),
('Digital', 'MercadoPago'),
('Tarjeta', 'Débito');

-- PLAN
INSERT INTO [PLAN] (nombre, duracion_meses, precio_plan) VALUES
('Plan Musculación', 1, 18000.00),   -- id_plan = 1
('Plan Crossfit', 1, 18000.00),      -- id_plan = 2
('Plan Libre', 1, 25000.00),         -- id_plan = 3
('Plan Libre', 6, 130000.00),        -- id_plan = 4
('Plan Libre', 12, 240000.00);       -- id_plan = 5

-- TURNOS_PROFESOR
INSERT INTO TURNOS_PROFESOR (id_profesor, dia_semana, hora_inicio, hora_fin) VALUES
(1, 'Lunes',    '06:00:00', '12:00:00'),
(1, 'Miercoles','06:00:00', '12:00:00'),
(2, 'Martes',   '14:00:00', '22:00:00'),
(2, 'Jueves',   '14:00:00', '22:00:00');

-- CLASE
INSERT INTO CLASE (id_profesor, dia_semana, hora_inicio, hora_fin, cupomax) VALUES
(1, 'Lunes',    '08:00:00', '09:00:00', 10),  -- id_clase = 1 (Arnold, mañana)
(1, 'Miercoles','08:00:00', '09:00:00', 10),  -- id_clase = 2 (Arnold, mañana)
(2, 'Martes',   '18:00:00', '19:00:00', 10),  -- id_clase = 3 (Ronnie, tarde)
(2, 'Jueves',   '18:00:00', '19:00:00', 10);  -- id_clase = 4 (Ronnie, tarde)

-- PLANES_CLASES (Crossfit, Libre mensual, Libre 6m, Libre 12m dan acceso a clases)
INSERT INTO PLANES_CLASES (id_clase, id_plan) VALUES
(1, 2), (1, 3), (1, 4), (1, 5),
(2, 2), (2, 3), (2, 4), (2, 5),
(3, 2), (3, 3), (3, 4), (3, 5),
(4, 2), (4, 3), (4, 4), (4, 5);

-- PAGO
-- Pepe: plan que vence en 3 días (aparece en socio_proximo_a_vencer)
INSERT INTO PAGO (id_plan, id_metodo, id_socio, fecha_pago, fecha_vencimiento, precio_con_IVA, precio_sin_IVA, pago_final, descuento, motivo_descuento) VALUES
(1, 1, 1, '2026-05-27', '2026-06-27', 18000.00, 14876.03, 18000.00, 0, NULL);

-- Cacho: plan vencido hace 2 meses (aparece como VENCIDO en socio_estado_plan)
INSERT INTO PAGO (id_plan, id_metodo, id_socio, fecha_pago, fecha_vencimiento, precio_con_IVA, precio_sin_IVA, pago_final, descuento, motivo_descuento) VALUES
(2, 2, 2, '2026-03-01', '2026-04-01', 18000.00, 14876.03, 18000.00, 0, NULL);

-- Mariela: plan Libre 6 meses vigente (aparece como VIGENTE)
INSERT INTO PAGO (id_plan, id_metodo, id_socio, fecha_pago, fecha_vencimiento, precio_con_IVA, precio_sin_IVA, pago_final, descuento, motivo_descuento) VALUES
(4, 3, 3, '2026-05-01', '2026-11-01', 130000.00, 107438.02, 124800.00, 4, 'Promo débito');

-- Diego: plan Libre mensual de mayo (vencido) + plan Libre mensual de junio (vigente) para probar historial
INSERT INTO PAGO (id_plan, id_metodo, id_socio, fecha_pago, fecha_vencimiento, precio_con_IVA, precio_sin_IVA, pago_final, descuento, motivo_descuento) VALUES
(3, 1, 4, '2026-05-01', '2026-06-01', 25000.00, 20661.16, 25000.00, 0, NULL);
INSERT INTO PAGO (id_plan, id_metodo, id_socio, fecha_pago, fecha_vencimiento, precio_con_IVA, precio_sin_IVA, pago_final, descuento, motivo_descuento) VALUES
(3, 1, 4, '2026-06-01', '2026-07-01', 25000.00, 20661.16, 22500.00, 10, 'Descuento fidelidad');

-- INGRESO (para mostrar registros autorizados y denegados)
INSERT INTO INGRESO (id_socio, fecha_hora, estado) VALUES
(1, '2026-06-20 08:00:00', 'Autorizado'),
(2, '2026-06-20 09:00:00', 'Denegado: Socio sin plan activo o vigente'),
(3, '2026-06-21 10:00:00', 'Autorizado');

-- INSCRIPTOACLASE (Mariela y Diego inscriptos a clases para mostrar disponibilidad_clases)
INSERT INTO INSCRIPTOACLASE (id_socio, id_clase, fecha_inscripcion) VALUES
(3, 1, '2026-06-15 10:00:00'),  -- Mariela → clase Lunes Arnold
(3, 3, '2026-06-15 11:00:00'),  -- Mariela → clase Martes Ronnie
(4, 1, '2026-06-16 09:00:00');  -- Diego → clase Lunes Arnold
GO
