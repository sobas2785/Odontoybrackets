// ABM de servicios (prestaciones) del consultorio. Solo el admin puede modificarlos.
import { supabase } from '@/supabase'
import { resolver } from './errores'

export async function listarServicios({ soloActivos = false } = {}) {
  let consulta = supabase.from('servicios').select('*').order('nombre')
  if (soloActivos) consulta = consulta.eq('activo', true)
  return resolver(consulta)
}

function limpiarDatos(datos) {
  return {
    nombre: datos.nombre.trim(),
    duracion_min: Number(datos.duracion_min),
    precio: datos.precio === '' || datos.precio === null ? null : Number(datos.precio),
    activo: datos.activo,
  }
}

export async function crearServicio(datos) {
  return resolver(supabase.from('servicios').insert(limpiarDatos(datos)).select().single())
}

export async function actualizarServicio(id, datos) {
  return resolver(
    supabase.from('servicios').update(limpiarDatos(datos)).eq('id', id).select().single(),
  )
}

// Falla si el servicio ya se usó en turnos o tratamientos: en ese caso se desactiva.
export async function eliminarServicio(id) {
  return resolver(supabase.from('servicios').delete().eq('id', id))
}
