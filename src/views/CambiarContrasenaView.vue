<script setup>
import { ref } from 'vue'
import { cambiarContrasena } from '@/services/auth'

const actual = ref('')
const nueva = ref('')
const repetirNueva = ref('')

const cargando = ref(false)
const mensaje = ref('')
const cambioExitoso = ref(false)

async function guardar() {
  mensaje.value = ''
  cambioExitoso.value = false

  if (nueva.value.length < 6) {
    mensaje.value = 'La contraseña nueva debe tener al menos 6 caracteres.'
    return
  }
  if (nueva.value !== repetirNueva.value) {
    mensaje.value = 'Las contraseñas nuevas no coinciden.'
    return
  }
  if (nueva.value === actual.value) {
    mensaje.value = 'La contraseña nueva tiene que ser distinta de la actual.'
    return
  }

  try {
    cargando.value = true
    await cambiarContrasena(actual.value, nueva.value)
    cambioExitoso.value = true
    mensaje.value = 'Listo, tu contraseña se cambió correctamente.'
    actual.value = ''
    nueva.value = ''
    repetirNueva.value = ''
  } catch (error) {
    mensaje.value = error.message
  } finally {
    cargando.value = false
  }
}
</script>

<template>
  <main class="contenedor angosto">
    <p class="etiqueta-seccion">Mi cuenta</p>
    <h1>Cambiar contraseña</h1>

    <form class="tarjeta formulario" @submit.prevent="guardar">
      <label class="campo">
        <span>Contraseña actual</span>
        <input v-model="actual" type="password" autocomplete="current-password" required />
      </label>

      <label class="campo">
        <span>Contraseña nueva</span>
        <input
          v-model="nueva"
          type="password"
          placeholder="Mínimo 6 caracteres"
          autocomplete="new-password"
          required
        />
      </label>

      <label class="campo">
        <span>Repetir contraseña nueva</span>
        <input v-model="repetirNueva" type="password" autocomplete="new-password" required />
      </label>

      <p v-if="mensaje" class="mensaje" :class="cambioExitoso ? 'exito' : 'error'">{{ mensaje }}</p>

      <div class="acciones">
        <button type="submit" class="btn" :disabled="cargando">
          {{ cargando ? 'Guardando...' : 'Cambiar contraseña' }}
        </button>
      </div>
    </form>
  </main>
</template>
