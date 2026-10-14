// Funciones para trabajar fechas y horas en la zona horaria del navegador.
// Las fechas viajan a la base como texto 'AAAA-MM-DD' y las horas como 'HH:MM'.

export const NOMBRES_DIAS = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']

function dosDigitos(numero) {
  return String(numero).padStart(2, '0')
}

// Date → 'AAAA-MM-DD' (usa la fecha local, no UTC)
export function aISO(fecha) {
  return `${fecha.getFullYear()}-${dosDigitos(fecha.getMonth() + 1)}-${dosDigitos(fecha.getDate())}`
}

// 'AAAA-MM-DD' → Date a las 00:00 locales
export function desdeISO(iso) {
  const [anio, mes, dia] = iso.split('-').map(Number)
  return new Date(anio, mes - 1, dia)
}

export function hoyISO() {
  return aISO(new Date())
}

export function sumarDias(iso, dias) {
  const fecha = desdeISO(iso)
  fecha.setDate(fecha.getDate() + dias)
  return aISO(fecha)
}

// 1 = lunes … 7 = domingo (igual que isodow en PostgreSQL)
export function diaDeSemana(iso) {
  return desdeISO(iso).getDay() || 7
}

export function formatearFecha(iso, opciones = { day: '2-digit', month: '2-digit', year: 'numeric' }) {
  if (!iso) return '—'
  return desdeISO(iso).toLocaleDateString('es-AR', opciones)
}

export function formatearFechaLarga(iso) {
  return formatearFecha(iso, { weekday: 'long', day: 'numeric', month: 'long' })
}

// '10:30:00' → '10:30'
export function formatearHora(hora) {
  return hora ? hora.slice(0, 5) : ''
}

// 'HH:MM' → minutos desde las 00:00
export function aMinutos(hora) {
  const [horas, minutos] = hora.split(':').map(Number)
  return horas * 60 + minutos
}

// minutos desde las 00:00 → 'HH:MM'
export function aHora(minutos) {
  return `${dosDigitos(Math.floor(minutos / 60))}:${dosDigitos(minutos % 60)}`
}

export function horaActual() {
  const ahora = new Date()
  return aHora(ahora.getHours() * 60 + ahora.getMinutes())
}

export function calcularEdad(fechaNacimiento) {
  if (!fechaNacimiento) return null
  const nacimiento = desdeISO(fechaNacimiento)
  const hoy = new Date()
  let edad = hoy.getFullYear() - nacimiento.getFullYear()
  const cumpleEsteAnio = new Date(hoy.getFullYear(), nacimiento.getMonth(), nacimiento.getDate())
  if (hoy < cumpleEsteAnio) edad--
  return edad
}
