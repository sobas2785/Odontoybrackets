-- =====================================================================
-- Odontoybrackets — Datos de prueba
-- =====================================================================
-- Correr DESPUÉS de schema.sql (SQL Editor → New query → pegar → Run).
-- Se puede volver a correr: primero borra los datos de prueba anteriores.
--
-- Crea 2 consultorios, cada uno con sus usuarios, pacientes, tratamientos
-- y turnos, para comprobar que las relaciones están bien armadas y que
-- cada consultorio ve solamente sus propios datos.
--
-- Usuarios de prueba (todos con la contraseña Prueba1234):
--
--   Consultorio Dra. Laura Fernández (ortodoncia, plan Profesional en prueba)
--     laura.fernandez@example.com   admin        (también atiende)
--     martin.rios@example.com       profesional
--     carla.diaz@example.com        recepcion
--
--   Sonrisas Centro Odontológico (plan Básico, atiende 9 a 13 hs)
--     pablo.mendez@example.com      admin        (también atiende)
--
-- Los turnos se cargan alrededor de la fecha de hoy (si hoy es sábado o
-- domingo, "hoy" pasa a ser el lunes siguiente) para que la agenda tenga
-- datos apenas se inicia sesión.
--
-- ⚠ Son cuentas con contraseña conocida y el repositorio es público:
--   borralas cuando el sistema lo use un consultorio real.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Borrar los datos de prueba anteriores
-- ---------------------------------------------------------------------
-- Al borrar el consultorio se borran en cascada sus perfiles, pacientes,
-- servicios, tratamientos y turnos.
delete from public.consultorios
where id in ('c1000000-0000-4000-8000-000000000001',
             'c2000000-0000-4000-8000-000000000002');

delete from auth.users
where id in ('a1000000-0000-4000-8000-000000000001',
             'a1000000-0000-4000-8000-000000000002',
             'a1000000-0000-4000-8000-000000000003',
             'b2000000-0000-4000-8000-000000000001');


-- ---------------------------------------------------------------------
-- 2. Consultorios (al crearse, cada uno recibe los 10 servicios base)
-- ---------------------------------------------------------------------
insert into public.consultorios
  (id, nombre, telefono, direccion, email,
   hora_apertura, hora_cierre, dias_atencion, plan, prueba_hasta)
values
  ('c1000000-0000-4000-8000-000000000001',
   'Consultorio Dra. Laura Fernández', '11 5555-0101', 'Av. San Martín 1234',
   'turnos.lfernandez@example.com',
   '10:30', '17:00', '{1,2,3,4,5}', 'profesional', current_date + 10),

  ('c2000000-0000-4000-8000-000000000002',
   'Sonrisas Centro Odontológico', '11 5555-0202', 'Belgrano 456',
   'contacto.sonrisas@example.com',
   '09:00', '13:00', '{1,2,3,4,5,6}', 'basico', null);

-- El consultorio Sonrisas cobra precios distintos y no hace ortodoncia.
update public.servicios
set precio = case nombre
               when 'Limpieza dental' then 25000
               when 'Blanqueamiento' then 90000
               when 'Consultas de diagnóstico' then 15000
               when 'Extracciones' then 40000
               when 'Tratamientos de caries' then 35000
             end
where consultorio_id = 'c2000000-0000-4000-8000-000000000002';

update public.servicios
set activo = false
where consultorio_id = 'c2000000-0000-4000-8000-000000000002'
  and nombre in ('Brackets y ortodoncia', 'Retenedores',
                 'Controles de ortodoncia', 'Colocación y control de aparatos');


-- ---------------------------------------------------------------------
-- 3. Usuarios (Supabase Auth) → el trigger al_crear_usuario crea su perfil
-- ---------------------------------------------------------------------
-- El consultorio y el rol viajan en raw_app_meta_data, que solo se puede
-- escribir desde el servidor (como acá). La contraseña se guarda
-- encriptada por Supabase Auth, nunca en una tabla nuestra.
do $$
declare
  u record;
begin
  for u in
    select *
    from (values
      ('a1000000-0000-4000-8000-000000000001'::uuid, 'laura.fernandez@example.com',
       'Laura', 'Fernández', 'c1000000-0000-4000-8000-000000000001', 'admin'),
      ('a1000000-0000-4000-8000-000000000002'::uuid, 'martin.rios@example.com',
       'Martín', 'Ríos', 'c1000000-0000-4000-8000-000000000001', 'profesional'),
      ('a1000000-0000-4000-8000-000000000003'::uuid, 'carla.diaz@example.com',
       'Carla', 'Díaz', 'c1000000-0000-4000-8000-000000000001', 'recepcion'),
      ('b2000000-0000-4000-8000-000000000001'::uuid, 'pablo.mendez@example.com',
       'Pablo', 'Méndez', 'c2000000-0000-4000-8000-000000000002', 'admin')
    ) as t (id, email, nombre, apellido, consultorio_id, rol)
  loop
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new,
      email_change_token_current, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', u.id, 'authenticated', 'authenticated',
      u.email, extensions.crypt('Prueba1234', extensions.gen_salt('bf')), now(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email'),
                         'consultorio_id', u.consultorio_id, 'rol', u.rol),
      jsonb_build_object('nombre', u.nombre, 'apellido', u.apellido),
      now(), now(), '', '', '', '', ''
    );

    insert into auth.identities (
      id, user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), u.id, u.id::text, 'email',
      jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
      now(), now(), now()
    );
  end loop;
