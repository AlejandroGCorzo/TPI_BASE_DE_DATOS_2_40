# Sistema de Gestión de Gimnasio (GimnasioDB)

Este repositorio contiene la especificación, diseño físico y población de la base de datos **GimnasioDB**, diseñada para la administración y control de un gimnasio (socios, profesores, sucursales, cobros, asistencia y reservas de clases).

---

## Enunciado y Reglas de Negocio del Proyecto

El sistema automatiza y centraliza la información necesaria para administrar los socios, la oferta de planes (Musculación y Crossfit), el registro de pagos y el control de acceso físico a las instalaciones, resolviendo dos problemáticas principales:
1. **Logística comercial**: El registro de pagos calcula automáticamente la fecha de vencimiento de los planes, permitiendo determinar si un socio tiene el acceso habilitado.
2. **Logística operativa**: El sistema gestiona la disponibilidad de las clases de Crossfit, asignando profesores a horarios fijos y controlando de manera estricta el cupo máximo por clase para evitar la sobreventa de lugares mediante la gestión eficiente de inscripciones.

### Reglas Clave:
* **Horario de operación**: El gimnasio opera en el horario de 6:00 a 23:00 horas.
* **Simultaneidad de planes**: Un socio no puede poseer más de un plan activo y vigente de forma simultánea. Para contar con acceso a ambas disciplinas, debe contratar el plan Libre.
* **Disciplinas por plan**:
  * Los planes de 6 y 12 meses incluyen automáticamente ambas disciplinas (plan Libre).
  * El plan mensual permite elegir entre Musculación, Crossfit o Libre.
* **Operaciones de los Socios**:
  * Registrarse en el sistema con sus datos personales y de contacto (DNI, nombre, apellido, teléfono, email).
  * Contratar planes de Musculación, Crossfit o el plan Libre, con duraciones de 1 mes, 6 meses o 1 año. Los planes de 6 meses y 12 meses corresponden al plan Libre.
  * Realizar pagos con distintos métodos (efectivo, débito, transferencia), con cálculo automático de la fecha de vencimiento.
  * Acceder al gimnasio mediante escaneo de DNI, validando la vigencia del plan y horario de apertura (6:00-23:00 hs).
  * Inscribirse a clases de Crossfit con horario fijo, profesor asignado y cupo limitado.
* **Gestión y Control**:
  * **Control de acceso**: Cada intento de ingreso queda registrado con fecha, hora y resultado (autorizado o denegado).
  * **Gestión de clases y profesores**: Asignación de instructores a días y horarios específicos para Crossfit, con límites de capacidad por clase.
  * **Inscripciones y control de cupo**: Validación de disponibilidad de lugares y prevención de inscripciones duplicadas.
  * **Reportes**: Socios con plan vigente o vencido, recaudación mensual, pérdida mensual, recaudación mensual por método de pago, socios con plan próximo a vencer en el lapso de 7 días, estado de plan de los socios (vigente/vencido) y disponibilidad de clases.

---

## Inicio Rápido (Orden de Ejecución)

Para desplegar la base de datos en tu servidor de SQL Server, ejecutá los scripts de la carpeta `CreacionDB/` en el siguiente orden estricto:

1. **[01_DDL_Estructura.sql](CreacionDB/01_DDL_Estructura.sql)**: Crea la base de datos `GimnasioDB` y define la estructura de tablas, claves primarias y relaciones (claves foráneas).
2. **[02_DML_Datos.sql](CreacionDB/02_DML_Datos.sql)**: Carga datos semilla iniciales (sucursales, socios, profesores, planes, pagos, asistencias y clases).
3. **[03_Vistas.sql](CreacionDB/03_Vistas.sql)**: Crea las vistas de reportes clave para la toma de decisiones y control de negocio.
4. **[04_Procedimientos_Y_Triggers.sql](CreacionDB/04_Procedimientos_Y_Triggers.sql)**: Crea la lógica programable (procedimiento almacenado y triggers) para gestionar pagos, cupos de clases y control de acceso.

---

## Detalles de la Estructura de Tablas

