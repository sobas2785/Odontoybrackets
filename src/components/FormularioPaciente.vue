<script setup>
// Campos del paciente. Se usa en el ABM de pacientes y, en versión
// reducida, para crear un paciente rápido desde "Nuevo turno".
const datos = defineModel({ type: Object, required: true })

defineProps({
  completo: { type: Boolean, default: true },
})
</script>

<template>
  <div class="formulario">
    <div class="fila-campos">
      <label class="campo">
        <span>Nombre *</span>
        <input v-model="datos.nombre" type="text" maxlength="80" required />
      </label>
      <label class="campo">
        <span>Apellido *</span>
        <input v-model="datos.apellido" type="text" maxlength="80" required />
      </label>
    </div>

    <div class="fila-campos">
      <label class="campo">
        <span>DNI</span>
        <input v-model="datos.dni" type="text" inputmode="numeric" maxlength="10" placeholder="Sin puntos" />
      </label>
      <label class="campo">
        <span>Teléfono</span>
        <input v-model="datos.telefono" type="tel" maxlength="30" placeholder="11 5555-5555" />
      </label>
    </div>

    <template v-if="completo">
      <div class="fila-campos">
        <label class="campo">
          <span>Fecha de nacimiento</span>
          <input v-model="datos.fecha_nacimiento" type="date" />
        </label>
        <label class="campo">
          <span>Obra social</span>
          <input v-model="datos.obra_social" type="text" maxlength="80" />
        </label>
      </div>

      <label class="campo">
        <span>Email</span>
        <input v-model="datos.email" type="email" maxlength="120" />
      </label>

      <label class="campo">
        <span>Observaciones</span>
        <textarea v-model="datos.observaciones" rows="3"></textarea>
      </label>
    </template>
  </div>
</template>
