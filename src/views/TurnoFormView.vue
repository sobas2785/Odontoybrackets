<script setup>
// Sirve para /turnos/nuevo y para /turnos/:id/editar
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import BuscadorPaciente from '@/components/BuscadorPaciente.vue'
import FormularioPaciente from '@/components/FormularioPaciente.vue'
import { sesion } from '@/services/auth'
import { listarProfesionales, nombreCompleto } from '@/services/consultorio'
import { crearPaciente, obtenerPaciente, pacienteVacio } from '@/services/pacientes'
import { listarServicios } from '@/services/servicios'
import {
  actualizarTurno,
  atiendeEseDia,
  buscarHorariosLibres,
  crearTurno,
  obtenerTurno,
  puedeGestionarTurno,
} from '@/services/turnos'
import { formatearHora, hoyISO } from '@/utils/fechas'

const route = useRoute()
const router = useRouter()

const turnoId = route.params.id ?? null
const esEdicion = Boolean(turnoId)

// Paso 1: paciente
const paciente = ref(null)
const creandoPaciente = ref(false)
const nuevoPaciente = ref(pacienteVacio())
const guardandoPaciente = ref(false)
const errorPaciente = ref('')

// Paso 2: datos del turno
const servicios = ref([])
const profesionales = ref([])
const servicioId = ref('')
const profesionalId = ref('')
const fecha = ref(route.query.fecha && route.query.fecha >= hoyISO() ? route.query.fecha : hoyISO())
const hora = ref('')
const notas = ref('')

// Al editar se guarda el horario original para no perderlo de la lista
const horarioOriginal = ref(null)

const horariosLibres = ref([])
const buscandoHorarios = ref(false)
const cargando = ref(true)
const guardando = ref(false)
const puedeEditar = ref(!esEdicion)
const errorMensaje = ref('')

const servicioElegido = computed(() => servicios.value.find((s) => s.id === servicioId.value))

const conservaHorario = computed(() => {
  const original = horarioOriginal.value
  return original && fecha.value === original.fecha &&
    servicioId.value === original.servicio && profesionalId.value === original.profesional
})

const opcionesHora = computed(() => {
  const opciones = [...horariosLibres.value]
  if (conservaHorario.value && !opciones.includes(horarioOriginal.value.hora)) {
    opciones.push(horarioOriginal.value.hora)
    opciones.sort()
  }
  return opciones
})

const textoHora = computed(() => {
  if (!servicioId.value) return 'Primero elegí el servicio'
  if (buscandoHorarios.value) return 'Buscando horarios...'
  if (!opcionesHora.value.length) return 'No hay horarios libres'
  return 'Elegir hora...'
})

const horarioConsultorio = computed(() => {
  const c = sesion.consultorio
  return c ? `${formatearHora(c.hora_apertura)} a ${formatearHora(c.hora_cierre)} hs` : ''
})

let numeroBusqueda = 0

async function actualizarHorarios() {
  const numero = ++numeroBusqueda
  horariosLibres.value = []
  if (!fecha.value || !profesionalId.value || !servicioElegido.value || fecha.value < hoyISO()) {
    buscandoHorarios.value = false
    if (!opcionesHora.value.includes(hora.value)) hora.value = ''
    return
  }
  buscandoHorarios.value = true
  try {
    const libres = await buscarHorariosLibres({
      fecha: fecha.value,
      profesionalId: profesionalId.value,
      duracionMin: servicioElegido.value.duracion_min,
      turnoAEditarId: turnoId,
    })
    if (numero !== numeroBusqueda) return
    horariosLibres.value = libres
    if (!opcionesHora.value.includes(hora.value)) hora.value = ''
  } catch (error) {
    if (numero === numeroBusqueda) errorMensaje.value = error.message
  } finally {
    if (numero === numeroBusqueda) buscandoHorarios.value = false
  }
}

watch([fecha, profesionalId, servicioId], actualizarHorarios)

