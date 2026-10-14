<script setup>
// ABM de pacientes: alta, modificación, baja lógica (y baja definitiva para el admin)
import { onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import EtiquetaEstado from '@/components/EtiquetaEstado.vue'
import FormularioPaciente from '@/components/FormularioPaciente.vue'
import { tieneRol } from '@/services/auth'
import {
  actualizarPaciente,
  cambiarEstadoPaciente,
  crearPaciente,
  eliminarPaciente,
  listarPacientes,
  obtenerPaciente,
  pacienteVacio,
} from '@/services/pacientes'

const route = useRoute()

const pacientes = ref([])
const datos = ref(pacienteVacio())
const pacienteEditandoId = ref(null)

const busqueda = ref('')
const incluirInactivos = ref(false)

const cargando = ref(false)
const guardando = ref(false)
const mensaje = ref('')
const errorMensaje = ref('')

const formulario = ref(null)

async function cargarPacientes() {
  cargando.value = true
  errorMensaje.value = ''
  try {
    pacientes.value = await listarPacientes({
      texto: busqueda.value,
      incluirInactivos: incluirInactivos.value,
    })
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    cargando.value = false
  }
}

let temporizador = null
watch(busqueda, () => {
  clearTimeout(temporizador)
  temporizador = setTimeout(cargarPacientes, 300)
})
watch(incluirInactivos, cargarPacientes)

async function guardarPaciente() {
  errorMensaje.value = ''
  mensaje.value = ''

  if (!datos.value.nombre.trim() || !datos.value.apellido.trim()) {
    errorMensaje.value = 'El nombre y el apellido son obligatorios.'
    return
  }

  try {
    guardando.value = true
    if (pacienteEditandoId.value) {
      await actualizarPaciente(pacienteEditandoId.value, datos.value)
      mensaje.value = 'Paciente actualizado correctamente.'
    } else {
      await crearPaciente(datos.value)
      mensaje.value = 'Paciente creado correctamente.'
    }
    limpiarFormulario()
    await cargarPacientes()
  } catch (error) {
    errorMensaje.value = error.message
  } finally {
    guardando.value = false
  }
}

function editarPaciente(paciente) {
  pacienteEditandoId.value = paciente.id
  datos.value = {
    nombre: paciente.nombre,
    apellido: paciente.apellido,
    dni: paciente.dni ?? '',
    fecha_nacimiento: paciente.fecha_nacimiento ?? '',
    telefono: paciente.telefono ?? '',
    email: paciente.email ?? '',
    obra_social: paciente.obra_social ?? '',
    observaciones: paciente.observaciones ?? '',
  }
  mensaje.value = ''
  errorMensaje.value = ''
  formulario.value?.scrollIntoView({ behavior: 'smooth' })
}

async function cambiarEstado(paciente) {
  const darDeBaja = paciente.activo
  const pregunta = darDeBaja
    ? `¿Dar de baja a ${paciente.nombre} ${paciente.apellido}? Se conserva su historial y se puede reactivar.`
    : `¿Reactivar a ${paciente.nombre} ${paciente.apellido}?`
  if (!window.confirm(pregunta)) return

  try {
    await cambiarEstadoPaciente(paciente.id, !darDeBaja)
    mensaje.value = darDeBaja ? 'Paciente dado de baja.' : 'Paciente reactivado.'
    await cargarPacientes()
  } catch (error) {
    errorMensaje.value = error.message
  }
}

async function eliminar(paciente) {
  if (!window.confirm(`¿Eliminar definitivamente a ${paciente.nombre} ${paciente.apellido}?`)) return
  try {
    await eliminarPaciente(paciente.id)
    mensaje.value = 'Paciente eliminado.'
    if (pacienteEditandoId.value === paciente.id) limpiarFormulario()
    await cargarPacientes()
  } catch (error) {
    errorMensaje.value = error.message
  }
}

function limpiarFormulario() {
  datos.value = pacienteVacio()
  pacienteEditandoId.value = null
}

function cancelarEdicion() {
  limpiarFormulario()
  mensaje.value = ''
  errorMensaje.value = ''
}

onMounted(async () => {
  await cargarPacientes()
  // Desde la ficha se llega con /pacientes?editar=<id>
  if (route.query.editar) {
    try {
      editarPaciente(await obtenerPaciente(route.query.editar))
    } catch (error) {
      errorMensaje.value = error.message
    }
  }
})
</script>

<template>
  <main class="contenedor">
    <div class="columnas">
      <section ref="formulario" class="tarjeta">
        <p class="etiqueta-seccion">Pacientes</p>
        <h2>{{ pacienteEditandoId ? 'Editar paciente' : 'Nuevo paciente' }}</h2>

        <form class="formulario" @submit.prevent="guardarPaciente">
          <FormularioPaciente v-model="datos" />

          <p v-if="errorMensaje" class="mensaje error">{{ errorMensaje }}</p>
          <p v-if="mensaje" class="mensaje exito">{{ mensaje }}</p>

          <div class="acciones">
            <button type="submit" class="btn" :disabled="guardando">
              {{ guardando ? 'Guardando...' : pacienteEditandoId ? 'Actualizar paciente' : 'Crear paciente' }}
            </button>
            <button v-if="pacienteEditandoId" type="button" class="btn secundario" @click="cancelarEdicion">
              Cancelar
            </button>
          </div>
        </form>
      </section>

      <section class="tarjeta">
        <div class="cabecera-pagina">
          <h2>Listado</h2>
          <label class="check">
            <input v-model="incluirInactivos" type="checkbox" />
            Mostrar dados de baja
          </label>
        </div>

        <input v-model="busqueda" type="search" placeholder="Buscar por nombre, apellido o DNI..." />

        <p v-if="cargando && !pacientes.length" class="vacio">Cargando pacientes...</p>
        <p v-else-if="!pacientes.length" class="vacio">
          {{ busqueda ? 'No hay pacientes que coincidan con la búsqueda.' : 'Todavía no cargaste pacientes.' }}
        </p>

        <div v-else class="tabla-contenedor">
          <table>
            <thead>
              <tr>
                <th>Paciente</th>
                <th>DNI</th>
                <th>Teléfono</th>
                <th>Estado</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="paciente in pacientes" :key="paciente.id" :class="{ inactivo: !paciente.activo }">
                <td>
                  <RouterLink :to="`/pacientes/${paciente.id}`">
                    <strong>{{ paciente.apellido }}, {{ paciente.nombre }}</strong>
                  </RouterLink>
                  <small>{{ paciente.obra_social || 'Sin obra social' }}</small>
                </td>
                <td>{{ paciente.dni || '—' }}</td>
                <td>{{ paciente.telefono || '—' }}</td>
                <td><EtiquetaEstado :estado="paciente.activo ? 'activo' : 'inactivo'" :texto="paciente.activo ? 'Activo' : 'De baja'" /></td>
                <td>
                  <div class="acciones">
                    <button class="btn secundario chico" @click="editarPaciente(paciente)">Editar</button>
                    <button class="btn secundario chico" @click="cambiarEstado(paciente)">
                      {{ paciente.activo ? 'Dar de baja' : 'Reactivar' }}
                    </button>
                    <button v-if="tieneRol('admin')" class="btn peligro chico" @click="eliminar(paciente)">
                      Eliminar
                    </button>
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
