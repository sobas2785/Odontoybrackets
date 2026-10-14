-- =====================================================================
-- Odontoybrackets — Estructura de la base de datos (Supabase / PostgreSQL)
-- =====================================================================
-- Cómo usarlo: Supabase → SQL Editor → New query → pegar todo → Run.
-- Después correr supabase/seed.sql para cargar los datos de prueba.
--
-- El script se puede volver a ejecutar para reconstruir la estructura.
-- ⚠ La sección 0 BORRA las tablas y todos sus datos.
--
-- Modelo multi-consultorio (multi-tenant):
--   * Cada consultorio que contrata el SaaS es una fila de "consultorios".
--   * Todas las tablas con datos del negocio tienen consultorio_id.
--   * Las políticas RLS hacen que cada usuario vea solo los datos de SU
--     consultorio, aunque todos compartan las mismas tablas.
--
-- Las contraseñas NO se guardan en ninguna tabla propia: las administra
-- Supabase Auth (tabla interna auth.users). "perfiles" solo guarda los
-- datos del usuario dentro del sistema (nombre, rol, consultorio).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0. Limpieza (permite volver a correr el script desde cero)
-- ---------------------------------------------------------------------
drop trigger if exists al_crear_usuario on auth.users;

drop table if exists public.turnos cascade;
drop table if exists public.tratamientos cascade;
drop table if exists public.servicios cascade;
drop table if exists public.pacientes cascade;
drop table if exists public.perfiles cascade;
drop table if exists public.consultorios cascade;

drop function if exists public.crear_perfil_nuevo_usuario() cascade;
drop function if exists public.crear_servicios_por_defecto() cascade;
drop function if exists public.validar_turno() cascade;
drop function if exists public.mi_consultorio_id() cascade;
drop function if exists public.mi_rol() cascade;


-- ---------------------------------------------------------------------
-- 1. Extensiones
-- ---------------------------------------------------------------------
-- btree_gist permite la restricción que impide turnos superpuestos.
create extension if not exists btree_gist with schema extensions;


-- ---------------------------------------------------------------------
-- 2. Tablas
-- ---------------------------------------------------------------------

-- Consultorio: el cliente que contrata el SaaS (la "organización").
create table public.consultorios (
  id                 uuid primary key default gen_random_uuid(),
  nombre             text not null check (length(trim(nombre)) > 0),
  telefono           text,
  direccion          text,
  email              text,
  hora_apertura      time not null default '10:30',
  hora_cierre        time not null default '17:00',
  dias_atencion      smallint[] not null default '{1,2,3,4,5}',
  duracion_turno_min smallint not null default 30
                     check (duracion_turno_min between 5 and 120),
  plan               text not null default 'profesional'
                     check (plan in ('basico', 'profesional', 'empresa')),
  prueba_hasta       date default (current_date + 14),
  creado_en          timestamptz not null default now(),

  constraint consultorios_horario_valido
    check (hora_apertura < hora_cierre),
  constraint consultorios_dias_validos
    check (cardinality(dias_atencion) > 0
           and dias_atencion <@ '{1,2,3,4,5,6,7}'::smallint[])
);

comment on table public.consultorios is
  'Cada consultorio que contrata Odontoybrackets (tenant). Agrupa a sus usuarios, pacientes, servicios, tratamientos y turnos.';


-- Perfil: datos de cada usuario dentro del sistema.
-- El id es el mismo que el del usuario en auth.users (relación 1 a 1).
create table public.perfiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  consultorio_id uuid not null references public.consultorios (id) on delete cascade,
  nombre         text not null check (length(trim(nombre)) > 0),
  apellido       text not null default '',
  rol            text not null default 'admin'
                 check (rol in ('admin', 'profesional', 'recepcion')),
  matricula      text,
  activo         boolean not null default true,
  creado_en      timestamptz not null default now()
);

comment on table public.perfiles is
  'Usuarios del sistema (odontólogos/as y recepción). Extiende auth.users con consultorio y rol.';

create index perfiles_consultorio_idx on public.perfiles (consultorio_id);


-- ---------------------------------------------------------------------
-- 3. Funciones auxiliares para la seguridad
-- ---------------------------------------------------------------------
-- Devuelven el consultorio y el rol del usuario conectado. Son
-- SECURITY DEFINER para poder leer "perfiles" sin quedar en un ciclo
-- con sus propias políticas RLS.

create or replace function public.mi_consultorio_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select consultorio_id
  from public.perfiles
  where id = (select auth.uid()) and activo
$$;

create or replace function public.mi_rol()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select rol
  from public.perfiles
  where id = (select auth.uid()) and activo
$$;


-- ---------------------------------------------------------------------
-- 2 (continuación). Tablas con los datos de cada consultorio
-- ---------------------------------------------------------------------
-- consultorio_id se completa solo con el consultorio del usuario
-- conectado (igual que usuario_id default auth.uid() en el ABM de clase).

