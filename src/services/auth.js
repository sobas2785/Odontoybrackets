// Autenticación con Supabase Auth y datos de la sesión actual.
// Las contraseñas las guarda y valida Supabase: la app nunca las almacena.
import { reactive } from 'vue'
import { supabase } from '@/supabase'
import { traducirError, resolver } from './errores'

// Estado compartido por toda la app: quién está conectado, su perfil y su consultorio.
export const sesion = reactive({
  usuario: null,
  perfil: null,
  consultorio: null,
  cargada: false,
})

function limpiarSesion() {
  sesion.usuario = null
  sesion.perfil = null
  sesion.consultorio = null
}

// Si la sesión cambia (login, logout, contraseña nueva) se vuelve a cargar
// en la próxima navegación. No se llama a Supabase dentro del callback.
supabase.auth.onAuthStateChange((evento) => {
  if (evento === 'SIGNED_OUT') limpiarSesion()
  if (evento !== 'TOKEN_REFRESHED') sesion.cargada = false
})

export async function cargarSesion(forzar = false) {

  const {
    data: { session },
  } = await supabase.auth.getSession()
  if (session && sesion.cargada && !forzar && sesion.usuario?.id === session.user.id) {
    return sesion
  }

  if (!session) {
    limpiarSesion()
  } else {
    const perfil = await resolver(
      supabase
        .from('perfiles')
        .select('*, consultorio:consultorios(*)')
        .eq('id', session.user.id)
        .maybeSingle(),
    )
    sesion.usuario = session.user
    sesion.perfil = perfil
    sesion.consultorio = perfil?.consultorio ?? null
  }

  sesion.cargada = true
  return sesion
}

export async function registrarUsuario({ correo, contrasena, nombre, apellido, nombreConsultorio }) {
  // Estos datos los usa el trigger al_crear_usuario para crear el
  // consultorio y el perfil (admin) del nuevo usuario.
  const { data, error } = await supabase.auth.signUp({
    email: correo,
    password: contrasena,
    options: {
      data: { nombre, apellido, nombre_consultorio: nombreConsultorio },
      emailRedirectTo: `${window.location.origin}/login`,
    },
  })
  if (error) throw traducirError(error)

  // Si el proyecto pide confirmar el correo, todavía no hay sesión.
  return { requiereConfirmacion: !data.session }
}

export async function iniciarSesion(correo, contrasena) {
  const { error } = await supabase.auth.signInWithPassword({ email: correo, password: contrasena })
  if (error) throw traducirError(error)
  await cargarSesion(true)
}

export async function cerrarSesion() {
  const { error } = await supabase.auth.signOut()
  if (error) throw traducirError(error)
  limpiarSesion()
}

export async function cambiarContrasena(contrasenaActual, contrasenaNueva) {
  // Se confirma la contraseña actual volviendo a iniciar sesión con ella.
  const { error: errorActual } = await supabase.auth.signInWithPassword({
    email: sesion.usuario.email,
    password: contrasenaActual,
  })
  if (errorActual) throw new Error('La contraseña actual no es correcta.')

  const { error } = await supabase.auth.updateUser({ password: contrasenaNueva })
  if (error) throw traducirError(error)
}

export function tieneRol(...roles) {
  return roles.includes(sesion.perfil?.rol)
}
