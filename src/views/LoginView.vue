<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { iniciarSesion } from '@/services/auth'

const route = useRoute()
const router = useRouter()

const correo = ref('')
const contrasena = ref('')

const cargando = ref(false)
const mensaje = ref(
  route.query.motivo === 'sin-acceso'
    ? 'Tu usuario no tiene acceso a ningún consultorio activo.'
    : '',
)

async function ingresar() {
  mensaje.value = ''
  try {
    cargando.value = true
    await iniciarSesion(correo.value.trim(), contrasena.value)
    router.push('/agenda')
  } catch (error) {
    mensaje.value = error.message
  } finally {
    cargando.value = false
  }
}
</script>

<template>
  <main class="pagina-acceso">
    <section class="tarjeta-acceso">
      <div class="marca-acceso">
        <img src="/favicon.svg" alt="" />
        <span class="nombre-marca">Odontoybrackets</span>
        <small>Turnos y pacientes de tu consultorio</small>
      </div>

      <h1>Iniciar sesión</h1>

      <form class="formulario" @submit.prevent="ingresar">
        <label class="campo">
          <span>Correo electrónico</span>
          <input v-model="correo" type="email" placeholder="nombre@correo.com" autocomplete="email" required />
        </label>

        <label class="campo">
          <span>Contraseña</span>
          <input
            v-model="contrasena"
            type="password"
            placeholder="Ingresá tu contraseña"
            autocomplete="current-password"
            required
          />
        </label>

        <p v-if="mensaje" class="mensaje error">{{ mensaje }}</p>

        <button type="submit" class="btn" :disabled="cargando">
          {{ cargando ? 'Ingresando...' : 'Ingresar' }}
        </button>
      </form>

      <p class="pie-acceso">
        ¿Todavía no usás Odontoybrackets?
        <RouterLink to="/registro">Registrá tu consultorio</RouterLink>
      </p>
    </section>
  </main>
</template>
