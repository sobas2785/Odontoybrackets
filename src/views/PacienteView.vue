<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import EtiquetaEstado from '@/components/EtiquetaEstado.vue'
import { tieneRol } from '@/services/auth'
import { nombreCompleto } from '@/services/consultorio'
import { obtenerPaciente } from '@/services/pacientes'
import { listarServicios } from '@/services/servicios'
import {
  ESTADOS_TRATAMIENTO,
  actualizarTratamiento,
  crearTratamiento,
  eliminarTratamiento,
  listarTratamientos,
} from '@/services/tratamientos'
import { listarTurnosDePaciente } from '@/services/turnos'
import { calcularEdad, formatearFecha, formatearHora, hoyISO } from '@/utils/fechas'

const route = useRoute()
const router = useRouter()
const pacienteId = route.params.id

const paciente = ref(null)
const turnos = ref([])
const tratamientos = ref([])
const servicios = ref([])

const cargando = ref(true)
const errorMensaje = ref('')

const puedeEditarTratamientos = computed(() => tieneRol('admin', 'profesional'))

// "Último turno" y "próximo turno" no se guardan: se calculan con el historial
const ultimoTurno = computed(() =>
  turnos.value.find((t) => t.fecha < hoyISO() && !['cancelado', 'ausente'].includes(t.estado)),
)
const proximoTurno = computed(() =>
  [...turnos.value]
    .reverse()
    .find((t) => t.fecha >= hoyISO() && ['pendiente', 'confirmado'].includes(t.estado)),
)
const tratamientoActual = computed(() => tratamientos.value.find((t) => t.estado === 'en_curso'))

// ---- Formulario de tratamiento ----
const mostrandoFormulario = ref(false)
const tratamientoEditandoId = ref(null)
const datosTratamiento = ref(tratamientoVacio())
const guardando = ref(false)
const errorTratamiento = ref('')

function tratamientoVacio() {
  return {
    servicio_id: '',
    fecha_inicio: hoyISO(),
    fecha_fin: '',
    proximo_control: '',
    estado: 'en_curso',
    observaciones: '',
  }
}

function nuevoTratamiento() {
  tratamientoEditandoId.value = null
  datosTratamiento.value = tratamientoVacio()
  errorTratamiento.value = ''
  mostrandoFormulario.value = true
}

function editarTratamiento(tratamiento) {
  tratamientoEditandoId.value = tratamiento.id
  datosTratamiento.value = {
    servicio_id: tratamiento.servicio_id,
    fecha_inicio: tratamiento.fecha_inicio,
    fecha_fin: tratamiento.fecha_fin ?? '',
    proximo_control: tratamiento.proximo_control ?? '',
    estado: tratamiento.estado,
    observaciones: tratamiento.observaciones ?? '',
  }
  errorTratamiento.value = ''
  mostrandoFormulario.value = true
}

async function guardarTratamiento() {
  errorTratamiento.value = ''
  if (!datosTratamiento.value.servicio_id) {
    errorTratamiento.value = 'Elegí el tipo de tratamiento.'
    return
  }
  try {
    guardando.value = true
    if (tratamientoEditandoId.value) {
      await actualizarTratamiento(tratamientoEditandoId.value, datosTratamiento.value)
    } else {
      await crearTratamiento(pacienteId, datosTratamiento.value)
    }
    tratamientos.value = await listarTratamientos(pacienteId)
    mostrandoFormulario.value = false
  } catch (error) {
    errorTratamiento.value = error.message
  } finally {
    guardando.value = false
  }
}

async function borrarTratamiento(tratamiento) {
  if (!window.confirm(`¿Eliminar el tratamiento "${tratamiento.servicio.nombre}"?`)) return
  try {
    await eliminarTratamiento(tratamiento.id)
    tratamientos.value = await listarTratamientos(pacienteId)
  } catch (error) {
    errorMensaje.value = error.message
  }
}