-- Paciente del consultorio.
create table public.pacientes (
  id               uuid primary key default gen_random_uuid(),
  consultorio_id   uuid not null default public.mi_consultorio_id()
                   references public.consultorios (id) on delete cascade,
  nombre           text not null check (length(trim(nombre)) > 0),
  apellido         text not null check (length(trim(apellido)) > 0),
  dni              text check (dni ~ '^[0-9]{7,8}$'),
  fecha_nacimiento date check (fecha_nacimiento > '1900-01-01'),
  telefono         text,
  email            text,
  obra_social      text,
  observaciones    text,
  activo           boolean not null default true,
  creado_en        timestamptz not null default now(),

  -- El mismo DNI no puede repetirse dentro de un consultorio,
  -- pero sí puede existir en dos consultorios distintos.
  constraint pacientes_dni_unico unique (consultorio_id, dni)
);

comment on table public.pacientes is
  'Pacientes de cada consultorio. Baja lógica con activo = false para conservar el historial.';

create index pacientes_consultorio_apellido_idx
  on public.pacientes (consultorio_id, apellido, nombre);


-- Servicio / prestación que ofrece el consultorio.
create table public.servicios (
  id             uuid primary key default gen_random_uuid(),
  consultorio_id uuid not null default public.mi_consultorio_id()
                 references public.consultorios (id) on delete cascade,
  nombre         text not null check (length(trim(nombre)) > 0),
  duracion_min   smallint not null default 30 check (duracion_min between 5 and 480),
  precio         numeric(12, 2) check (precio >= 0),
  activo         boolean not null default true,
  creado_en      timestamptz not null default now(),

  constraint servicios_nombre_unico unique (consultorio_id, nombre)
);

comment on table public.servicios is
  'Catálogo de prestaciones de cada consultorio, con su duración (define cuánto dura el turno).';

create index servicios_consultorio_idx on public.servicios (consultorio_id);


-- Tratamiento largo de un paciente (ej. ortodoncia con controles mensuales).
create table public.tratamientos (
  id              uuid primary key default gen_random_uuid(),
  consultorio_id  uuid not null default public.mi_consultorio_id()
                  references public.consultorios (id) on delete cascade,
  paciente_id     uuid not null references public.pacientes (id) on delete cascade,
  servicio_id     uuid not null references public.servicios (id),
  fecha_inicio    date not null default current_date,
  fecha_fin       date,
  proximo_control date,
  estado          text not null default 'en_curso'
                  check (estado in ('en_curso', 'finalizado', 'suspendido')),
  observaciones   text,
  creado_en       timestamptz not null default now(),

  constraint tratamientos_fechas_validas
    check (fecha_fin is null or fecha_fin >= fecha_inicio)
);

comment on table public.tratamientos is
  'Seguimiento de tratamientos de cada paciente: en qué etapa está y cuándo es su próximo control.';

create index tratamientos_paciente_idx on public.tratamientos (paciente_id);


-- Turno: la función principal del sistema.
create table public.turnos (
  id             uuid primary key default gen_random_uuid(),
  consultorio_id uuid not null default public.mi_consultorio_id()
                 references public.consultorios (id) on delete cascade,
  paciente_id    uuid not null references public.pacientes (id),
  profesional_id uuid not null references public.perfiles (id),
  servicio_id    uuid not null references public.servicios (id),
  fecha          date not null,
  hora_inicio    time not null,
  hora_fin       time not null, -- si llega vacía la calcula validar_turno()
  estado         text not null default 'pendiente'
                 check (estado in ('pendiente', 'confirmado', 'atendido', 'ausente', 'cancelado')),
  notas          text,
  creado_por     uuid default auth.uid() references public.perfiles (id) on delete set null,
  creado_en      timestamptz not null default now(),

  constraint turnos_horas_validas check (hora_fin > hora_inicio),

  -- Un profesional no puede tener dos turnos que se pisen en el tiempo.
  -- Los turnos cancelados o ausentes liberan el horario.
  constraint turnos_sin_superposicion exclude using gist (
    profesional_id with =,
    tsrange(fecha + hora_inicio, fecha + hora_fin) with &&
  ) where (estado not in ('cancelado', 'ausente'))
);

comment on table public.turnos is
  'Agenda: cada turno une paciente, profesional y servicio en una fecha y horario. Cancelar = cambiar estado, no borrar.';

create index turnos_consultorio_fecha_idx on public.turnos (consultorio_id, fecha, hora_inicio);
create index turnos_paciente_idx on public.turnos (paciente_id);


-- ---------------------------------------------------------------------
-- 4. Triggers (reglas automáticas)
-- ---------------------------------------------------------------------

