USE GimnasioDB;
GO

INSERT INTO SUCURSAL (nombre, direccion, hora_inicio, hora_fin) VALUES
('Gimnasio Los Monstruos', 'Calle Falsa 123', '06:00:00', '23:00:00'),
('Gimnasio Los Fierros', 'Av. Siempreviva 742', '07:00:00', '22:00:00');

INSERT INTO PERSONA (id_sucursal, nombre, apellido, fecha_nacimiento, telefono, email) VALUES
(1, 'Arnold', 'Schwarzenegger', '1947-07-30', '1155550001', 'arnold@gym.com'),
(1, 'Ronnie', 'Coleman', '1964-05-13', '1155550002', 'ronnie@gym.com'),
(1, 'Pepe', 'Honguito', '1995-10-10', '1155550003', 'pepe@hotmail.com'),
(1, 'Cacho', 'Castaña', '1980-06-11', '1155550004', 'cacho@gmail.com');

INSERT INTO PROFESOR (id_sucursal, id_persona) VALUES
(1, 1),
(1, 2);

INSERT INTO SOCIO (id_sucursal, id_persona) VALUES
(1, 3),
(1, 4);

INSERT INTO INGRESO (id_sucursal, id_persona, id_socio, fecha_hora, estado) VALUES
(1, 3, 1, '2026-06-18 08:00:00', 'Permitido'),
(1, 4, 2, '2026-06-18 09:30:00', 'Permitido');

INSERT INTO METODO_PAGO (tipo_metodo, nombre_metodo) VALUES
('Físico', 'Efectivo USD'),
('Digital', 'MercadoPago'),
('Cripto', 'USDC Red Solana');

INSERT INTO [PLAN] (nombre, duracion_meses, precio_plan) VALUES
('Plan Hulk', 1, 15000.00),
('Plan Saiyajin', 6, 80000.00);

INSERT INTO PAGO (id_plan, id_metodo, id_sucursal, id_persona, id_socio, fecha_pago, fecha_vencimiento, precio_con_IVA, precio_sin_IVA, pago_final, descuento, motivo_descuento) VALUES
(1, 2, 1, 3, 1, '2026-06-01', '2026-07-01', 15000.00, 12396.69, 15000.00, 0, NULL),
(2, 3, 1, 4, 2, '2026-06-10', '2026-12-10', 80000.00, 66115.70, 75000.00, 5000, 'Promo pago en USDC');

INSERT INTO CLASE (id_sucursal, id_persona, id_profesor, diasemana, hora_inicio, hora_fin, cupomax) VALUES
(1, 1, 1, 'Lunes', '10:00:00', '11:00:00', 20),
(1, 2, 2, 'Miercoles', '18:00:00', '19:00:00', 30);

INSERT INTO PLANES_CLASES (id_sucursal, id_persona, id_profesor, id_clase, id_plan) VALUES
(1, 1, 1, 1, 1),
(1, 2, 2, 2, 2);

INSERT INTO TURNOS_PROFESOR (id_sucursal, id_persona, id_profesor, dia_semana, hora_inicio, hora_fin) VALUES
(1, 1, 1, '2026-06-22', '08:00:00', '14:00:00'),
(1, 2, 2, '2026-06-24', '16:00:00', '22:00:00');

INSERT INTO INSCRIPTOACLASE (id_sucursal_socio, id_persona_socio, id_socio, id_sucursal_clase, id_persona_clase, id_profesor_clase, id_clase, fecha_inscripcion) VALUES
(1, 3, 1, 1, 1, 1, 1, '2026-06-15 10:00:00'),
(1, 4, 2, 1, 2, 2, 2, '2026-06-16 11:30:00');
GO