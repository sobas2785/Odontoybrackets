// Tratamientos de cada paciente (seguimiento de ortodoncia y próximo control).
// Recepción puede verlos; solo admin y profesionales pueden modificarlos (RLS).
import { supabase } from '@/supabase'
import { resolver } from './errores'

export const ESTADOS_TRATAMIENTO = {
  en_curso: 'En curso',
  finalizado: 'Finalizado',
  suspendido: 'Suspendido',
}

const CAMPOS = '*, servicio:servicios(id, nombre)'

export async function listarTratamientos(pacienteId) {
  return resolver(
    supabase
      .from('tratamientos')
      .select(CAMPOS)
      .eq('paciente_id', pacienteId)
      .order('fecha_inicio', { ascending: false }),
  )
}

// El tratamiento en curso más reciente del paciente (o null)
export async function obtenerTratamientoActual(pacienteId) {
  return resolver(
    supabase
      .from('tratamientos')
      .select(CAMPOS)
      .eq('paciente_id', pacienteId)
      .eq('estado', 'en_curso')
      .order('fecha_inicio', { ascending: false })
      .limit(1)
      .maybeSingle(),
  )
}

function limpiarDatos(datos) {
  return {
    servicio_id: datos.servicio_id,
    fecha_inicio: datos.fecha_inicio,
    fecha_fin: datos.fecha_fin || null,
    proximo_control: datos.proximo_control || null,
    estado: datos.estado,
    observaciones: datos.observaciones?.trim() || null,
  }
}

export async function crearTratamiento(pacienteId, datos) {
  return resolver(
    supabase
      .from('tratamientos')
      .insert({ ...limpiarDatos(datos), paciente_id: pacienteId })
      .select(CAMPOS)
      .single(),
  )
}

export async function actualizarTratamiento(id, datos) {
  return resolver(
    supabase.from('tratamientos').update(limpiarDatos(datos)).eq('id', id).select(CAMPOS).single(),
  )
}

export async function eliminarTratamiento(id) {
  return resolver(supabase.from('tratamientos').delete().eq('id', id))
}
