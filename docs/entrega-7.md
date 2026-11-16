# Odontoybrackets — Entrega 7

## Administración de turnos

El módulo administra paciente, servicio, profesional, fecha, horario, notas y estado. Permite crear, consultar, reprogramar y cancelar turnos. La agenda filtra por fecha y profesional, permite incluir los cancelados y ofrece orden ascendente o descendente por hora. La búsqueda de pacientes por nombre, apellido o DNI está disponible al cargar un turno.

Cancelar conserva la reserva en el historial y libera su horario. La baja definitiva se reserva a administración, pide confirmación y vuelve a la agenda con un aviso solo cuando Supabase confirma que eliminó una fila. El formulario compartido por el alta y la edición verifica los campos obligatorios y la disponibilidad. PostgreSQL controla pertenencia, franja de atención y superposición.

## Roles y organización

Cada perfil se vincula con la cuenta de Supabase Auth mediante su ID, tiene un consultorio y un rol, y debe estar activo. La asignación profesional del turno determina qué puede gestionar una cuenta con rol profesional.

| Rol | Consulta | Alta, edición y cambios de estado | Baja definitiva | Justificación |
| --- | --- | --- | --- | --- |
| Administración | Agenda del consultorio | Turnos del consultorio | Sí, dentro del consultorio | Supervisa la operación y resuelve bajas excepcionales. |
| Recepción | Agenda del consultorio | Turnos del consultorio | No | Coordina reservas y cambios con los pacientes y el equipo. |
| Profesional | Agenda del consultorio | Solo turnos asignados a su perfil | No | Consulta la coordinación general y gestiona sus propias atenciones. |

Vue Router verifica la sesión en cada navegación y las vistas comprueban permisos al abrir el detalle, la edición y el formulario de alta. La base aplica Row Level Security. Para actualizar, comprueba tanto el turno existente como el resultado de la edición, de modo que un profesional tampoco pueda reasignar su turno a un colega. El permiso de actualización del propio perfil cubre nombre, apellido y matrícula. El rol y el consultorio están fuera de ese permiso.

## Verificación

| Caso | Entorno | Resultado observado |
| --- | --- | --- |
| Alta y consulta de un turno, pertenencia y autor | Chrome y Supabase alojado | La reserva apareció en la agenda del día, con confirmación, organización y autor esperados. |
| DNI inválido o repetido y día sin atención | Chrome y Supabase alojado | Se bloquearon los envíos inválidos o se mostró el rechazo de la base. |
| Orden por hora | Chrome y Supabase alojado | Los turnos de las 10:30 y las 16:00 aparecieron en el orden elegido en ambos sentidos. |
| Alcance visual del profesional | Chrome y Supabase alojado | Martín vio sus turnos y los de otro integrante. Pudo abrir la acción de editar el suyo. La edición por URL del otro mostró un aviso de permiso. |
| Recepción | Chrome y Supabase alojado | Carla pudo ver la acción de editar para un turno del consultorio. La vista omitió la baja definitiva. |
| Organización distinta | API alojada | Pablo obtuvo cero filas al consultar, actualizar y eliminar el turno de prueba del otro consultorio. La consulta filtrada por fecha devolvió exclusivamente filas de su organización, o ninguna si no tenía turnos ese día. |
| Baja definitiva | Chrome y Supabase alojado | Se mostró confirmación. Al descartarla se conservó el turno. Al aceptarla se eliminó y la agenda mostró el aviso. |
| Sesión cerrada o vencida | Chrome y Supabase Auth alojado | Tras cerrar sesión, la URL privada redirigió al ingreso. También redirigió al simular una sesión vencida cuyo token de renovación fue rechazado por Auth. |
| Permisos de escritura por rol | PostgreSQL local | El profesional creó y editó turnos propios. Se denegaron el alta para un colega, la edición de un turno de un colega y la reasignación. Recepción creó y canceló turnos. Administración pudo eliminarlos. |
| Aislamiento, perfil y validación | PostgreSQL local | Otra organización pudo consultar solo sus propios turnos y no consultar, editar ni borrar los ajenos. El perfil no pudo cambiar su rol ni consultorio. Alta y edición rechazaron una hora fuera de atención. |

Las pruebas de base se ejecutaron con un motor PostgreSQL embebido y datos ficticios. Se aprobaron 16 comprobaciones en cada configuración, tanto en una instalación nueva como al aplicar la migración al esquema anterior. Vite compiló correctamente. Se retiraron las reservas y el paciente ficticios creados en el proyecto alojado.

## Verificación de la migración alojada

El 16 de noviembre de 2026 se verificó la [migración de permisos](../supabase/migrations/20261116171442_permisos_turnos_entrega_7.sql) en el proyecto alojado con cuatro cuentas ficticias. El profesional creó y editó su propio turno, y consultó el de una colega. La base impidió que editara el turno de la colega, creara uno para ella o le reasignara el propio. Recepción canceló un turno y la baja definitiva quedó bloqueada para ese rol. La cuenta del otro consultorio no pudo consultar, modificar ni eliminar el turno. Administración eliminó los dos turnos y el paciente creados durante la verificación.
