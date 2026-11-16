<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SelectorDia from '@/components/SelectorDia.vue'
import TarjetaTurno from '@/components/TarjetaTurno.vue'
import { sesion } from '@/services/auth'
import { listarProfesionales, nombreCompleto } from '@/services/consultorio'
import { atiendeEseDia, listarTurnosDelDia } from '@/services/turnos'
import { formatearFechaLarga, hoyISO } from '@/utils/fechas'

const route = useRoute()
const router = useRouter()
const avisosGuardado = {
  creado: 'Turno creado correctamente.',
  eliminado: 'Turno eliminado correctamente.',
}
const mensajeGuardado = avisosGuardado[window.history.state?.turnoGuardado]

// La fecha va en la dirección (/agenda?fecha=2026-10-14) para poder volver al mismo día
const fecha = computed({
  get: () => route.query.fecha || hoyISO(),
  set: (nuevaFecha) => router.replace({ query: { ...route.query, fecha: nuevaFecha } }),
})

const profesionalElegido = computed({
  get: () => route.query.profesional || '',
  set: (id) => router.replace({ query: { ...route.query, profesional: id || undefined } }),
})

const turnos = ref([])
const profesionales = ref([])
const mostrarCancelados = ref(false)
const ordenHora = ref('asc')
const cargando = ref(true)
const errorMensaje = ref('')

const titulo = computed(() =>
  fecha.value === hoyISO() ? `Hoy, ${formatearFechaLarga(fecha.value)}` : formatearFechaLarga(fecha.value),
)

const turnosVisibles = computed(() => {
  const visibles = turnos.value.filter(
    (turno) =>
      (mostrarCancelados.value || turno.estado !== 'cancelado') &&
      (!profesionalElegido.value || turno.profesional_id === profesionalElegido.value),
  )
  return ordenHora.value === 'desc' ? visibles.reverse() : visibles
})

const cantidadCancelados = computed(() => turnos.value.filter((t) => t.estado === 'cancelado').length)

onMounted(async () => {
  try {
    ;[turnos.value, profesionales.value] = await Promise.all([
      listarTurnosDelDia(fecha.value),
      listarProfesionales(),
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
    <p v-if="mensajeGuardado" class="mensaje exito" role="status">{{ mensajeGuardado }}</p>
    <div class="cabecera-pagina">
      <div>
        <p class="etiqueta-seccion">Agenda del día</p>
        <h1 class="titulo-dia">{{ titulo }}</h1>
      </div>
      <SelectorDia v-model="fecha" />
    </div>

    <div class="filtros">
      <label class="campo-filtro">
        <span>Orden por hora</span>
        <select v-model="ordenHora">
          <option value="asc">Más temprano primero</option>
          <option value="desc">Más tarde primero</option>
        </select>
      </label>
      <label v-if="profesionales.length > 1" class="campo-filtro">
        <span>Profesional</span>
        <select v-model="profesionalElegido">
          <option value="">Todos</option>
          <option v-for="p in profesionales" :key="p.id" :value="p.id">{{ nombreCompleto(p) }}</option>
        </select>
      </label>
      <label v-if="cantidadCancelados" class="check">
        <input v-model="mostrarCancelados" type="checkbox" />
        Mostrar cancelados ({{ cantidadCancelados }})
      </label>
    </div>

    <p v-if="!atiendeEseDia(fecha)" class="mensaje aviso">
      {{ sesion.consultorio?.nombre }} no atiende este día.
    </p>

    <p v-if="errorMensaje" class="mensaje error">{{ errorMensaje }}</p>
    <p v-else-if="cargando" class="vacio">Cargando turnos...</p>
    <p v-else-if="!turnosVisibles.length" class="vacio">No hay turnos para este día.</p>

    <template v-else>
      <p class="texto-suave">{{ turnosVisibles.length }} turno(s)</p>
      <TarjetaTurno
        v-for="turno in turnosVisibles"
        :key="turno.id"
        :turno="turno"
        :mostrar-profesional="profesionales.length > 1"
      />
    </template>

    <RouterLink
      class="btn flotante"
      :to="{ path: '/turnos/nuevo', query: { fecha } }"
      title="Nuevo turno"
      aria-label="Nuevo turno"
    >
      +
    </RouterLink>
  </main>
</template>

<style scoped>
.titulo-dia::first-letter { text-transform: uppercase; }

.filtros {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px 20px;
  margin-bottom: 12px;
}

.campo-filtro {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.campo-filtro select { width: auto; }
</style>
