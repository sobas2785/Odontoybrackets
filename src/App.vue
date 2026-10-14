<script setup>
import { useRoute } from 'vue-router'
import BarraNavegacion from '@/components/BarraNavegacion.vue'

const route = useRoute()
</script>

<template>
  <BarraNavegacion v-if="route.meta.requiereAutenticacion" />
  <!-- La key hace que la vista se vuelva a cargar si cambia la dirección (ej. otro día de la agenda) -->
  <RouterView :key="route.fullPath" />
</template>