onMounted(async () => {
  try {
    ;[servicios.value, profesionales.value] = await Promise.all([
      listarServicios({ soloActivos: true }),
      listarProfesionales(),
    ])

    profesionales.value = profesionales.value.filter((p) => puedeGestionarTurno(p.id))

    if (esEdicion) {
      const turno = await obtenerTurno(turnoId)
      puedeEditar.value = puedeGestionarTurno(turno.profesional_id)
      if (!puedeEditar.value) {
        errorMensaje.value = 'No tenés permiso para modificar este turno.'
        return
      }
      // Si el servicio o el profesional del turno ya no están activos, igual se muestran
      if (!servicios.value.some((s) => s.id === turno.servicio_id)) servicios.value.push(turno.servicio)
      if (!profesionales.value.some((p) => p.id === turno.profesional_id)) {
        profesionales.value.push(turno.profesional)
      }

      paciente.value = turno.paciente
      servicioId.value = turno.servicio_id
      profesionalId.value = turno.profesional_id
      fecha.value = turno.fecha
      hora.value = formatearHora(turno.hora_inicio)
      horarioOriginal.value = {
        fecha: turno.fecha,
        hora: hora.value,
        servicio: turno.servicio_id,
        profesional: turno.profesional_id,
      }
      notas.value = turno.notas ?? ''
    } else {
      if (route.query.pacienteId) paciente.value = await obtenerPaciente(route.query.pacienteId)
      // Por defecto atiende el usuario conectado (si es profesional) o el primero de la lista
      const yo = profesionales.value.find((p) => p.id === sesion.perfil.id)
      profesionalId.value = yo?.id ?? profesionales.value[0]?.id ?? ''
    }
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    cargando.value = false
  }
})

function empezarPacienteNuevo(textoBuscado) {
  const texto = textoBuscado.trim()
  const esDni = /^[\d.]+$/.test(texto)
  const [nombre = '', ...resto] = esDni ? [] : texto.split(/\s+/)
  nuevoPaciente.value = {
    ...pacienteVacio(),
    nombre,
    apellido: resto.join(' '),
    dni: esDni ? texto.replace(/\D/g, '') : '',
  }
  errorPaciente.value = ''
  creandoPaciente.value = true
}

async function guardarPacienteNuevo() {
  errorPaciente.value = ''
  try {
    guardandoPaciente.value = true
    paciente.value = await crearPaciente(nuevoPaciente.value)
    creandoPaciente.value = false
  } catch (error) {
    errorPaciente.value = error.message
  } finally {
    guardandoPaciente.value = false
  }
}

async function guardar() {
  if (guardando.value) return
  errorMensaje.value = ''
  if (!puedeEditar.value || (profesionalId.value && !puedeGestionarTurno(profesionalId.value))) {
    errorMensaje.value = 'No tenés permiso para guardar este turno.'
    return
  }

  if (!paciente.value) {
    errorMensaje.value = 'Elegí o cargá el paciente del turno.'
    return
  }
  if (!servicioId.value || !profesionalId.value || !fecha.value || !hora.value) {
    errorMensaje.value = 'Completá servicio, profesional, fecha y hora.'
    return
  }

  if (buscandoHorarios.value || !opcionesHora.value.includes(hora.value)) {
    errorMensaje.value = 'Elegí un horario disponible para el servicio y profesional.'
    return
  }

  const datos = {
    paciente_id: paciente.value.id,
    profesional_id: profesionalId.value,
    servicio_id: servicioId.value,
    fecha: fecha.value,
    hora_inicio: hora.value,
    notas: notas.value,
  }

  try {
    guardando.value = true
    if (esEdicion) {
      await actualizarTurno(turnoId, datos)
      await router.push({ path: `/turnos/${turnoId}`, state: { turnoGuardado: 'editado' } })
    } else {
      await crearTurno(datos)
      await router.push({
        path: '/agenda',
        query: { fecha: fecha.value },
        state: { turnoGuardado: 'creado' },
      })
    }
  } catch (error) {
    errorMensaje.value = error.message
    // Por si otra persona tomó ese horario mientras tanto
    await actualizarHorarios()
  } finally {
    guardando.value = false
  }
}
</script>

