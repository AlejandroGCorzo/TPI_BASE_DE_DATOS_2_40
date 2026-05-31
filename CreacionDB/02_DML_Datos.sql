USE GimnasioDB;
GO

-- Insertar Planes 
INSERT INTO PLANES (Nombre, DuracionMeses, Precio) VALUES
('Musculación Mensual', 1, 15000.00),
('Crossfit Mensual', 1, 18000.00),
('Ambos Mensual', 1, 22000.00),
('Plan Semestral (Ambos)', 6, 110000.00),
('Plan Anual (Ambos)', 12, 200000.00);

-- Insertar Métodos de Pago
INSERT INTO METODOS_PAGO (Descripcion) VALUES
('Efectivo'),
('Débito'),
('Transferencia');

-- Insertar Profesores
INSERT INTO PROFESORES (Nombre, Apellido, Telefono, Email) VALUES
('Juan', 'Perez', '1122334455', 'juan.perez@gimnasio.com'),
('Maria', 'Gomez', '1155443322', 'maria.gomez@gimnasio.com');

-- Insertar Horarios de Clase
INSERT INTO HORARIOS_CLASE (DiaSemana, HoraInicio, CupoMaximo, IdProfesor) VALUES
('Lunes', '18:00', 15, 1),
('Miercoles', '18:00', 15, 1),
('Martes', '19:00', 20, 2),
('Jueves', '19:00', 20, 2);

-- Insertar Socios de prueba
INSERT INTO SOCIOS (DNI, Nombre, Apellido, Telefono, Email, FechaNacimiento, FechaAlta) VALUES
(12345678, 'Carlos', 'Lopez', '1144556677', 'carlos@mail.com', '1990-05-15', '2026-05-01'),
(87654321, 'Ana', 'Martinez', '1199887766', 'ana@mail.com', '1995-10-20', '2026-05-15');