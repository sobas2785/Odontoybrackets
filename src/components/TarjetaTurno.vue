<script setup>
import EtiquetaEstado from './EtiquetaEstado.vue'
import { formatearHora } from '@/utils/fechas'
import { nombreCompleto } from '@/services/consultorio'

defineProps({
  turno: { type: Object, required: true },
  mostrarProfesional: { type: Boolean, default: false },
})
</script>

<template>
  <RouterLink :to="`/turnos/${turno.id}`" class="fila-turno" :class="turno.estado">
    <div class="hora">
      <strong>{{ formatearHora(turno.hora_inicio) }}</strong>
      <small>a {{ formatearHora(turno.hora_fin) }}</small>
    </div>

    <div class="paciente">
      <strong>{{ nombreCompleto(turno.paciente) }}</strong>
    </div>

    <div class="servicio">
      {{ turno.servicio?.nombre }}
      <small v-if="mostrarProfesional">con {{ nombreCompleto(turno.profesional) }}</small>
    </div>

    <EtiquetaEstado :estado="turno.estado" />
  </RouterLink>
</template>

<style scoped>
.fila-turno {
  display: grid;
  grid-template-columns: 80px 1fr 1fr auto;
  gap: 12px;
  align-items: center;
  padding: 12px 16px;
  background: var(--blanco);
  border: 1px solid var(--borde);
  border-left: 4px solid var(--violeta);
  border-radius: var(--radio);
  color: inherit;
  text-decoration: none;
  margin-bottom: 8px;
}

.fila-turno:hover { border-color: var(--celeste); }
.fila-turno.confirmado { border-left-color: var(--celeste); }
.fila-turno.atendido { border-left-color: var(--verde); }
.fila-turno.ausente { border-left-color: var(--rojo); }
.fila-turno.cancelado { border-left-color: var(--borde); opacity: 0.65; }
.fila-turno.cancelado .paciente strong { text-decoration: line-through; }

.fila-turno .estado { justify-self: start; }
.hora { display: grid; }
.hora strong { color: var(--violeta); font-size: 17px; }
.servicio { font-size: 14px; display: grid; }

@media (max-width: 600px) {
  .fila-turno {
    grid-template-columns: 64px 1fr;
    row-gap: 4px;
  }
  .hora { grid-row: span 3; }
}
</style>