end $$;

update public.perfiles set matricula = 'MP 12345' where id = 'a1000000-0000-4000-8000-000000000001';
update public.perfiles set matricula = 'MP 23456' where id = 'a1000000-0000-4000-8000-000000000002';
update public.perfiles set matricula = 'MP 34567' where id = 'b2000000-0000-4000-8000-000000000001';


-- ---------------------------------------------------------------------
-- 4. Pacientes
-- ---------------------------------------------------------------------
-- Juan Pérez (DNI 35222333) es paciente de los dos consultorios: cada uno
-- tiene su propia ficha y ninguno ve la del otro.
insert into public.pacientes
  (consultorio_id, nombre, apellido, dni, fecha_nacimiento, telefono, email,
   obra_social, observaciones, activo)
values
  ('c1000000-0000-4000-8000-000000000001', 'Sofía', 'Aguilar', '40111222', '2003-04-12',
   '11 6000-1111', 'sofia.aguilar@example.com', 'OSDE', 'Control mensual', true),
  ('c1000000-0000-4000-8000-000000000001', 'Juan', 'Pérez', '35222333', '1990-08-30',
   '11 6000-2222', null, 'Swiss Medical', null, true),
  ('c1000000-0000-4000-8000-000000000001', 'María', 'Gómez', '38333444', '1995-01-20',
   '11 6000-3333', 'maria.gomez@example.com', null, 'Usa retenedor nocturno', true),
  ('c1000000-0000-4000-8000-000000000001', 'Lucía', 'Benítez', '43555666', '2008-11-02',
   '11 6000-4444', null, 'IOMA', 'Viene con su mamá (menor de edad)', true),
  ('c1000000-0000-4000-8000-000000000001', 'Tomás', 'Herrera', '42444555', '2001-06-15',
   '11 6000-5555', null, null, 'Se mudó de ciudad (dado de baja)', false),

  ('c2000000-0000-4000-8000-000000000002', 'Juan', 'Pérez', '35222333', '1990-08-30',
   '11 6000-2222', null, 'Swiss Medical', 'Prefiere turnos temprano', true),
  ('c2000000-0000-4000-8000-000000000002', 'Valentina', 'Sosa', '41555666', '1998-03-09',
   '11 6100-6666', 'vale.sosa@example.com', 'OSDE', null, true),
  ('c2000000-0000-4000-8000-000000000002', 'Lucas', 'Romero', '39666777', '1996-12-24',
   '11 6100-7777', null, null, null, true);


-- ---------------------------------------------------------------------
-- 5. Tratamientos
-- ---------------------------------------------------------------------
with hoy as (
  select case extract(isodow from d) when 6 then d + 2 when 7 then d + 1 else d end as fecha
  from (select (now() at time zone 'America/Argentina/Buenos_Aires')::date as d) x
)
insert into public.tratamientos
  (consultorio_id, paciente_id, servicio_id, fecha_inicio, fecha_fin,
   proximo_control, estado, observaciones)
select t.consultorio_id::uuid, p.id, s.id,
       hoy.fecha + t.inicio, hoy.fecha + t.fin, hoy.fecha + t.control,
       t.estado, t.observaciones
from (values
  ('c1000000-0000-4000-8000-000000000001', '40111222', 'Brackets y ortodoncia',
   -182, null::int, 28, 'en_curso', 'Brackets superior e inferior. Control mensual.'),
  ('c1000000-0000-4000-8000-000000000001', '38333444', 'Retenedores',
   -60, null, 35, 'en_curso', 'Retenedor fijo inferior y removible superior.'),
  ('c1000000-0000-4000-8000-000000000001', '35222333', 'Tratamientos de caries',
   -120, -91, null, 'finalizado', 'Dos caries en molares, resuelto.'),
  ('c2000000-0000-4000-8000-000000000002', '41555666', 'Blanqueamiento',
   -14, null, 14, 'en_curso', 'Segunda sesión pendiente.')
) as t (consultorio_id, dni, servicio, inicio, fin, control, estado, observaciones)
cross join hoy
join public.pacientes p on p.consultorio_id = t.consultorio_id::uuid and p.dni = t.dni
join public.servicios s on s.consultorio_id = t.consultorio_id::uuid and s.nombre = t.servicio;


