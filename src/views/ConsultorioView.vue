<script setup>
import { computed, onMounted, ref } from 'vue'
import { sesion, tieneRol } from '@/services/auth'
import {
  PLANES,
  ROLES,
  actualizarConsultorio,
  actualizarMiPerfil,
  listarEquipo,
  nombreCompleto,
} from '@/services/consultorio'
import { NOMBRES_DIAS, desdeISO, formatearFecha, formatearHora, hoyISO } from '@/utils/fechas'

const esAdmin = computed(() => tieneRol('admin'))

// ---- Datos y horario del consultorio ----
const consultorio = ref(copiarConsultorio())
const guardandoConsultorio = ref(false)
const mensajeConsultorio = ref('')
const errorConsultorio = ref('')

function copiarConsultorio() {
  const c = sesion.consultorio
  return {
    nombre: c.nombre,
    telefono: c.telefono ?? '',
    direccion: c.direccion ?? '',
    email: c.email ?? '',
    hora_apertura: formatearHora(c.hora_apertura),
    hora_cierre: formatearHora(c.hora_cierre),
    duracion_turno_min: c.duracion_turno_min,
    dias_atencion: [...c.dias_atencion],
  }
}

const diasDePrueba = computed(() => {
  const hasta = sesion.consultorio.prueba_hasta
  if (!hasta) return null
  return Math.round((desdeISO(hasta) - desdeISO(hoyISO())) / 86400000)
})

async function guardarConsultorio() {
  mensajeConsultorio.value = ''
  errorConsultorio.value = ''
  if (!consultorio.value.dias_atencion.length) {
    errorConsultorio.value = 'Elegí al menos un día de atención.'
    return
  }
  if (consultorio.value.hora_apertura >= consultorio.value.hora_cierre) {
    errorConsultorio.value = 'La hora de apertura tiene que ser anterior a la de cierre.'
    return
  }
  try {
    guardandoConsultorio.value = true
    await actualizarConsultorio(consultorio.value)
    consultorio.value = copiarConsultorio()
    mensajeConsultorio.value = 'Datos del consultorio guardados.'
  } catch (error) {
    errorConsultorio.value = error.message
  } finally {
    guardandoConsultorio.value = false
  }
}

// ---- Mi perfil ----
const perfil = ref({
  nombre: sesion.perfil.nombre,
  apellido: sesion.perfil.apellido,
  matricula: sesion.perfil.matricula ?? '',
})
const guardandoPerfil = ref(false)
const mensajePerfil = ref('')
const errorPerfil = ref('')

async function guardarPerfil() {
  mensajePerfil.value = ''
  errorPerfil.value = ''
  try {
    guardandoPerfil.value = true
    await actualizarMiPerfil(perfil.value)
    mensajePerfil.value = 'Tus datos se guardaron.'
  } catch (error) {
    errorPerfil.value = error.message
  } finally {
    guardandoPerfil.value = false
  }
}

// ---- Equipo ----
const equipo = ref([])
const errorEquipo = ref('')

onMounted(async () => {
  try {
    equipo.value = await listarEquipo()
  } catch (error) {
    errorEquipo.value = error.message
  }
})
</script>