| Tabla | Propósito / Descripción | Clave Primaria (PK) | Relaciones Clave (FK) |
|---|---|---|---|
| **SUCURSAL** | Registra las sedes físicas del gimnasio con sus horarios. | `id_sucursal` | - |
| **PERSONA** | Tabla base para el modelo de datos de personas físicas (socios y profesores). | `id_persona` | `id_sucursal` -> SUCURSAL |
| **SOCIO** | Subclase de PERSONA que identifica a los clientes del gimnasio. | `id_socio` | `id_persona` -> PERSONA |
| **PROFESOR** | Subclase de PERSONA que identifica a los instructores del gimnasio. | `id_profesor` | `id_persona` -> PERSONA |
| **INGRESO** | Control de acceso diario de socios a las instalaciones y su estado (Autorizado/Denegado). | `id_asistencia` | `id_socio` -> SOCIO |
| **METODO_PAGO**| Tipos de pago aceptados (Efectivo, MercadoPago, Débito). | `id_metodo` | - |
| **PLAN** | Planes y membresías ofrecidos (Musculación, Crossfit, Libres con duraciones variables). | `id_plan` | - |
| **PAGO** | Historial de transacciones de compra de planes con desglose de IVA y descuentos. | `id_pago` | `id_plan` -> PLAN, `id_metodo` -> METODO_PAGO, `id_socio` -> SOCIO |
| **CLASE** | Horarios de las actividades ofrecidas en el gimnasio y su cupo máximo. | `id_clase` | `id_profesor` -> PROFESOR |
| **PLANES_CLASES** | Relación de muchos a muchos que define qué planes habilitan a qué clases. | `(id_clase, id_plan)` | `id_clase` -> CLASE, `id_plan` -> PLAN |
| **TURNOS_PROFESOR** | Disponibilidad y asignación horaria laboral de los profesores. | `id_turno` | `id_profesor` -> PROFESOR |
| **INSCRIPTOACLASE**| Reservas de cupo que realizan los socios para asistir a una clase específica. | `id_inscripto` | `id_socio` -> SOCIO, `id_clase` -> CLASE |

---

## Vistas de Reporte Implementadas

Para facilitar la administración del negocio, el script **[03_Vistas.sql](CreacionDB/03_Vistas.sql)** define las siguientes vistas listas para consultar:

1. **`recaudacion_mensual`**: Calcula el total cobrado agrupado por mes y año. Útil para métricas financieras generales.
2. **`perdida_mensual`**: Calcula la brecha entre el precio de lista (con IVA) y lo efectivamente pagado (debido a descuentos aplicados), agrupado por mes y año.
3. **`recaudacion_metodo_pago`**: Sumariza los ingresos históricos según el medio de pago utilizado.
4. **`socio_proximo_a_vencer`**: Lista de socios cuya membresía expira en los próximos 7 días (excluyendo los ya vencidos). Permite acciones proactivas de renovación.
5. **`socio_estado_plan`**: Lista de socios específicando si el plan esta vigente o vencido. Útil para control de acceso y telemarketing.
6. **`disponibilidad_clases`**: Lista de clases específicando el día, horario, profesor y cupos disponibles.

---

## Lógica Programable Implementada (Procedimientos Almacenados y Triggers)

Para automatizar reglas críticas del negocio sin sobrecargar el cliente, el script **[04_Procedimientos_Y_Triggers.sql](CreacionDB/04_Procedimientos_Y_Triggers.sql)** agrega los siguientes componentes:

### 1. Procedimiento Almacenado `sp_RegistrarPago`
* **Propósito**: Automatizar el registro de pagos y la facturación de membresías de socios.
* **Operación**:
  - Recibe el socio, plan, medio de pago, descuento opcional (de 0 a 100%) y motivo del descuento.
  - Valida la existencia del socio, plan y método de pago.
  - Valida que el porcentaje de descuento esté comprendido entre 0 y 100.
  - Obtiene el precio base y la duración del plan.
  - Calcula dinámicamente el IVA (`precio_sin_IVA = precio_con_IVA / 1.21` redondeado a 2 decimales), el pago final aplicando el descuento, y la fecha de vencimiento proyectada.
  - Inserta el registro completo en la tabla `PAGO` de forma transaccional protegiendo la consistencia y atomicidad de los datos.

### 2. Procedimiento Almacenado `sp_InscribirSocioClase`
* **Propósito**: Gestionar la inscripción de un socio a una clase de forma segura, validando los permisos de su membresía.
* **Operación**:
  - Recibe el identificador del socio y de la clase.
  - Valida la existencia de ambos registros en sus respectivas tablas (`SOCIO` y `CLASE`).
  - Valida que el socio no esté inscripto previamente en la misma clase.
  - **Control de Membresía**: Verifica a través de la tabla `PLANES_CLASES` y los pagos vigentes que el socio tenga contratada una membresía activa que le otorgue derecho a tomar esa clase.
  - Realiza la inserción en `INSCRIPTOACLASE` dentro de una transacción. En caso de superar el cupo máximo (lógica controlada por el trigger `trg_ControlCupoClase`), captura el error y realiza el rollback.

