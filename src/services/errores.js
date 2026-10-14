// Traduce los errores de Supabase / PostgreSQL a mensajes claros en español.

const MENSAJES_AUTH = {
  'Invalid login credentials': 'El correo o la contraseña son incorrectos.',
  'Email not confirmed': 'Primero tenés que confirmar tu correo electrónico.',
  'User already registered': 'Ya existe una cuenta con ese correo.',
  'New password should be different from the old password.':
    'La contraseña nueva tiene que ser distinta de la actual.',
  'Password should be at least 6 characters.': 'La contraseña debe tener al menos 6 caracteres.',
  'email rate limit exceeded':
    'Se enviaron demasiados correos en poco tiempo. Esperá un rato y volvé a intentar.',
}

const MENSAJES_RESTRICCIONES = {
  turnos_sin_superposicion: 'Ese profesional ya tiene un turno en ese horario.',
  pacientes_dni_unico: 'Ya hay un paciente con ese DNI en el consultorio.',
  pacientes_dni_check: 'El DNI debe tener 7 u 8 números, sin puntos.',
  servicios_nombre_unico: 'Ya existe un servicio con ese nombre.',
  consultorios_horario_valido: 'La hora de apertura tiene que ser anterior a la de cierre.',
  consultorios_dias_validos: 'Elegí al menos un día de atención.',
  tratamientos_fechas_validas: 'La fecha de fin no puede ser anterior a la de inicio.',
}

export function traducirError(error) {
  if (!error) return null

  const mensaje = error.message ?? String(error)

  if (MENSAJES_AUTH[mensaje]) return new Error(MENSAJES_AUTH[mensaje])

  const restriccion = Object.keys(MENSAJES_RESTRICCIONES).find((nombre) => mensaje.includes(nombre))
  if (restriccion) return new Error(MENSAJES_RESTRICCIONES[restriccion])

  switch (error.code) {
    case '23503':
      return new Error(
        'No se puede eliminar porque tiene turnos o tratamientos asociados. Podés darlo de baja.',
      )
    case '42501':
      return new Error('No tenés permiso para hacer esta operación.')
    case '23514':
      return new Error('Algún dato no es válido. Revisá el formulario.')
    case 'PGRST116':
      return new Error('No se encontró el registro.')
    default:
      // Los errores de los triggers (validar_turno) ya vienen en español
      return new Error(mensaje)
  }
}

// Ejecuta una consulta de Supabase y devuelve data, o lanza el error traducido.
export async function resolver(consulta) {
  const { data, error } = await consulta
  if (error) throw traducirError(error)
  return data
}
