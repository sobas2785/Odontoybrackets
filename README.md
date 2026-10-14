# Odontoybrackets

SaaS de **gestión de turnos y pacientes para consultorios odontológicos**,
especialmente de ortodoncia. Cada consultorio que se registra tiene su propia
agenda, pacientes, servicios y tratamientos, separados del resto.

**Stack:** Vue 3 + Vue Router (Vite) · Supabase (PostgreSQL, Auth, RLS) · Vercel.

## Funcionalidades

- Registro del consultorio, inicio de sesión, cierre de sesión y cambio de contraseña.
- **Agenda del día** con cambio de día, filtro por profesional y estados del turno.
- **Nuevo turno / reprogramar**: buscar o crear paciente, elegir servicio y
  profesional; solo se ofrecen los horarios libres dentro del horario de atención.
- Detalle del turno: confirmar, atendido, ausente, cancelar, recordatorio por WhatsApp.
- **ABM de pacientes** (con baja lógica) y **ficha del paciente** con tratamiento
  actual, próximo control, último turno e historial.
- **ABM de servicios** (solo admin) y configuración del consultorio (horario,
  días de atención, equipo, plan).
- Roles: admin, profesional y recepción.

## Cómo ponerlo en marcha

### 1. Base de datos (Supabase)

1. En el proyecto de Supabase abrir **SQL Editor → New query**.
2. Pegar y ejecutar [`supabase/schema.sql`](supabase/schema.sql) (crea tablas,
   relaciones, restricciones, triggers y políticas RLS).
3. Pegar y ejecutar [`supabase/seed.sql`](supabase/seed.sql) (datos de prueba de
   dos consultorios). Al final muestra una tabla con lo que se cargó.
4. En **Authentication → URL Configuration** poner como *Site URL*
   `http://localhost:5173` (es a donde lleva el link del mail de confirmación).
5. Opcional para probar más rápido: en **Authentication → Sign In / Providers →
   Email** desactivar *Confirm email*. Así, al registrarse, se entra directo.

Los usuarios de prueba y su contraseña están en el encabezado de `seed.sql`.

### 2. Aplicación

```bash
npm install
```

Copiar `.env.example` como `.env` y completar la **Publishable key**
(Supabase → Project Settings → API Keys). Después:

```bash
npm run dev
```

y abrir http://localhost:5173.

### 3. Publicar (Vercel)

Importar el repositorio en Vercel, cargar las variables `VITE_SUPABASE_URL` y
`VITE_SUPABASE_PUBLISHABLE_KEY`, y agregar la URL de Vercel en
*Authentication → URL Configuration* de Supabase. `vercel.json` ya redirige todas
las rutas a la app.

## Documentación

- [Modelo de datos y DER](docs/modelo-de-datos.md) — entidades, relaciones,
  multi-consultorio, usuarios y roles.
- [Diccionario de datos](docs/diccionario-de-datos.md)
- [Estructura del proyecto](docs/estructura-del-proyecto.md) — carpetas y rutas.
