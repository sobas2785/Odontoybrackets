# Diccionario de datos — Odontoybrackets

Todas las tablas están en el esquema `public` de Supabase y tienen
**Row Level Security** activado. Referencias: **PK** clave primaria ·
**FK** clave foránea · **UK** valor único · **NN** obligatorio (`not null`).

Los `id` son `uuid` generados por la base (`gen_random_uuid()`): no son
correlativos, así no se pueden adivinar los registros de otro consultorio.

---

## `consultorios`

Cada consultorio que contrata el SaaS (el "cliente" u organización).

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | uuid | PK | Identificador del consultorio |
| `nombre` | text | NN, no vacío | Nombre comercial del consultorio |
| `telefono` | text | | Teléfono de contacto |
| `direccion` | text | | Dirección del consultorio |
| `email` | text | | Correo de contacto del consultorio |
| `hora_apertura` | time | NN, default `10:30` | Hora desde la que se dan turnos |
| `hora_cierre` | time | NN, default `17:00`, mayor a la apertura | Hora en la que tiene que terminar el último turno |
| `dias_atencion` | smallint[] | NN, default `{1,2,3,4,5}`, valores 1 a 7 | Días que atiende (1 = lunes … 7 = domingo) |
| `duracion_turno_min` | smallint | NN, default 30, entre 5 y 120 | Cada cuántos minutos se ofrecen horarios en la agenda |
| `plan` | text | NN, default `profesional`, `basico` / `profesional` / `empresa` | Plan de suscripción contratado |
| `prueba_hasta` | date | default hoy + 14 días | Fin de la prueba gratis (vacío = sin prueba) |
| `creado_en` | timestamptz | NN, default `now()` | Fecha de alta en el sistema |

## `perfiles`

Datos de cada usuario dentro del sistema. Las credenciales están en `auth.users`.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | uuid | PK, FK → `auth.users.id` (cascade) | Mismo id que el usuario de Supabase Auth |
| `consultorio_id` | uuid | NN, FK → `consultorios.id` (cascade) | Consultorio al que pertenece |
| `nombre` | text | NN, no vacío | Nombre de la persona |
| `apellido` | text | NN, default `''` | Apellido de la persona |
| `rol` | text | NN, default `admin`, `admin` / `profesional` / `recepcion` | Qué puede hacer en el sistema |
| `matricula` | text | | Matrícula profesional (odontólogos/as) |
| `activo` | boolean | NN, default `true` | `false` = ya no puede ingresar |
| `creado_en` | timestamptz | NN, default `now()` | Fecha de alta |

## `pacientes`

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | uuid | PK | Identificador del paciente |
| `consultorio_id` | uuid | NN, FK → `consultorios.id` (cascade), default consultorio del usuario | Consultorio que atiende al paciente |
| `nombre` | text | NN, no vacío | Nombre |
| `apellido` | text | NN, no vacío | Apellido |
| `dni` | text | 7 u 8 dígitos; UK junto con `consultorio_id` | Documento, sin puntos |
| `fecha_nacimiento` | date | posterior a 1900 | Para calcular la edad |
| `telefono` | text | | Para confirmar o recordar turnos (WhatsApp) |
| `email` | text | | Correo del paciente |
| `obra_social` | text | | Obra social o prepaga |
| `observaciones` | text | | Notas generales (ej. "Control mensual") |
| `activo` | boolean | NN, default `true` | Baja lógica: `false` = dado de baja, se conserva el historial |
| `creado_en` | timestamptz | NN, default `now()` | Fecha de alta |

## `servicios`

Prestaciones que ofrece cada consultorio. Al crearse un consultorio se cargan
automáticamente los 10 servicios del documento.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | uuid | PK | Identificador del servicio |
| `consultorio_id` | uuid | NN, FK → `consultorios.id` (cascade), default consultorio del usuario | Consultorio que ofrece el servicio |
| `nombre` | text | NN, no vacío; UK junto con `consultorio_id` | Nombre de la prestación |
| `duracion_min` | smallint | NN, default 30, entre 5 y 480 | Duración del turno en minutos |
| `precio` | numeric(12,2) | ≥ 0 | Precio de referencia (informativo, el MVP no cobra) |
| `activo` | boolean | NN, default `true` | `false` = no se ofrece al dar turnos |
| `creado_en` | timestamptz | NN, default `now()` | Fecha de alta |

## `tratamientos`

Seguimiento de tratamientos largos, en especial ortodoncia.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | uuid | PK | Identificador del tratamiento |
| `consultorio_id` | uuid | NN, FK → `consultorios.id` (cascade), default consultorio del usuario | Consultorio |
| `paciente_id` | uuid | NN, FK → `pacientes.id` (cascade) | Paciente en tratamiento |
| `servicio_id` | uuid | NN, FK → `servicios.id` | Tipo de tratamiento (ej. Brackets y ortodoncia) |
| `fecha_inicio` | date | NN, default hoy | Inicio del tratamiento |
| `fecha_fin` | date | ≥ `fecha_inicio` | Fin del tratamiento (si terminó) |
| `proximo_control` | date | | Fecha en la que el paciente tiene que volver |
| `estado` | text | NN, default `en_curso`, `en_curso` / `finalizado` / `suspendido` | Situación del tratamiento |
| `observaciones` | text | | Detalle (ej. "Brackets superior e inferior") |
| `creado_en` | timestamptz | NN, default `now()` | Fecha de carga |

## `turnos`

La función principal del sistema.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | uuid | PK | Identificador del turno |
| `consultorio_id` | uuid | NN, FK → `consultorios.id` (cascade), default consultorio del usuario | Consultorio del turno |
| `paciente_id` | uuid | NN, FK → `pacientes.id` | Paciente que viene |
| `profesional_id` | uuid | NN, FK → `perfiles.id` (rol admin o profesional) | Quién atiende |
| `servicio_id` | uuid | NN, FK → `servicios.id` | Qué se le hace |
| `fecha` | date | NN, día de atención del consultorio | Día del turno |
| `hora_inicio` | time | NN, dentro del horario de atención | Hora de comienzo |
| `hora_fin` | time | NN, mayor a `hora_inicio`; se calcula con la duración del servicio | Hora de finalización |
| `estado` | text | NN, default `pendiente`, `pendiente` / `confirmado` / `atendido` / `ausente` / `cancelado` | Situación del turno |
| `notas` | text | | Comentarios del turno |
| `creado_por` | uuid | FK → `perfiles.id` (set null), default usuario conectado | Quién cargó el turno |
| `creado_en` | timestamptz | NN, default `now()` | Fecha de carga |

Restricción adicional: **`turnos_sin_superposicion`** — un mismo profesional no
puede tener dos turnos (no cancelados ni ausentes) cuyos horarios se pisen.

---

## Funciones y triggers

| Nombre | Tipo | Qué hace |
|---|---|---|
| `mi_consultorio_id()` | función | Devuelve el consultorio del usuario conectado. La usan las políticas RLS y los `default`. |
| `mi_rol()` | función | Devuelve el rol del usuario conectado. La usan las políticas RLS. |
| `al_crear_usuario` → `crear_perfil_nuevo_usuario()` | trigger en `auth.users` | Al registrarse alguien: crea su consultorio y su perfil admin. |
| `al_crear_consultorio` → `crear_servicios_por_defecto()` | trigger en `consultorios` | Carga los 10 servicios base del documento. |
| `antes_de_guardar_turno` → `validar_turno()` | trigger en `turnos` | Valida consultorio, profesional, día y horario de atención, y calcula `hora_fin`. |
