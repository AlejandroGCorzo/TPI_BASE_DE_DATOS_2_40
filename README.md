# Sistema de Gestión de Gimnasio (BD2)

## Descripción
Proyecto de diseño e implementación de una base de datos relacional para la gestión integral de un gimnasio.
El sistema automatiza la administración de socios, planes (Musculación y Crossfit), pagos, y control de acceso.

## Autores
* Delfina Sarkis
* Tomás Juárez
* Alejandro Gabriel Corzo

## Estructura del Repositorio
* `CreacionDB/`: Contiene los scripts SQL para la creación y carga inicial de la base de datos en SQL Server.
  * `01_DDL_Estructura.sql`: Script de creación de tablas y relaciones (PK, FK).
  * `02_DML_Datos.sql`: Script de inserción de datos iniciales (planes, métodos de pago, profesores, etc.).
  * `03_Vistas.sql`: Script con las vistas de reportes para el dueño del gimnasio (recaudación mensual, pérdidas, recaudación por método de pago, socios con plan próximo a vencer y socios con plan vencido).
