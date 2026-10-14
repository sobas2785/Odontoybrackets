// Datos del consultorio (tenant), del equipo y del perfil propio.
import { supabase } from '@/supabase'
import { resolver } from './errores'
import { sesion } from './auth'

export const ROLES = {
  admin: 'Administrador/a',
  profesional: 'Profesional',
  recepcion: 'Recepción',
}

export const PLANES = {
  basico: 'Básico',
  profesional: 'Profesional',
  empresa: 'Empresa',
}

export async function actualizarConsultorio(datos) {
  // Solo se envían las columnas que el usuario puede editar
  // (el plan y la prueba gratis no: ver permisos en schema.sql).
  const consultorio = await resolver(
    supabase
      .from('consultorios')
      .update({
        nombre: datos.nombre.trim(),
        telefono: datos.telefono?.trim() || null,
        direccion: datos.direccion?.trim() || null,
        email: datos.email?.trim() || null,
        hora_apertura: datos.hora_apertura,
        hora_cierre: datos.hora_cierre,
        duracion_turno_min: Number(datos.duracion_turno_min),
        dias_atencion: [...datos.dias_atencion].sort((a, b) => a - b),
      })
      .eq('id', sesion.consultorio.id)
      .select()
      .single(),
  )
  sesion.consultorio = consultorio
  return consultorio
}

export async function listarEquipo() {
  return resolver(
    supabase.from('perfiles').select('*').order('activo', { ascending: false }).order('nombre'),
  )
}

// Personas que pueden atender turnos (admin y profesionales activos)
export async function listarProfesionales() {
  return resolver(
    supabase
      .from('perfiles')
      .select('id, nombre, apellido, rol')
      .in('rol', ['admin', 'profesional'])
      .eq('activo', true)
      .order('nombre'),
  )
}

export async function actualizarMiPerfil(datos) {
  const perfil = await resolver(
    supabase
      .from('perfiles')
      .update({
        nombre: datos.nombre.trim(),
        apellido: datos.apellido?.trim() ?? '',
        matricula: datos.matricula?.trim() || null,
      })
      .eq('id', sesion.perfil.id)
      .select()
      .single(),
  )
  sesion.perfil = { ...sesion.perfil, ...perfil }
  return perfil
}

export function nombreCompleto(persona) {
  return persona ? `${persona.nombre} ${persona.apellido ?? ''}`.trim() : ''
}