<template>
  <main class="contenedor angosto">
    <RouterLink
      class="volver"
      :to="esEdicion ? `/turnos/${turnoId}` : { path: '/agenda', query: { fecha } }"
    >
      ← Volver
    </RouterLink>

    <h1>{{ esEdicion ? 'Editar turno' : 'Nuevo turno' }}</h1>

    <p v-if="cargando" class="vacio">Cargando...</p>

    <p v-else-if="!puedeEditar" class="mensaje error" role="alert">{{ errorMensaje }}</p>

    <template v-else>
      <section class="tarjeta">
        <h2>1. Paciente</h2>

        <div v-if="paciente" class="paciente-elegido">
          <div>
            <strong>{{ nombreCompleto(paciente) }}</strong>
            <small>DNI {{ paciente.dni || '—' }} · {{ paciente.telefono || 'sin teléfono' }}</small>
          </div>
          <button type="button" class="btn secundario chico" @click="paciente = null">Cambiar</button>
        </div>

        <form v-else-if="creandoPaciente" class="formulario" @submit.prevent="guardarPacienteNuevo">
          <FormularioPaciente v-model="nuevoPaciente" :completo="false" />
          <p v-if="errorPaciente" class="mensaje error">{{ errorPaciente }}</p>
          <div class="acciones">
            <button type="submit" class="btn chico" :disabled="guardandoPaciente">
              {{ guardandoPaciente ? 'Guardando...' : 'Guardar paciente' }}
            </button>
            <button type="button" class="btn secundario chico" @click="creandoPaciente = false">
              Cancelar
            </button>
          </div>
        </form>

        <BuscadorPaciente v-else @seleccionar="paciente = $event" @crear="empezarPacienteNuevo" />
      </section>

      <form class="tarjeta formulario" @submit.prevent="guardar">
        <h2>2. Turno</h2>

        <label class="campo">
          <span>Servicio</span>
          <select v-model="servicioId" required>
            <option disabled value="">Elegir servicio...</option>
            <option v-for="s in servicios" :key="s.id" :value="s.id">
              {{ s.nombre }} ({{ s.duracion_min }} min)
            </option>
          </select>
        </label>

        <label v-if="profesionales.length > 1" class="campo">
          <span>Profesional</span>
          <select v-model="profesionalId" required>
            <option v-for="p in profesionales" :key="p.id" :value="p.id">{{ nombreCompleto(p) }}</option>
          </select>
        </label>

        <div class="fila-campos">
          <label class="campo">
            <span>Fecha</span>
            <input v-model="fecha" type="date" :min="esEdicion ? null : hoyISO()" required />
          </label>
          <label class="campo">
            <span>Hora</span>
            <select v-model="hora" :disabled="buscandoHorarios || !opcionesHora.length" required>
              <option disabled value="">{{ textoHora }}</option>
              <option v-for="h in opcionesHora" :key="h" :value="h">{{ h }}</option>
            </select>
          </label>
        </div>

        <p v-if="fecha && !atiendeEseDia(fecha)" class="mensaje aviso">
          El consultorio no atiende ese día. Elegí otra fecha.
        </p>
        <small v-else>
          Atención: {{ horarioConsultorio }}. Solo se muestran los horarios libres del profesional.
        </small>

        <label class="campo">
          <span>Notas</span>
          <textarea v-model="notas" rows="2" placeholder="Opcional"></textarea>
        </label>

        <p v-if="errorMensaje" class="mensaje error">{{ errorMensaje }}</p>

        <div class="acciones">
          <button type="submit" class="btn" :disabled="guardando || buscandoHorarios">
            {{ guardando ? 'Guardando...' : esEdicion ? 'Guardar cambios' : 'Confirmar turno' }}
          </button>
        </div>
      </form>
    </template>
  </main>
</template>

<style scoped>
.paciente-elegido {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  background: var(--violeta-suave);
  border-radius: 8px;
}

.paciente-elegido div { display: grid; }
</style>
