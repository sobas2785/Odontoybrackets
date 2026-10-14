# Estructura del proyecto — Odontoybrackets

```
Odontoybrackets/
├── docs/                         Documentación del proyecto
│   ├── modelo-de-datos.md        Entidades, DER, multi-consultorio, roles y reglas
│   ├── der.png                   Diagrama entidad-relación como imagen
│   ├── diccionario-de-datos.md   Cada tabla con sus campos, tipos y descripción
│   └── estructura-del-proyecto.md
├── supabase/                     Todo lo que se ejecuta en la base de datos
│   ├── schema.sql                Tablas, relaciones, restricciones, triggers y RLS
│   └── seed.sql                  Datos de prueba (2 consultorios)
├── public/
│   └── favicon.svg               Isotipo (diente con brackets)
├── src/
│   ├── main.js                   Punto de entrada: crea la app e instala el router
│   ├── App.vue                   Estructura general: barra de navegación + RouterView
│   ├── style.css                 Estilos globales y paleta (celeste / violeta)
│   ├── supabase.js               Cliente único de Supabase (lee el .env)
│   ├── router/
│   │   └── index.js              Rutas y guard: sesión obligatoria y permisos por rol
│   ├── services/                 ÚNICO lugar que habla con la base de datos
│   │   ├── auth.js               Registro, login, cerrar sesión, cambiar contraseña, sesión actual
│   │   ├── consultorio.js        Datos y horario del consultorio, equipo, mi perfil
│   │   ├── pacientes.js          ABM de pacientes y búsqueda
│   │   ├── servicios.js          ABM de servicios
│   │   ├── tratamientos.js       Tratamientos y próximo control
│   │   ├── turnos.js             Turnos, cambio de estado y cálculo de horarios libres
│   │   └── errores.js            Traduce los errores de Supabase a mensajes en español
│   ├── utils/
│   │   └── fechas.js             Fechas y horas en la zona horaria local
│   ├── components/               Piezas reutilizables de la interfaz
│   │   ├── BarraNavegacion.vue   Menú superior (Agenda, Pacientes, ... Cerrar sesión)
│   │   ├── SelectorDia.vue       Flechas ‹ › y calendario para cambiar de día
│   │   ├── TarjetaTurno.vue      Fila de la agenda (hora, paciente, servicio, estado)
│   │   ├── EtiquetaEstado.vue    Etiqueta de color para estados
│   │   ├── BuscadorPaciente.vue  Buscador por nombre/DNI que se usa al dar turnos
│   │   └── FormularioPaciente.vue Campos del paciente (ABM y alta rápida)
│   └── views/                    Una pantalla por ruta
│       ├── LoginView.vue         /login
│       ├── RegistroView.vue      /registro  (crea el consultorio)
│       ├── CambiarContrasenaView.vue /cambiar-contrasena
│       ├── AgendaView.vue        /agenda  (pantalla principal del wireframe)
│       ├── TurnoFormView.vue     /turnos/nuevo y /turnos/:id/editar
│       ├── TurnoView.vue         /turnos/:id  (detalle, estados, WhatsApp)
│       ├── PacientesView.vue     /pacientes  (ABM de pacientes)
│       ├── PacienteView.vue      /pacientes/:id  (ficha, tratamientos, historial)
│       ├── ServiciosView.vue     /servicios  (ABM, solo admin)
│       └── ConsultorioView.vue   /consultorio  (datos, horario, plan, equipo)
├── .env.example                  Modelo del .env (URL y clave publicable)
├── .gitignore                    Excluye node_modules, dist y .env
├── index.html
├── package.json
├── vercel.json                   Para publicar el frontend en Vercel
└── vite.config.js                Vite + alias "@" → src
```

## Función de cada carpeta

| Carpeta | Para qué sirve |
|---|---|
| `supabase/` | Scripts SQL para **reconstruir la base desde cero** y cargar datos de prueba. |
| `src/views/` | Las **pantallas**. Cada una corresponde a una ruta del router. Solo manejan lo que se ve y lo que escribe el usuario. |
| `src/components/` | **Partes de pantalla reutilizables** (se usan en más de una vista). |
| `src/router/` | Las **rutas** de la aplicación. El guard `beforeEach` exige sesión en las páginas privadas (`meta.requiereAutenticacion`) y controla las páginas solo para admin (`meta.roles`). |
| `src/services/` | **Centraliza todas las operaciones con la base de datos**. Las vistas nunca llaman a `supabase` directamente: llaman funciones como `crearTurno()` o `listarPacientes()`. Si cambia la base, se cambia solo acá. |
| `src/utils/` | Funciones auxiliares que no dependen de la base (fechas y horas). |
| `docs/` | Documentación para la entrega: modelo de datos, DER y diccionario. |

## Rutas

| Ruta | Pantalla | Acceso |
|---|---|---|
| `/login` | Iniciar sesión | Sin sesión |
| `/registro` | Registrar consultorio | Sin sesión |
| `/agenda` | Agenda del día (con `?fecha=AAAA-MM-DD`) | Con sesión |
| `/turnos/nuevo` | Nuevo turno | Con sesión |
| `/turnos/:id` | Detalle del turno | Con sesión |
| `/turnos/:id/editar` | Editar / reprogramar turno | Con sesión |
| `/pacientes` | ABM de pacientes | Con sesión |
| `/pacientes/:id` | Ficha del paciente | Con sesión |
| `/consultorio` | Mi consultorio | Con sesión |
| `/cambiar-contrasena` | Cambiar contraseña | Con sesión |
| `/servicios` | ABM de servicios | Solo admin |
