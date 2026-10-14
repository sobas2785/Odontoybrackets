<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { registrarUsuario, cargarSesion } from '@/services/auth'

const router = useRouter()

const nombre = ref('')
const apellido = ref('')
const nombreConsultorio = ref('')
const correo = ref('')
const contrasena = ref('')
const repetirContrasena = ref('')

const cargando = ref(false)
const mensaje = ref('')
const registroExitoso = ref(false)

async function registrar() {
  mensaje.value = ''
  registroExitoso.value = false

  if (contrasena.value !== repetirContrasena.value) {
    mensaje.value = 'Las contraseñas no coinciden.'
    return
  }

  if (contrasena.value.length < 6) {
    mensaje.value = 'La contraseña debe tener al menos 6 caracteres.'
    return
  }

  try {
    cargando.value = true

    const { requiereConfirmacion } = await registrarUsuario({
      correo: correo.value.trim(),
      contrasena: contrasena.value,
      nombre: nombre.value.trim(),
      apellido: apellido.value.trim(),
      nombreConsultorio: nombreConsultorio.value.trim(),
    })

    if (!requiereConfirmacion) {
      await cargarSesion(true)
      router.push('/agenda')
      return
    }

    registroExitoso.value = true
    mensaje.value =
      'Registro realizado. Revisá tu correo electrónico para confirmar la cuenta y después iniciá sesión.'
    contrasena.value = ''
    repetirContrasena.value = ''
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
        <small>14 días gratis del plan Profesional</small>
      </div>

      <h1>Registrá tu consultorio</h1>

      <form class="formulario" @submit.prevent="registrar">
        <div class="fila-campos">
          <label class="campo">
            <span>Nombre</span>
            <input v-model="nombre" type="text" autocomplete="given-name" required />
          </label>
          <label class="campo">
            <span>Apellido</span>
            <input v-model="apellido" type="text" autocomplete="family-name" required />
          </label>
        </div>

        <label class="campo">
          <span>Nombre del consultorio</span>
          <input v-model="nombreConsultorio" type="text" placeholder="Ej: Consultorio Dra. Fernández" required />
        </label>

        <label class="campo">
          <span>Correo electrónico</span>
          <input v-model="correo" type="email" placeholder="nombre@correo.com" autocomplete="email" required />
        </label>

        <div class="fila-campos">
          <label class="campo">
            <span>Contraseña</span>
            <input
              v-model="contrasena"
              type="password"
              placeholder="Mínimo 6 caracteres"
              autocomplete="new-password"
              required
            />
          </label>
          <label class="campo">
            <span>Repetir contraseña</span>
            <input v-model="repetirContrasena" type="password" autocomplete="new-password" required />
          </label>
        </div>

        <p v-if="mensaje" class="mensaje" :class="registroExitoso ? 'exito' : 'error'">
          {{ mensaje }}
        </p>

        <button type="submit" class="btn" :disabled="cargando">
          {{ cargando ? 'Registrando...' : 'Crear cuenta' }}
        </button>
      </form>

      <p class="pie-acceso">
        ¿Ya tenés cuenta?
        <RouterLink to="/login">Iniciá sesión</RouterLink>
      </p>
    </section>
  </main>
</template>
