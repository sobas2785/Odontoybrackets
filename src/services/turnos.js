// Turnos: la función principal del sistema.
// La base valida horario de atención, superposición y pertenencia al
// consultorio (trigger validar_turno + restricción turnos_sin_superposicion);
// acá además se calculan los horarios libres para mostrar en el formulario.
import { supabase } from '@/supabase'
import { resolver } from './errores'
import { sesion } from './auth'
import { aHora, aMinutos, diaDeSemana, hoyISO, horaActual } from '@/utils/fechas'

export const ESTADOS_TURNO = {
  pendiente: 'Pendiente',
  confirmado: 'Confirmado',
  atendido: 'Atendido',
  ausente: 'Ausente',
  cancelado: 'Cancelado',
}

// Estados que liberan el horario (igual que en la restricción de la base)
const ESTADOS_LIBRES = ['cancelado', 'ausente']

const CAMPOS = `
  *,
  paciente:pacientes (id, nombre, apellido, dni, telefono, observaciones),
  servicio:servicios (id, nombre, duracion_min),
  profesional:perfiles!profesional_id (id, nombre, apellido)
`

export async function listarTurnosDelDia(fecha) {
  return resolver(
    supabase.from('turnos').select(CAMPOS).eq('fecha', fecha).order('hora_inicio'),
  )
}

export async function listarTurnosDePaciente(pacienteId) {
  return resolver(
    supabase
      .from('turnos')
      .select(CAMPOS)
      .eq('paciente_id', pacienteId)
      .order('fecha', { ascending: false })
      .order('hora_inicio', { ascending: false }),
  )
}

export async function obtenerTurno(id) {
  return resolver(supabase.from('turnos').select(CAMPOS).eq('id', id).single())
}

function limpiarDatos(datos) {
  return {
    paciente_id: datos.paciente_id,
    profesional_id: datos.profesional_id,
    servicio_id: datos.servicio_id,
    fecha: datos.fecha,
    hora_inicio: datos.hora_inicio,
    // null = la base calcula la hora de fin con la duración del servicio
    hora_fin: null,
    notas: datos.notas?.trim() || null,
  }
}

export function puedeGestionarTurno(profesionalId) {
  const perfil = sesion.perfil
  return perfil?.rol === 'admin' || perfil?.rol === 'recepcion' ||
    (perfil?.rol === 'profesional' && perfil.id === profesionalId)
}

export async function crearTurno(datos) {
  return resolver(supabase.from('turnos').insert(limpiarDatos(datos)).select().single())
}

export async function actualizarTurno(id, datos) {
  return resolver(
    supabase.from('turnos').update(limpiarDatos(datos)).eq('id', id).select().single(),
  )
}

// Cancelar no borra: cambia el estado y así queda el historial
export async function cambiarEstadoTurno(id, estado) {
  return resolver(supabase.from('turnos').update({ estado }).eq('id', id).select('id').single())
}

export async function eliminarTurno(id) {
  return resolver(supabase.from('turnos').delete().eq('id', id).select('id').single())
}

export function atiendeEseDia(fecha, consultorio = sesion.consultorio) {
  return consultorio?.dias_atencion?.includes(diaDeSemana(fecha)) ?? false
}

// Horarios en los que el profesional puede recibir un turno de
// "duracionMin" minutos ese día, según el horario del consultorio y los
// turnos que ya tiene. Devuelve una lista de 'HH:MM'.
export async function buscarHorariosLibres({ fecha, profesionalId, duracionMin, turnoAEditarId }) {
  const consultorio = sesion.consultorio
  if (!consultorio || !fecha || !profesionalId || !duracionMin) return []
  if (!atiendeEseDia(fecha, consultorio)) return []

  let consulta = supabase
    .from('turnos')
    .select('id, hora_inicio, hora_fin')
    .eq('fecha', fecha)
    .eq('profesional_id', profesionalId)
    .not('estado', 'in', `(${ESTADOS_LIBRES.join(',')})`)
  if (turnoAEditarId) consulta = consulta.neq('id', turnoAEditarId)
  const ocupados = (await resolver(consulta)).map((turno) => ({
    inicio: aMinutos(turno.hora_inicio),
    fin: aMinutos(turno.hora_fin),
  }))

  const apertura = aMinutos(consultorio.hora_apertura)
  const cierre = aMinutos(consultorio.hora_cierre)
  const paso = consultorio.duracion_turno_min
  const ahora = fecha === hoyISO() ? aMinutos(horaActual()) : -1

  const libres = []
  for (let inicio = apertura; inicio + duracionMin <= cierre; inicio += paso) {
    const fin = inicio + duracionMin
    const sePisa = ocupados.some((turno) => inicio < turno.fin && fin > turno.inicio)
    if (!sePisa && inicio > ahora) libres.push(aHora(inicio))
  }
  return libres
}

// Link de WhatsApp con un recordatorio del turno ya escrito
export function linkRecordatorioWhatsApp(turno, nombreConsultorio, fechaTexto) {
  let telefono = (turno.paciente?.telefono ?? '').replace(/\D/g, '')
  if (!telefono) return null
  if (!telefono.startsWith('54')) telefono = `549${telefono}`

  const mensaje =
    `Hola ${turno.paciente.nombre}! Te recordamos tu turno de ${turno.servicio.nombre} ` +
    `el ${fechaTexto} a las ${turno.hora_inicio.slice(0, 5)} hs en ${nombreConsultorio}.`
  return `https://wa.me/${telefono}?text=${encodeURIComponent(mensaje)}`
}