onMounted(async () => {
  try {
    ;[paciente.value, turnos.value, tratamientos.value, servicios.value] = await Promise.all([
      obtenerPaciente(pacienteId),
      listarTurnosDePaciente(pacienteId),
      listarTratamientos(pacienteId),
      listarServicios(),
    ])
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    cargando.value = false
  }
})
</script>

<template>
  <main class="contenedor">
    <RouterLink class="volver" to="/pacientes">← Volver a pacientes</RouterLink>

    <p v-if="cargando" class="vacio">Cargando ficha...</p>
    <p v-else-if="!paciente" class="mensaje error">{{ errorMensaje || 'No se encontró el paciente.' }}</p>

    <template v-else>
      <div class="cabecera-pagina">
        <div>
          <p class="etiqueta-seccion">Ficha del paciente</p>
          <h1>
            {{ nombreCompleto(paciente) }}
            <EtiquetaEstado v-if="!paciente.activo" estado="inactivo" texto="De baja" />
          </h1>
        </div>
        <div class="acciones">
          <RouterLink class="btn secundario" :to="{ path: '/pacientes', query: { editar: paciente.id } }">
            Editar datos
          </RouterLink>
          <RouterLink
            v-if="paciente.activo"
            class="btn"
            :to="{ path: '/turnos/nuevo', query: { pacienteId: paciente.id } }"
          >
            + Nuevo turno
          </RouterLink>
        </div>
      </div>

      <p v-if="errorMensaje" class="mensaje error">{{ errorMensaje }}</p>

      <div class="dos-columnas">
        <section class="tarjeta">
          <h2>Resumen</h2>
          <dl class="datos">
            <dt>Tratamiento</dt>
            <dd>{{ tratamientoActual?.servicio.nombre ?? 'Sin tratamiento en curso' }}</dd>
            <dt>Próximo control</dt>
            <dd>{{ formatearFecha(tratamientoActual?.proximo_control) }}</dd>
            <dt>Último turno</dt>
            <dd>
              <template v-if="ultimoTurno">
                {{ formatearFecha(ultimoTurno.fecha) }} · {{ ultimoTurno.servicio.nombre }}
              </template>
              <template v-else>—</template>
            </dd>
            <dt>Próximo turno</dt>
            <dd>
              <RouterLink v-if="proximoTurno" :to="`/turnos/${proximoTurno.id}`">
                {{ formatearFecha(proximoTurno.fecha) }} {{ formatearHora(proximoTurno.hora_inicio) }} hs ·
                {{ proximoTurno.servicio.nombre }}
              </RouterLink>
              <template v-else>—</template>
            </dd>
            <dt>Observaciones</dt>
            <dd>{{ paciente.observaciones || '—' }}</dd>
          </dl>
        </section>

        <section class="tarjeta">
          <h2>Datos personales</h2>
          <dl class="datos">
            <dt>DNI</dt>
            <dd>{{ paciente.dni || '—' }}</dd>
            <dt>Nacimiento</dt>
            <dd>
              {{ formatearFecha(paciente.fecha_nacimiento) }}
              <small v-if="paciente.fecha_nacimiento">({{ calcularEdad(paciente.fecha_nacimiento) }} años)</small>
            </dd>
            <dt>Teléfono</dt>
            <dd>{{ paciente.telefono || '—' }}</dd>
            <dt>Email</dt>
            <dd>{{ paciente.email || '—' }}</dd>
            <dt>Obra social</dt>
            <dd>{{ paciente.obra_social || '—' }}</dd>
          </dl>
        </section>
      </div>

      <section class="tarjeta">
        <div class="cabecera-pagina">
          <h2>Tratamientos</h2>
          <button v-if="puedeEditarTratamientos && !mostrandoFormulario" class="btn secundario chico" @click="nuevoTratamiento">
            + Nuevo tratamiento
          </button>
        </div>

        <form v-if="mostrandoFormulario" class="formulario formulario-tratamiento" @submit.prevent="guardarTratamiento">
          <div class="fila-campos">
            <label class="campo">
              <span>Tratamiento</span>
              <select v-model="datosTratamiento.servicio_id" required>
                <option disabled value="">Elegir...</option>
                <option v-for="s in servicios" :key="s.id" :value="s.id">
                  {{ s.nombre }}{{ s.activo ? '' : ' (inactivo)' }}
                </option>
              </select>
            </label>
            <label class="campo">
              <span>Estado</span>
              <select v-model="datosTratamiento.estado">
                <option v-for="(texto, valor) in ESTADOS_TRATAMIENTO" :key="valor" :value="valor">{{ texto }}</option>
              </select>
            </label>
          </div>
          <div class="fila-campos">
            <label class="campo">
              <span>Inicio</span>
              <input v-model="datosTratamiento.fecha_inicio" type="date" required />
            </label>
            <label class="campo">
              <span>Próximo control</span>
              <input v-model="datosTratamiento.proximo_control" type="date" />
            </label>
          </div>
          <label v-if="datosTratamiento.estado !== 'en_curso'" class="campo">
            <span>Fecha de fin</span>
            <input v-model="datosTratamiento.fecha_fin" type="date" />
          </label>
          <label class="campo">
            <span>Observaciones</span>
            <textarea v-model="datosTratamiento.observaciones" rows="2"></textarea>
          </label>
          <p v-if="errorTratamiento" class="mensaje error">{{ errorTratamiento }}</p>
          <div class="acciones">
            <button type="submit" class="btn chico" :disabled="guardando">
              {{ guardando ? 'Guardando...' : 'Guardar tratamiento' }}
            </button>
            <button type="button" class="btn secundario chico" @click="mostrandoFormulario = false">Cancelar</button>
          </div>
        </form>

        <p v-if="!tratamientos.length" class="vacio">Sin tratamientos registrados.</p>
        <div v-else class="tabla-contenedor">
          <table>
            <thead>
              <tr>
                <th>Tratamiento</th>
                <th>Inicio</th>
                <th>Próximo control</th>
                <th>Estado</th>
                <th v-if="puedeEditarTratamientos">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="t in tratamientos" :key="t.id">
                <td class="texto-largo">
                  <strong>{{ t.servicio.nombre }}</strong>
                  <small>{{ t.observaciones }}</small>
                </td>
                <td>{{ formatearFecha(t.fecha_inicio) }}</td>
                <td>{{ formatearFecha(t.proximo_control) }}</td>
                <td><EtiquetaEstado :estado="t.estado" /></td>
                <td v-if="puedeEditarTratamientos">
                  <div class="acciones">
                    <button class="btn secundario chico" @click="editarTratamiento(t)">Editar</button>
                    <button class="btn peligro chico" @click="borrarTratamiento(t)">Eliminar</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="tarjeta">
        <h2>Historial de turnos</h2>
        <p v-if="!turnos.length" class="vacio">Este paciente todavía no tiene turnos.</p>
        <div v-else class="tabla-contenedor">
          <table>
            <thead>
              <tr>
                <th>Fecha</th>
                <th>Hora</th>
                <th>Servicio</th>
                <th>Profesional</th>
                <th>Estado</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="t in turnos" :key="t.id" class="clickeable" @click="router.push(`/turnos/${t.id}`)">
                <td>{{ formatearFecha(t.fecha) }}</td>
                <td>{{ formatearHora(t.hora_inicio) }}</td>
                <td>{{ t.servicio.nombre }}</td>
                <td>{{ nombreCompleto(t.profesional) }}</td>
                <td><EtiquetaEstado :estado="t.estado" /></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </template>
  </main>
</template>

<style scoped>
h1 { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; }

.formulario-tratamiento {
  padding: 12px;
  margin-bottom: 16px;
  background: var(--gris-claro);
  border-radius: 8px;
}
</style>
