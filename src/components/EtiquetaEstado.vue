<script setup>
import { computed } from 'vue'
import { ESTADOS_TURNO } from '@/services/turnos'
import { ESTADOS_TRATAMIENTO } from '@/services/tratamientos'

const props = defineProps({
  estado: { type: String, required: true },
  texto: { type: String, default: '' },
})

const TEXTOS = {
  ...ESTADOS_TURNO,
  ...ESTADOS_TRATAMIENTO,
  activo: 'Activo',
  inactivo: 'Inactivo',
}

const textoVisible = computed(() => props.texto || TEXTOS[props.estado] || props.estado)
</script>

<template>
  <span class="estado" :class="estado">{{ textoVisible }}</span>
</template>