-- ---------------------------------------------------------------------
-- 6. Turnos (hora_fin la calcula el trigger según la duración del servicio)
-- ---------------------------------------------------------------------
with hoy as (
  select case extract(isodow from d) when 6 then d + 2 when 7 then d + 1 else d end as fecha
  from (select (now() at time zone 'America/Argentina/Buenos_Aires')::date as d) x
)
insert into public.turnos
  (consultorio_id, paciente_id, profesional_id, servicio_id,
   fecha, hora_inicio, estado, notas)
select t.consultorio_id::uuid, p.id, t.profesional_id::uuid, s.id,
       hoy.fecha + t.dias, t.hora::time, t.estado, t.notas
from (values
  -- Consultorio Dra. Laura Fernández: agenda de hoy (como en el documento)
  ('c1000000-0000-4000-8000-000000000001', '40111222', 'a1000000-0000-4000-8000-000000000001',
   'Controles de ortodoncia', 0, '10:30', 'confirmado', 'Ajuste de arco'),
  ('c1000000-0000-4000-8000-000000000001', '35222333', 'a1000000-0000-4000-8000-000000000001',
   'Limpieza dental', 0, '11:00', 'pendiente', null),
  ('c1000000-0000-4000-8000-000000000001', '38333444', 'a1000000-0000-4000-8000-000000000001',
   'Colocación y control de aparatos', 0, '11:30', 'pendiente', null),
  -- El Dr. Ríos atiende en paralelo: mismo horario, otro profesional
  ('c1000000-0000-4000-8000-000000000001', '43555666', 'a1000000-0000-4000-8000-000000000002',
   'Consultas de diagnóstico', 0, '10:30', 'pendiente', 'Primera consulta'),
  -- Historial
  ('c1000000-0000-4000-8000-000000000001', '40111222', 'a1000000-0000-4000-8000-000000000001',
   'Controles de ortodoncia', -28, '10:30', 'atendido', null),
  ('c1000000-0000-4000-8000-000000000001', '35222333', 'a1000000-0000-4000-8000-000000000001',
   'Limpieza dental', -35, '11:00', 'atendido', null),
  ('c1000000-0000-4000-8000-000000000001', '38333444', 'a1000000-0000-4000-8000-000000000001',
   'Retenedores', -7, '15:00', 'ausente', 'No avisó'),
  ('c1000000-0000-4000-8000-000000000001', '35222333', 'a1000000-0000-4000-8000-000000000002',
   'Consultas de diagnóstico', -7, '16:00', 'cancelado', 'Canceló por WhatsApp'),
  ('c1000000-0000-4000-8000-000000000001', '42444555', 'a1000000-0000-4000-8000-000000000001',
   'Limpieza dental', -91, '12:00', 'atendido', null),
  -- Próximos
  ('c1000000-0000-4000-8000-000000000001', '40111222', 'a1000000-0000-4000-8000-000000000001',
   'Controles de ortodoncia', 28, '10:30', 'pendiente', null),
  ('c1000000-0000-4000-8000-000000000001', '43555666', 'a1000000-0000-4000-8000-000000000002',
   'Tratamientos de caries', 7, '16:30', 'pendiente', null),

  -- Sonrisas Centro Odontológico: agenda de hoy
  ('c2000000-0000-4000-8000-000000000002', '35222333', 'b2000000-0000-4000-8000-000000000001',
   'Consultas de diagnóstico', 0, '09:00', 'confirmado', null),
  ('c2000000-0000-4000-8000-000000000002', '41555666', 'b2000000-0000-4000-8000-000000000001',
   'Blanqueamiento', 0, '09:30', 'pendiente', 'Segunda sesión'),
  ('c2000000-0000-4000-8000-000000000002', '39666777', 'b2000000-0000-4000-8000-000000000001',
   'Limpieza dental', 0, '11:00', 'pendiente', null),
  -- Historial
  ('c2000000-0000-4000-8000-000000000002', '41555666', 'b2000000-0000-4000-8000-000000000001',
   'Blanqueamiento', -14, '10:00', 'atendido', 'Primera sesión')
) as t (consultorio_id, dni, profesional_id, servicio, dias, hora, estado, notas)
cross join hoy
join public.pacientes p on p.consultorio_id = t.consultorio_id::uuid and p.dni = t.dni
join public.servicios s on s.consultorio_id = t.consultorio_id::uuid and s.nombre = t.servicio;


-- ---------------------------------------------------------------------
-- 7. Comprobación: cuántos registros quedaron asociados a cada consultorio
-- ---------------------------------------------------------------------
select c.nombre as consultorio,
       (select count(*) from public.perfiles p     where p.consultorio_id = c.id) as usuarios,
       (select count(*) from public.servicios s    where s.consultorio_id = c.id) as servicios,
       (select count(*) from public.pacientes p    where p.consultorio_id = c.id) as pacientes,
       (select count(*) from public.tratamientos t where t.consultorio_id = c.id) as tratamientos,
       (select count(*) from public.turnos t       where t.consultorio_id = c.id) as turnos
from public.consultorios c
where c.id in ('c1000000-0000-4000-8000-000000000001',
               'c2000000-0000-4000-8000-000000000002')
order by c.nombre;
