<script setup>
import { ref, watch } from 'vue'
import { listarPacientes } from '@/services/pacientes'

const emit = defineEmits(['seleccionar', 'crear'])

const texto = ref('')
const resultados = ref([])
const buscando = ref(false)
const errorMensaje = ref('')

let temporizador = null
let numeroBusqueda = 0

// Busca mientras se escribe, esperando 300 ms entre teclas
watch(texto, (valor) => {
  clearTimeout(temporizador)
  if (valor.trim().length < 2) {
    resultados.value = []
    return
  }
  temporizador = setTimeout(() => buscar(valor), 300)
})

async function buscar(valor) {
  const numero = ++numeroBusqueda
  buscando.value = true
  errorMensaje.value = ''
  try {
    const encontrados = await listarPacientes({ texto: valor, limite: 8 })
    // Si mientras tanto se escribió otra cosa, se descarta esta respuesta
    if (numero === numeroBusqueda) resultados.value = encontrados
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    if (numero === numeroBusqueda) buscando.value = false
  }
}
</script>

<template>
  <div class="buscador">
    <input
      v-model="texto"
      type="search"
      placeholder="Buscar por nombre, apellido o DNI..."
      autocomplete="off"
    />

    <p v-if="errorMensaje" class="mensaje error">{{ errorMensaje }}</p>

    <ul v-if="resultados.length" class="resultados">
      <li v-for="paciente in resultados" :key="paciente.id">
        <button type="button" @click="emit('seleccionar', paciente)">
          <strong>{{ paciente.apellido }}, {{ paciente.nombre }}</strong>
          <small>DNI {{ paciente.dni || '—' }} · {{ paciente.telefono || 'sin teléfono' }}</small>
        </button>
      </li>
    </ul>
    <p v-else-if="texto.trim().length >= 2 && !buscando" class="texto-suave">
      No se encontraron pacientes con ese dato.
    </p>

    <button type="button" class="btn secundario chico" @click="emit('crear', texto)">
      + Paciente nuevo
    </button>
  </div>
</template>

<style scoped>
.buscador {
  display: grid;
  gap: 8px;
  justify-items: start;
}

.buscador input { width: 100%; }

.resultados {
  list-style: none;
  margin: 0;
  padding: 0;
  width: 100%;
  border: 1px solid var(--borde);
  border-radius: 8px;
  overflow: hidden;
}

.resultados li + li { border-top: 1px solid var(--borde); }

.resultados button {
  display: grid;
  width: 100%;
  text-align: left;
  padding: 8px 12px;
  background: var(--blanco);
  border: none;
  font: inherit;
  color: inherit;
  cursor: pointer;
}

.resultados button:hover { background: var(--celeste-suave); }
</style>
