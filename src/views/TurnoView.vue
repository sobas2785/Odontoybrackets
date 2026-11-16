<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import EtiquetaEstado from '@/components/EtiquetaEstado.vue'
import { sesion, tieneRol } from '@/services/auth'
import { nombreCompleto } from '@/services/consultorio'
import { obtenerTratamientoActual } from '@/services/tratamientos'
import {
  cambiarEstadoTurno,
  eliminarTurno,
  linkRecordatorioWhatsApp,
  obtenerTurno,
  puedeGestionarTurno,
} from '@/services/turnos'
import { formatearFecha, formatearFechaLarga, formatearHora } from '@/utils/fechas'

const route = useRoute()
const router = useRouter()

const turno = ref(null)
const tratamiento = ref(null)
const cargando = ref(true)
const trabajando = ref(false)
const errorMensaje = ref('')
const mensaje = ref(window.history.state?.turnoGuardado === 'editado' ? 'Turno actualizado correctamente.' : '')

const linkWhatsApp = computed(() =>
  turno.value
    ? linkRecordatorioWhatsApp(turno.value, sesion.consultorio?.nombre, formatearFechaLarga(turno.value.fecha))
    : null,
)

const puedeGestionar = computed(() => puedeGestionarTurno(turno.value?.profesional_id))

const volverA = computed(() => ({ path: '/agenda', query: { fecha: turno.value?.fecha } }))

async function cargar() {
  turno.value = await obtenerTurno(route.params.id)
  tratamiento.value = await obtenerTratamientoActual(turno.value.paciente_id)
}

onMounted(async () => {
  try {
    await cargar()
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    cargando.value = false
  }
})

async function cambiarEstado(estado, textoExito) {
  if (!puedeGestionar.value || trabajando.value) return
  if (estado === 'cancelado' && !window.confirm('¿Querés cancelar este turno? El horario queda libre.')) {
    return
  }
  errorMensaje.value = ''
  mensaje.value = ''
  try {
    trabajando.value = true
    await cambiarEstadoTurno(turno.value.id, estado)
    await cargar()
    mensaje.value = textoExito
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    trabajando.value = false
  }
}

async function eliminar() {
  if (!tieneRol('admin') || trabajando.value) return
  if (!window.confirm('¿Eliminar el turno definitivamente? Esta acción no se puede deshacer.')) return
  errorMensaje.value = ''
  mensaje.value = ''
  try {
    trabajando.value = true
    await eliminarTurno(turno.value.id)
    await router.push({ ...volverA.value, state: { turnoGuardado: 'eliminado' } })
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    trabajando.value = false
  }
}
</script>

<template>
  <main class="contenedor angosto">
    <p v-if="mensaje" class="mensaje exito" role="status">{{ mensaje }}</p>
    <RouterLink class="volver" :to="volverA">← Volver a la agenda</RouterLink>

    <p v-if="cargando" class="vacio">Cargando turno...</p>
    <p v-else-if="!turno" class="mensaje error">{{ errorMensaje || 'No se encontró el turno.' }}</p>

    <template v-else>
      <div class="cabecera-pagina">
        <div>
          <p class="etiqueta-seccion">Turno</p>
          <h1>
            <RouterLink :to="`/pacientes/${turno.paciente.id}`">{{ nombreCompleto(turno.paciente) }}</RouterLink>
          </h1>
        </div>
        <EtiquetaEstado :estado="turno.estado" />
      </div>

      <section class="tarjeta">
        <dl class="datos">
          <dt>Fecha</dt>
          <dd class="capitalizar">{{ formatearFechaLarga(turno.fecha) }}</dd>
          <dt>Horario</dt>
          <dd>{{ formatearHora(turno.hora_inicio) }} a {{ formatearHora(turno.hora_fin) }} hs</dd>
          <dt>Servicio</dt>
          <dd>{{ turno.servicio.nombre }}</dd>
          <dt>Profesional</dt>
          <dd>{{ nombreCompleto(turno.profesional) }}</dd>
          <dt>Notas</dt>
          <dd>{{ turno.notas || '—' }}</dd>
        </dl>
      </section>

      <section class="tarjeta">
        <h2>Ficha del paciente</h2>
        <dl class="datos">
          <dt>Tratamiento</dt>
          <dd>
            <template v-if="tratamiento">
              {{ tratamiento.servicio.nombre }}
              <small>desde {{ formatearFecha(tratamiento.fecha_inicio) }}</small>
            </template>
            <template v-else>Sin tratamiento en curso</template>
          </dd>
          <dt>Próximo control</dt>
          <dd>{{ formatearFecha(tratamiento?.proximo_control) }}</dd>
          <dt>Teléfono</dt>
          <dd>{{ turno.paciente.telefono || '—' }}</dd>
          <dt>Observaciones</dt>
          <dd>{{ turno.paciente.observaciones || '—' }}</dd>
        </dl>
        <div class="acciones espacio-arriba">
          <RouterLink class="btn secundario chico" :to="`/pacientes/${turno.paciente.id}`">Ver ficha completa</RouterLink>
          <a v-if="linkWhatsApp" class="btn secundario chico" :href="linkWhatsApp" target="_blank" rel="noopener">
            Enviar recordatorio por WhatsApp
          </a>
        </div>
      </section>


      <p v-if="errorMensaje" class="mensaje error">{{ errorMensaje }}</p>

      <div v-if="puedeGestionar" class="acciones espacio-arriba">
        <template v-if="['pendiente', 'confirmado'].includes(turno.estado)">
          <button
            v-if="turno.estado === 'pendiente'"
            class="btn secundario"
            :disabled="trabajando"
            @click="cambiarEstado('confirmado', 'Turno confirmado.')"
          >
            Confirmar
          </button>
          <button class="btn exito" :disabled="trabajando" @click="cambiarEstado('atendido', 'Turno marcado como atendido.')">
            Atendido
          </button>
          <button class="btn secundario" :disabled="trabajando" @click="cambiarEstado('ausente', 'Turno marcado como ausente.')">
            No vino
          </button>
          <RouterLink class="btn secundario" :to="`/turnos/${turno.id}/editar`">Editar / reprogramar</RouterLink>
          <button class="btn peligro" :disabled="trabajando" @click="cambiarEstado('cancelado', 'Turno cancelado.')">
            Cancelar turno
          </button>
        </template>

        <button
          v-else
          class="btn secundario"
          :disabled="trabajando"
          @click="cambiarEstado('pendiente', 'El turno volvió a quedar pendiente.')"
        >
          Volver a pendiente
        </button>

        <button v-if="tieneRol('admin')" class="btn peligro" :disabled="trabajando" @click="eliminar">
          Eliminar
        </button>
      </div>
    </template>
  </main>
</template>

<style scoped>
h1 a { color: inherit; text-decoration: none; }
h1 a:hover { color: var(--violeta); }
.capitalizar::first-letter { text-transform: uppercase; }
.espacio-arriba { margin-top: 12px; margin-bottom: 16px; }
</style>