### 3. Procedimiento Almacenado `sp_CancelarInscripcion`
* **Propósito**: Cancelar la inscripción de un socio a una clase de forma segura, validando reglas temporales.
* **Operación**:
  - Recibe el identificador del socio y de la clase.
  - Valida la existencia de ambos en sus respectivas tablas.
  - Valida que el socio posea una inscripción activa para esa clase.
  - De forma independiente a la configuración regional de SQL Server, determina el día de hoy y si coincide con el día de la clase, valida que la cancelación se efectúe al menos con 2 horas de anticipación.
  - Realiza el borrado físico del registro en `INSCRIPTOACLASE` dentro de una transacción.

### 4. Procedimiento Almacenado `sp_RegistrarIngreso`
* **Propósito**: Gestionar el control de accesos físico de forma lógica mediante el escaneo del DNI del socio.
* **Operación**:
  - Recibe el DNI del socio (`@dni`).
  - Valida cruzando con `SOCIO` y `PERSONA` que el DNI corresponda a un socio registrado. Si no existe, genera un error con `RAISERROR`.
  - Inserta un nuevo registro en `INGRESO` con estado `'Pendiente'`.
  - Deja que el trigger `trg_ValidarIngreso` evalúe de forma automática y autónoma el horario del gimnasio y la vigencia de la membresía del socio, actualizando el estado de forma inmediata.
  - Retorna y muestra el estado final del ingreso obtenido tras la evaluación.

### 5. Trigger `trg_ValidarPlanActivo` (en `PAGO`)
* **Propósito**: Evitar la compra o superposición accidental de membresías para un socio que ya posee un plan activo.
* **Operación**:
  - Se ejecuta `AFTER INSERT` en la tabla `PAGO`.
  - Lanza un `ROLLBACK` y un error descriptivo si el socio intenta registrar un nuevo pago y ya cuenta con un plan activo y vigente a la fecha actual.

### 6. Trigger `trg_ControlCupoClase` (en `INSCRIPTOACLASE`)
* **Propósito**: Impedir la sobre-inscripción a clases del gimnasio.
* **Operación**:
  - Se ejecuta `AFTER INSERT, UPDATE` en la tabla `INSCRIPTOACLASE`.
  - Evalúa si el número total de inscriptos para las clases afectadas supera el cupo máximo (`cupomax`) configurado en `CLASE`.
  - En caso de excederse, ejecuta un `ROLLBACK` y cancela la transacción lanzando un error con `RAISERROR`.

### 7. Trigger `trg_ValidarIngreso` (en `INGRESO`)
* **Propósito**: Controlar de forma autónoma el ingreso físico de los socios, validando plan y horario.
* **Operación**:
  - Se ejecuta `AFTER INSERT` en la tabla `INGRESO`.
  - **Validación Horaria**: Valida que la hora del ingreso (`CAST(fecha_hora AS TIME)`) esté dentro del horario de funcionamiento comercial del gimnasio (**06:00 a 23:00 hs**).
  - **Validación Financiera**: Compara si el socio posee un pago activo vigente a la fecha del ingreso.
  - Registra el resultado en la columna `estado` escribiendo `'Autorizado'` si cumple ambas condiciones, o el motivo detallado si es denegado:
    - `'Denegado: Fuera de horario de apertura (06:00 - 23:00)'`
    - `'Denegado: Socio sin plan activo o vigente'`

### 8. Trigger `trg_ValidarTurnoProfesor` (en `CLASE`)
* **Propósito**: Impedir la programación de clases en horarios de inactividad del gimnasio o fuera de la jornada laboral del profesor.
* **Operación**:
  - Se ejecuta `AFTER INSERT, UPDATE` en la tabla `CLASE`.
  - **Control de Apertura**: Asegura que las clases se programen dentro del horario de apertura del gimnasio (**06:00 a 23:00 hs**).
  - **Control de Profesor**: Para cada clase nueva o modificada, busca en `TURNOS_PROFESOR` si el profesor asignado tiene registrado un turno el mismo día de la semana que cubra completamente el rango horario de la clase (`hora_inicio` y `hora_fin`).
  - Si alguna regla se infringe, cancela la transacción (`ROLLBACK`) y lanza un error descriptivo.

---

## Autores

* **Delfina Sarkis**
* **Tomás Juárez**
* **Alejandro Gabriel Corzo**
