<script setup>
// ABM de servicios del consultorio (solo admin: lo controla el router y RLS)
import { onMounted, ref } from 'vue'
import EtiquetaEstado from '@/components/EtiquetaEstado.vue'
import {
  actualizarServicio,
  crearServicio,
  eliminarServicio,
  listarServicios,
} from '@/services/servicios'

const servicios = ref([])

const nombre = ref('')
const duracionMin = ref(30)
const precio = ref('')
const activo = ref(true)
const servicioEditandoId = ref(null)

const cargando = ref(false)
const guardando = ref(false)
const mensaje = ref('')
const errorMensaje = ref('')

const formatoPrecio = new Intl.NumberFormat('es-AR', { style: 'currency', currency: 'ARS' })

async function cargarServicios(limpiarMensaje = true) {
  cargando.value = true
  errorMensaje.value = ''
  if (limpiarMensaje) mensaje.value = ''
  try {
    servicios.value = await listarServicios()
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    cargando.value = false
  }
}

async function guardarServicio() {
  errorMensaje.value = ''
  mensaje.value = ''

  if (!nombre.value.trim()) {
    errorMensaje.value = 'El nombre es obligatorio.'
    return
  }
  if (Number(duracionMin.value) < 5) {
    errorMensaje.value = 'La duración mínima es de 5 minutos.'
    return
  }
  if (precio.value !== '' && Number(precio.value) < 0) {
    errorMensaje.value = 'El precio no puede ser negativo.'
    return
  }

  const datos = {
    nombre: nombre.value,
    duracion_min: duracionMin.value,
    precio: precio.value,
    activo: activo.value,
  }

  try {
    guardando.value = true
    if (servicioEditandoId.value) {
      await actualizarServicio(servicioEditandoId.value, datos)
      mensaje.value = 'Servicio actualizado correctamente.'
    } else {
      await crearServicio(datos)
      mensaje.value = 'Servicio creado correctamente.'
    }
    limpiarFormulario()
    await cargarServicios(false)
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    guardando.value = false
  }
}

function editarServicio(servicio) {
  servicioEditandoId.value = servicio.id
  nombre.value = servicio.nombre
  duracionMin.value = servicio.duracion_min
  precio.value = servicio.precio ?? ''
  activo.value = servicio.activo
  mensaje.value = ''
  errorMensaje.value = ''
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function eliminar(servicio) {
  if (!window.confirm(`¿Querés eliminar el servicio "${servicio.nombre}"?`)) return
  errorMensaje.value = ''
  mensaje.value = ''
  try {
    await eliminarServicio(servicio.id)
    mensaje.value = 'Servicio eliminado correctamente.'
    if (servicioEditandoId.value === servicio.id) limpiarFormulario()
    await cargarServicios(false)
  } catch (error) {
    errorMensaje.value =
      error.message.startsWith('No se puede eliminar')
        ? 'Este servicio ya se usó en turnos o tratamientos. Editalo y desmarcá "Activo" para que no se ofrezca más.'
        : error.message
  }
}

function limpiarFormulario() {
  nombre.value = ''
  duracionMin.value = 30
  precio.value = ''
  activo.value = true
  servicioEditandoId.value = null
}

function cancelarEdicion() {
  limpiarFormulario()
  mensaje.value = ''
  errorMensaje.value = ''
}

onMounted(cargarServicios)
</script>

<template>
  <main class="contenedor">
    <div class="columnas">
      <section class="tarjeta">
        <p class="etiqueta-seccion">Administración</p>
        <h2>{{ servicioEditandoId ? 'Editar servicio' : 'Nuevo servicio' }}</h2>

        <form class="formulario" @submit.prevent="guardarServicio">
          <label class="campo">
            <span>Nombre</span>
            <input v-model="nombre" type="text" maxlength="120" required />
          </label>

          <div class="fila-campos">
            <label class="campo">
              <span>Duración (minutos)</span>
              <input v-model="duracionMin" type="number" min="5" max="480" step="5" required />
            </label>
            <label class="campo">
              <span>Precio (opcional)</span>
              <input v-model="precio" type="number" min="0" step="0.01" />
            </label>
          </div>

          <label class="check">
            <input v-model="activo" type="checkbox" />
            Activo (se puede elegir al dar turnos)
          </label>

          <p v-if="errorMensaje" class="mensaje error">{{ errorMensaje }}</p>
          <p v-if="mensaje" class="mensaje exito">{{ mensaje }}</p>

          <div class="acciones">
            <button type="submit" class="btn" :disabled="guardando">
              {{ guardando ? 'Guardando...' : servicioEditandoId ? 'Actualizar servicio' : 'Crear servicio' }}
            </button>
            <button v-if="servicioEditandoId" type="button" class="btn secundario" @click="cancelarEdicion">
              Cancelar
            </button>
          </div>
        </form>
      </section>

      <section class="tarjeta">
        <div class="cabecera-pagina">
          <h2>Servicios del consultorio</h2>
          <button class="btn secundario chico" :disabled="cargando" @click="cargarServicios()">Actualizar</button>
        </div>

        <p v-if="cargando && !servicios.length" class="vacio">Cargando servicios...</p>
        <p v-else-if="!servicios.length" class="vacio">Todavía no hay servicios.</p>

        <div v-else class="tabla-contenedor">
          <table>
            <thead>
              <tr>
                <th>Servicio</th>
                <th>Duración</th>
                <th>Precio</th>
                <th>Estado</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="servicio in servicios" :key="servicio.id" :class="{ inactivo: !servicio.activo }">
                <td><strong>{{ servicio.nombre }}</strong></td>
                <td>{{ servicio.duracion_min }} min</td>
                <td>{{ servicio.precio === null ? '—' : formatoPrecio.format(servicio.precio) }}</td>
                <td><EtiquetaEstado :estado="servicio.activo ? 'activo' : 'inactivo'" /></td>
                <td>
                  <div class="acciones">
                    <button class="btn secundario chico" @click="editarServicio(servicio)">Editar</button>
                    <button class="btn peligro chico" @click="eliminar(servicio)">Eliminar</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
  </main>
</template>
