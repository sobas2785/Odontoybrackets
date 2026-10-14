// ABM de pacientes. consultorio_id lo completa la base con el consultorio
// del usuario conectado, y RLS impide ver pacientes de otros consultorios.
import { supabase } from '@/supabase'
import { resolver } from './errores'

// Deja solo letras, números y espacios para no romper el filtro de Supabase
function palabrasDeBusqueda(texto) {
  return texto
    .replace(/[^\p{L}\p{N}\s'-]/gu, '')
    .split(/\s+/)
    .filter(Boolean)
}

export async function listarPacientes({ texto = '', incluirInactivos = false, limite = null } = {}) {
  let consulta = supabase.from('pacientes').select('*').order('apellido').order('nombre')

  if (!incluirInactivos) consulta = consulta.eq('activo', true)

  // Cada palabra tiene que aparecer en el nombre, el apellido o el DNI
  for (const palabra of palabrasDeBusqueda(texto)) {
    consulta = consulta.or(
      `nombre.ilike.%${palabra}%,apellido.ilike.%${palabra}%,dni.ilike.%${palabra}%`,
    )
  }

  if (limite) consulta = consulta.limit(limite)

  return resolver(consulta)
}

export async function obtenerPaciente(id) {
  return resolver(supabase.from('pacientes').select('*').eq('id', id).single())
}

function limpiarDatos(datos) {
  return {
    nombre: datos.nombre.trim(),
    apellido: datos.apellido.trim(),
    dni: datos.dni ? String(datos.dni).replace(/\D/g, '') || null : null,
    fecha_nacimiento: datos.fecha_nacimiento || null,
    telefono: datos.telefono?.trim() || null,
    email: datos.email?.trim() || null,
    obra_social: datos.obra_social?.trim() || null,
    observaciones: datos.observaciones?.trim() || null,
  }
}

export async function crearPaciente(datos) {
  return resolver(supabase.from('pacientes').insert(limpiarDatos(datos)).select().single())
}

export async function actualizarPaciente(id, datos) {
  return resolver(
    supabase.from('pacientes').update(limpiarDatos(datos)).eq('id', id).select().single(),
  )
}

// Baja lógica: el paciente deja de aparecer, pero se conserva su historial
export async function cambiarEstadoPaciente(id, activo) {
  return resolver(supabase.from('pacientes').update({ activo }).eq('id', id))
}

// Baja definitiva (solo admin). Falla si el paciente tiene turnos.
export async function eliminarPaciente(id) {
  return resolver(supabase.from('pacientes').delete().eq('id', id))
}

export function pacienteVacio() {
  return {
    nombre: '',
    apellido: '',
    dni: '',
    fecha_nacimiento: '',
    telefono: '',
    email: '',
    obra_social: '',
    observaciones: '',
  }
}
