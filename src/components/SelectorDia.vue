<script setup>
import { computed } from 'vue'
import { hoyISO, sumarDias } from '@/utils/fechas'

// v-model con la fecha elegida ('AAAA-MM-DD')
const fecha = defineModel({ type: String, required: true })

const esHoy = computed(() => fecha.value === hoyISO())

function elegir(evento) {
  if (evento.target.value) fecha.value = evento.target.value
}
</script>

<template>
  <div class="selector-dia">
    <button type="button" class="btn secundario chico" aria-label="Día anterior" @click="fecha = sumarDias(fecha, -1)">
      ‹
    </button>
    <input type="date" :value="fecha" aria-label="Elegir día" @change="elegir" />
    <button type="button" class="btn secundario chico" aria-label="Día siguiente" @click="fecha = sumarDias(fecha, 1)">
      ›
    </button>
    <button v-if="!esHoy" type="button" class="btn secundario chico" @click="fecha = hoyISO()">Hoy</button>
  </div>
</template>

<style scoped>
.selector-dia {
  display: flex;
  align-items: center;
  gap: 6px;
}

.selector-dia input {
  width: auto;
}

.selector-dia .btn {
  font-size: 18px;
  line-height: 1;
}
</style>