<template>
  <main class="contenedor">
    <p class="etiqueta-seccion">Configuración</p>
    <h1>Mi consultorio</h1>

    <div class="dos-columnas">
      <form class="tarjeta formulario" @submit.prevent="guardarConsultorio">
        <h2>Datos y horario de atención</h2>
        <p v-if="!esAdmin" class="mensaje aviso">Solo el administrador/a puede modificar estos datos.</p>

        <fieldset :disabled="!esAdmin" class="formulario sin-borde">
          <label class="campo">
            <span>Nombre</span>
            <input v-model="consultorio.nombre" type="text" required />
          </label>
          <div class="fila-campos">
            <label class="campo">
              <span>Teléfono</span>
              <input v-model="consultorio.telefono" type="tel" />
            </label>
            <label class="campo">
              <span>Email</span>
              <input v-model="consultorio.email" type="email" />
            </label>
          </div>
          <label class="campo">
            <span>Dirección</span>
            <input v-model="consultorio.direccion" type="text" />
          </label>

          <div class="fila-campos">
            <label class="campo">
              <span>Abre</span>
              <input v-model="consultorio.hora_apertura" type="time" required />
            </label>
            <label class="campo">
              <span>Cierra</span>
              <input v-model="consultorio.hora_cierre" type="time" required />
            </label>
          </div>

          <label class="campo">
            <span>Turnos cada</span>
            <select v-model.number="consultorio.duracion_turno_min">
              <option v-for="m in [10, 15, 20, 30, 45, 60]" :key="m" :value="m">{{ m }} minutos</option>
            </select>
          </label>

          <div class="campo">
            <span>Días de atención</span>
            <div class="opciones-dias">
              <label v-for="dia in 7" :key="dia" class="check">
                <input v-model="consultorio.dias_atencion" type="checkbox" :value="dia" />
                {{ NOMBRES_DIAS[dia] }}
              </label>
            </div>
          </div>
        </fieldset>

        <p v-if="errorConsultorio" class="mensaje error">{{ errorConsultorio }}</p>
        <p v-if="mensajeConsultorio" class="mensaje exito">{{ mensajeConsultorio }}</p>

        <div v-if="esAdmin" class="acciones">
          <button type="submit" class="btn" :disabled="guardandoConsultorio">
            {{ guardandoConsultorio ? 'Guardando...' : 'Guardar cambios' }}
          </button>
        </div>
      </form>

      <div>
        <section class="tarjeta">
          <h2>Plan</h2>
          <dl class="datos">
            <dt>Plan actual</dt>
            <dd>{{ PLANES[sesion.consultorio.plan] }}</dd>
            <template v-if="diasDePrueba !== null">
              <dt>Prueba gratis</dt>
              <dd>
                <template v-if="diasDePrueba >= 0">
                  Quedan {{ diasDePrueba }} día(s) (hasta el {{ formatearFecha(sesion.consultorio.prueba_hasta) }})
                </template>
                <template v-else>Finalizada el {{ formatearFecha(sesion.consultorio.prueba_hasta) }}</template>
              </dd>
            </template>
          </dl>
        </section>

        <form class="tarjeta formulario" @submit.prevent="guardarPerfil">
          <h2>Mis datos</h2>
          <dl class="datos">
            <dt>Correo</dt>
            <dd>{{ sesion.usuario.email }}</dd>
            <dt>Rol</dt>
            <dd>{{ ROLES[sesion.perfil.rol] }}</dd>
          </dl>
          <div class="fila-campos">
            <label class="campo">
              <span>Nombre</span>
              <input v-model="perfil.nombre" type="text" required />
            </label>
            <label class="campo">
              <span>Apellido</span>
              <input v-model="perfil.apellido" type="text" />
            </label>
          </div>
          <label class="campo">
            <span>Matrícula</span>
            <input v-model="perfil.matricula" type="text" placeholder="Ej: MP 12345" />
          </label>
          <p v-if="errorPerfil" class="mensaje error">{{ errorPerfil }}</p>
          <p v-if="mensajePerfil" class="mensaje exito">{{ mensajePerfil }}</p>
          <div class="acciones">
            <button type="submit" class="btn" :disabled="guardandoPerfil">
              {{ guardandoPerfil ? 'Guardando...' : 'Guardar mis datos' }}
            </button>
            <RouterLink class="btn secundario" to="/cambiar-contrasena">Cambiar contraseña</RouterLink>
          </div>
        </form>

        <section class="tarjeta">
          <h2>Equipo</h2>
          <p v-if="errorEquipo" class="mensaje error">{{ errorEquipo }}</p>
          <table v-else>
            <tbody>
              <tr v-for="persona in equipo" :key="persona.id" :class="{ inactivo: !persona.activo }">
                <td>
                  <strong>{{ nombreCompleto(persona) }}</strong>
                  <small>{{ persona.matricula || '' }}</small>
                </td>
                <td>{{ ROLES[persona.rol] }}</td>
              </tr>
            </tbody>
          </table>
        </section>
      </div>
    </div>
  </main>
</template>

<style scoped>
.sin-borde {
  border: none;
  margin: 0;
  padding: 0;
  min-width: 0;
}
</style>