-- 4.1 Al registrarse un usuario se crea su perfil.
--   * Registro desde la app: se crea un consultorio nuevo con el nombre
--     que escribió en el formulario y el usuario queda como admin.
--   * Usuario agregado a un consultorio existente: se indica en
--     raw_app_meta_data (solo se puede escribir desde el servidor, nunca
--     desde el navegador), así nadie puede sumarse a un consultorio ajeno.
create or replace function public.crear_perfil_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_consultorio_id uuid;
  v_rol            text;
begin
  v_consultorio_id := nullif(new.raw_app_meta_data ->> 'consultorio_id', '')::uuid;
  v_rol := coalesce(new.raw_app_meta_data ->> 'rol', 'admin');

  if v_consultorio_id is null then
    insert into public.consultorios (nombre)
    values (coalesce(nullif(trim(new.raw_user_meta_data ->> 'nombre_consultorio'), ''), 'Mi consultorio'))
    returning id into v_consultorio_id;

    v_rol := 'admin';
  end if;

  insert into public.perfiles (id, consultorio_id, nombre, apellido, rol)
  values (
    new.id,
    v_consultorio_id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'nombre'), ''), split_part(new.email, '@', 1)),
    coalesce(trim(new.raw_user_meta_data ->> 'apellido'), ''),
    v_rol
  );

  return new;
end;
$$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil_nuevo_usuario();


-- 4.2 Todo consultorio nuevo arranca con los servicios del documento.
create or replace function public.crear_servicios_por_defecto()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  insert into public.servicios (consultorio_id, nombre, duracion_min) values
    (new.id, 'Brackets y ortodoncia', 60),
    (new.id, 'Retenedores', 30),
    (new.id, 'Controles de ortodoncia', 30),
    (new.id, 'Limpieza dental', 30),
    (new.id, 'Blanqueamiento', 60),
    (new.id, 'Arreglos / consultas odontológicas', 30),
    (new.id, 'Extracciones', 30),
    (new.id, 'Tratamientos de caries', 30),
    (new.id, 'Consultas de diagnóstico', 30),
    (new.id, 'Colocación y control de aparatos', 60);

  return new;
end;
$$;

create trigger al_crear_consultorio
  after insert on public.consultorios
  for each row execute function public.crear_servicios_por_defecto();


-- 4.3 Validaciones de cada turno antes de guardarlo.
create or replace function public.validar_turno()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_consultorio public.consultorios%rowtype;
  v_duracion    smallint;
  v_rol         text;
begin
  -- Paciente, servicio y profesional tienen que ser del mismo consultorio.
  if not exists (
    select 1 from public.pacientes
    where id = new.paciente_id and consultorio_id = new.consultorio_id
  ) then
    raise exception 'El paciente no pertenece a este consultorio.';
  end if;

  select duracion_min into v_duracion
  from public.servicios
  where id = new.servicio_id and consultorio_id = new.consultorio_id;

  if not found then
    raise exception 'El servicio no pertenece a este consultorio.';
  end if;

  select rol into v_rol
  from public.perfiles
  where id = new.profesional_id and consultorio_id = new.consultorio_id;

  if v_rol is null or v_rol not in ('admin', 'profesional') then
    raise exception 'La persona elegida no atiende pacientes en este consultorio.';
  end if;

  -- Si no se indica la hora de fin, se calcula con la duración del servicio.
  if new.hora_fin is null then
    new.hora_fin := new.hora_inicio + make_interval(mins => v_duracion);
  end if;

  -- Día y horario de atención: solo al crear o al cambiar fecha/hora,
  -- así un cambio de horario del consultorio no bloquea turnos viejos.
  if tg_op = 'INSERT'
     or new.fecha is distinct from old.fecha
     or new.hora_inicio is distinct from old.hora_inicio
     or new.hora_fin is distinct from old.hora_fin then

    select * into v_consultorio
    from public.consultorios
    where id = new.consultorio_id;

    if not (extract(isodow from new.fecha)::smallint = any (v_consultorio.dias_atencion)) then
      raise exception 'El consultorio no atiende ese día.';
    end if;

    if new.hora_inicio < v_consultorio.hora_apertura
       or new.hora_fin > v_consultorio.hora_cierre
       or new.hora_fin <= new.hora_inicio then
      raise exception 'El turno tiene que estar dentro del horario de atención (% a % hs).',
        left(v_consultorio.hora_apertura::text, 5),
        left(v_consultorio.hora_cierre::text, 5);
    end if;
  end if;

  return new;
end;
$$;

create trigger antes_de_guardar_turno
  before insert or update on public.turnos
  for each row execute function public.validar_turno();


-- ---------------------------------------------------------------------
-- 5. Seguridad: permisos y Row Level Security (RLS)
-- ---------------------------------------------------------------------
-- Roles del sistema:
--   admin       dueño/a del consultorio. Puede todo dentro de su consultorio.
--   profesional odontólogo/a. Agenda, pacientes y tratamientos.
--   recepcion   agenda y pacientes. Ve los tratamientos pero no los modifica.

