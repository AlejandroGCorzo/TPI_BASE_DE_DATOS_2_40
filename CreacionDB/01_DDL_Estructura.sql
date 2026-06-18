USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'GimnasioDB')
BEGIN
    ALTER DATABASE GimnasioDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GimnasioDB;
END
GO

CREATE DATABASE GimnasioDB;
GO
USE GimnasioDB;
GO

CREATE TABLE SUCURSAL (
    id_sucursal INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL
);

CREATE TABLE PERSONA (
    id_sucursal INT NOT NULL,
    id_persona INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100),
    PRIMARY KEY (id_sucursal, id_persona),
    FOREIGN KEY (id_sucursal) REFERENCES SUCURSAL(id_sucursal)
);

CREATE TABLE SOCIO (
    id_sucursal INT NOT NULL,
    id_persona INT NOT NULL,
    id_socio INT IDENTITY(1,1) NOT NULL,
    PRIMARY KEY (id_sucursal, id_persona, id_socio),
    FOREIGN KEY (id_sucursal, id_persona) REFERENCES PERSONA(id_sucursal, id_persona)
);

CREATE TABLE PROFESOR (
    id_sucursal INT NOT NULL,
    id_persona INT NOT NULL,
    id_profesor INT IDENTITY(1,1) NOT NULL,
    PRIMARY KEY (id_sucursal, id_persona, id_profesor),
    FOREIGN KEY (id_sucursal, id_persona) REFERENCES PERSONA(id_sucursal, id_persona)
);

CREATE TABLE INGRESO (
    id_sucursal INT NOT NULL,
    id_persona INT NOT NULL,
    id_socio INT NOT NULL,
    id_asistencia INT IDENTITY(1,1) NOT NULL,
    fecha_hora DATETIME DEFAULT GETDATE() NOT NULL,
    estado VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_sucursal, id_persona, id_socio, id_asistencia),
    FOREIGN KEY (id_sucursal, id_persona, id_socio) REFERENCES SOCIO(id_sucursal, id_persona, id_socio)
);

CREATE TABLE METODO_PAGO (
    id_metodo INT IDENTITY(1,1) PRIMARY KEY,
    tipo_metodo VARCHAR(50) NOT NULL,
    nombre_metodo VARCHAR(50) NOT NULL
);

CREATE TABLE [PLAN] (
    id_plan INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    duracion_meses INT NOT NULL,
    precio_plan DECIMAL(10, 2) NOT NULL
);

CREATE TABLE PAGO (
    id_plan INT NOT NULL,
    id_metodo INT NOT NULL,
    id_sucursal INT NOT NULL,
    id_persona INT NOT NULL,
    id_socio INT NOT NULL,
    id_pago INT IDENTITY(1,1) NOT NULL,
    fecha_pago DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    precio_con_IVA DECIMAL(10, 2) NOT NULL,
    precio_sin_IVA DECIMAL(10, 2) NOT NULL,
    pago_final DECIMAL(10, 2) NOT NULL,
    descuento INT DEFAULT 0,
    motivo_descuento VARCHAR(255),
    PRIMARY KEY (id_plan, id_metodo, id_sucursal, id_persona, id_socio, id_pago),
    FOREIGN KEY (id_plan) REFERENCES [PLAN](id_plan),
    FOREIGN KEY (id_metodo) REFERENCES METODO_PAGO(id_metodo),
    FOREIGN KEY (id_sucursal, id_persona, id_socio) REFERENCES SOCIO(id_sucursal, id_persona, id_socio)
);

CREATE TABLE CLASE (
    id_sucursal INT NOT NULL,
    id_persona INT NOT NULL,
    id_profesor INT NOT NULL,
    id_clase INT IDENTITY(1,1) NOT NULL,
    diasemana VARCHAR(15) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    cupomax INT NOT NULL,
    PRIMARY KEY (id_sucursal, id_persona, id_profesor, id_clase),
    FOREIGN KEY (id_sucursal, id_persona, id_profesor) REFERENCES PROFESOR(id_sucursal, id_persona, id_profesor)
);

CREATE TABLE PLANES_CLASES (
    id_sucursal INT NOT NULL,
    id_persona INT NOT NULL,
    id_profesor INT NOT NULL,
    id_clase INT NOT NULL,
    id_plan INT NOT NULL,
    PRIMARY KEY (id_sucursal, id_persona, id_profesor, id_clase, id_plan),
    FOREIGN KEY (id_sucursal, id_persona, id_profesor, id_clase) REFERENCES CLASE(id_sucursal, id_persona, id_profesor, id_clase),
    FOREIGN KEY (id_plan) REFERENCES [PLAN](id_plan)
);

CREATE TABLE TURNOS_PROFESOR (
    id_turno INT IDENTITY(1,1) NOT NULL,
    id_sucursal INT NOT NULL,
    id_persona INT NOT NULL,
    id_profesor INT NOT NULL,
    dia_semana DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    PRIMARY KEY (id_sucursal, id_persona, id_profesor, id_turno),
    FOREIGN KEY (id_sucursal, id_persona, id_profesor) REFERENCES PROFESOR(id_sucursal, id_persona, id_profesor)
);

CREATE TABLE INSCRIPTOACLASE (
    id_sucursal_socio INT NOT NULL,
    id_persona_socio INT NOT NULL,
    id_socio INT NOT NULL,
    id_sucursal_clase INT NOT NULL,
    id_persona_clase INT NOT NULL,
    id_profesor_clase INT NOT NULL,
    id_clase INT NOT NULL,
    id_inscripto INT IDENTITY(1,1) PRIMARY KEY,
    fecha_inscripcion DATETIME DEFAULT GETDATE() NOT NULL,
    FOREIGN KEY (id_sucursal_socio, id_persona_socio, id_socio) REFERENCES SOCIO(id_sucursal, id_persona, id_socio),
    FOREIGN KEY (id_sucursal_clase, id_persona_clase, id_profesor_clase, id_clase) REFERENCES CLASE(id_sucursal, id_persona, id_profesor, id_clase)
);
GO