USE GimnasioDB;
GO

-- SUCURSAL
INSERT INTO SUCURSAL (nombre, direccion, hora_inicio, hora_fin) VALUES
('Gimnasio Los Monstruos', 'Calle Falsa 123', '06:00:00', '23:00:00'),
('Gimnasio Los Fierros', 'Av. Siempreviva 742', '07:00:00', '22:00:00');

-- PERSONA 
INSERT INTO PERSONA (id_sucursal, nombre, apellido, fecha_nacimiento, dni, telefono, email) VALUES
(1, 'Arnold', 'Schwarzenegger', '1947-07-30', 12345678, '1155550001', 'arnold@gym.com'),
(1, 'Ronnie', 'Coleman', '1964-05-13', 23456789, '1155550002', 'ronnie@gym.com'),
(1, 'Pepe', 'Honguito', '1995-10-10', 34567890, '1155550003', 'pepe@hotmail.com'),
(1, 'Cacho', 'Castaña', '1980-06-11', 45678901, '1155550004', 'cacho@gmail.com'),
(1, 'Mariela', 'Funes', '1990-03-22', 56789012, '1155550005', 'mariela@gmail.com'),
(1, 'Diego', 'Roldan', '1988-12-01', 67890123, '1155550006', 'diego@gmail.com');

-- PROFESOR 
INSERT INTO PROFESOR (id_persona) VALUES
(1), -- Arnold
(2); -- Ronnie

-- SOCIO 
INSERT INTO SOCIO (id_persona) VALUES
(3), -- Pepe
(4), -- Cacho
(5), -- Mariela
(6); -- Diego

-- METODO_PAGO
INSERT INTO METODO_PAGO (tipo_metodo, nombre_metodo) VALUES
('Físico', 'Efectivo'),
('Digital', 'MercadoPago'),
('Tarjeta', 'Débito');

-- PLAN
INSERT INTO [PLAN] (nombre, duracion_meses, precio_plan) VALUES
('Plan Musculación', 1, 15000.00),
('Plan Crossfit', 1, 18000.00),
('Plan Libre', 1, 25000.00),
('Plan Libre 6 Meses', 6, 130000.00),
('Plan Libre 12 Meses', 12, 240000.00);

-- CLASE
INSERT INTO CLASE (id_profesor, diasemana, hora_inicio, hora_fin, cupomax) VALUES
(1, 'Lunes', '08:00:00', '09:00:00', 20),
(1, 'Miercoles', '08:00:00', '09:00:00', 20),
(2, 'Martes', '18:00:00', '19:00:00', 20),
(2, 'Jueves', '18:00:00', '19:00:00', 20);

-- TURNOS_PROFESOR
INSERT INTO TURNOS_PROFESOR (id_profesor, dia_semana, hora_inicio, hora_fin) VALUES
(1, 'Lunes', '06:00:00', '12:00:00'),
(1, 'Miercoles', '06:00:00', '12:00:00'),
(2, 'Martes', '14:00:00', '22:00:00'),
(2, 'Jueves', '14:00:00', '22:00:00');

-- PLANES_CLASES (planes que dan acceso a Crossfit: Crossfit, Libre, Libre 6m, Libre 12m -> ids 2,3,4,5)
INSERT INTO PLANES_CLASES (id_clase, id_plan) VALUES
(1, 2), (1, 3), (1, 4), (1, 5),
(2, 2), (2, 3), (2, 4), (2, 5),
(3, 2), (3, 3), (3, 4), (3, 5),
(4, 2), (4, 3), (4, 4), (4, 5);

-- PAGO 
INSERT INTO PAGO (id_plan, id_metodo, id_socio, fecha_pago, fecha_vencimiento, precio_con_IVA, precio_sin_IVA, pago_final, descuento, motivo_descuento) VALUES
(1, 1, 1, '2026-05-01', '2026-06-01', 15000.00, 12396.69, 15000.00, 0, NULL),
(3, 2, 2, '2026-06-10', '2026-07-10', 25000.00, 20661.16, 25000.00, 0, NULL),
(4, 3, 3, '2026-05-15', '2026-11-15', 130000.00, 107438.02, 125000.00, 5000, 'Promo débito'),
(2, 1, 4, '2026-06-05', '2026-07-05', 18000.00, 14876.03, 18000.00, 0, NULL);

-- INGRESO
INSERT INTO INGRESO (id_socio, fecha_hora, estado) VALUES
(1, '2026-06-18 08:00:00', 'Autorizado'),
(2, '2026-06-18 09:30:00', 'Autorizado'),
(3, '2026-06-18 23:30:00', 'Denegado');

-- INSCRIPTOACLASE (socio 2 tiene plan Libre, socio 3 tiene plan Libre 6m -> ambos pueden anotarse a Crossfit)
INSERT INTO INSCRIPTOACLASE (id_socio, id_clase, fecha_inscripcion) VALUES
(2, 1, '2026-06-15 10:00:00'),
(3, 3, '2026-06-16 11:30:00');
GO