alter table public.consultorios enable row level security;
alter table public.perfiles     enable row level security;
alter table public.pacientes    enable row level security;
alter table public.servicios    enable row level security;
alter table public.tratamientos enable row level security;
alter table public.turnos       enable row level security;

-- Permisos de tabla. Primero se quita todo y después se da lo justo.
revoke all on public.consultorios, public.perfiles, public.pacientes,
              public.servicios, public.tratamientos, public.turnos
  from anon, authenticated;

-- Del consultorio se pueden editar los datos y el horario, pero no el
-- plan ni la prueba gratis (eso lo cambia el sistema al cobrar).
grant select on public.consultorios to authenticated;
grant update (nombre, telefono, direccion, email, hora_apertura, hora_cierre,
              dias_atencion, duracion_turno_min)
  on public.consultorios to authenticated;

-- Del perfil propio se pueden editar los datos personales, no el rol
-- ni el consultorio.
grant select on public.perfiles to authenticated;
grant update (nombre, apellido, matricula) on public.perfiles to authenticated;

grant select, insert, update, delete
  on public.pacientes, public.servicios, public.tratamientos, public.turnos
  to authenticated;

revoke execute on function public.mi_consultorio_id(), public.mi_rol() from public, anon;
grant execute on function public.mi_consultorio_id(), public.mi_rol() to authenticated;

revoke execute on function public.crear_perfil_nuevo_usuario(),
                           public.crear_servicios_por_defecto(),
                           public.validar_turno()
  from public, anon, authenticated;


-- consultorios
create policy "Miembros ven su consultorio"
  on public.consultorios for select to authenticated
  using (id = (select public.mi_consultorio_id()));

create policy "El admin modifica su consultorio"
  on public.consultorios for update to authenticated
  using (id = (select public.mi_consultorio_id()) and (select public.mi_rol()) = 'admin')
  with check (id = (select public.mi_consultorio_id()));

-- perfiles
create policy "Miembros ven al equipo de su consultorio"
  on public.perfiles for select to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()) or id = (select auth.uid()));

create policy "Cada usuario modifica su perfil"
  on public.perfiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- pacientes
create policy "Miembros ven los pacientes"
  on public.pacientes for select to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()));

create policy "Miembros cargan pacientes"
  on public.pacientes for insert to authenticated
  with check (consultorio_id = (select public.mi_consultorio_id()));

create policy "Miembros modifican pacientes"
  on public.pacientes for update to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()))
  with check (consultorio_id = (select public.mi_consultorio_id()));

create policy "El admin elimina pacientes"
  on public.pacientes for delete to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()) and (select public.mi_rol()) = 'admin');

-- servicios
create policy "Miembros ven los servicios"
  on public.servicios for select to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()));

create policy "El admin carga servicios"
  on public.servicios for insert to authenticated
  with check (consultorio_id = (select public.mi_consultorio_id()) and (select public.mi_rol()) = 'admin');

create policy "El admin modifica servicios"
  on public.servicios for update to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()) and (select public.mi_rol()) = 'admin')
  with check (consultorio_id = (select public.mi_consultorio_id()));

create policy "El admin elimina servicios"
  on public.servicios for delete to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()) and (select public.mi_rol()) = 'admin');

-- tratamientos
create policy "Miembros ven los tratamientos"
  on public.tratamientos for select to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()));

create policy "Profesionales cargan tratamientos"
  on public.tratamientos for insert to authenticated
  with check (consultorio_id = (select public.mi_consultorio_id())
              and (select public.mi_rol()) in ('admin', 'profesional'));

create policy "Profesionales modifican tratamientos"
  on public.tratamientos for update to authenticated
  using (consultorio_id = (select public.mi_consultorio_id())
         and (select public.mi_rol()) in ('admin', 'profesional'))
  with check (consultorio_id = (select public.mi_consultorio_id()));

create policy "Profesionales eliminan tratamientos"
  on public.tratamientos for delete to authenticated
  using (consultorio_id = (select public.mi_consultorio_id())
         and (select public.mi_rol()) in ('admin', 'profesional'));

-- turnos
create policy "Miembros ven los turnos"
  on public.turnos for select to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()));

create policy "Miembros cargan turnos"
  on public.turnos for insert to authenticated
  with check (consultorio_id = (select public.mi_consultorio_id()));

create policy "Miembros modifican turnos"
  on public.turnos for update to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()))
  with check (consultorio_id = (select public.mi_consultorio_id()));

create policy "El admin elimina turnos"
  on public.turnos for delete to authenticated
  using (consultorio_id = (select public.mi_consultorio_id()) and (select public.mi_rol()) = 'admin');
