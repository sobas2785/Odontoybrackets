import { createRouter, createWebHistory } from 'vue-router'
import { cargarSesion, cerrarSesion } from '@/services/auth'

import LoginView from '@/views/LoginView.vue'
import RegistroView from '@/views/RegistroView.vue'
import CambiarContrasenaView from '@/views/CambiarContrasenaView.vue'
import AgendaView from '@/views/AgendaView.vue'
import TurnoView from '@/views/TurnoView.vue'
import TurnoFormView from '@/views/TurnoFormView.vue'
import PacientesView from '@/views/PacientesView.vue'
import PacienteView from '@/views/PacienteView.vue'
import ServiciosView from '@/views/ServiciosView.vue'
import ConsultorioView from '@/views/ConsultorioView.vue'

const privada = { requiereAutenticacion: true }

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),

  routes: [
    { path: '/', redirect: '/agenda' },

    // Públicas (si ya hay sesión, mandan a la agenda)
    { path: '/login', name: 'login', component: LoginView, meta: { soloInvitados: true } },
    { path: '/registro', name: 'registro', component: RegistroView, meta: { soloInvitados: true } },

    // Privadas
    { path: '/agenda', name: 'agenda', component: AgendaView, meta: privada },
    { path: '/turnos/nuevo', name: 'nuevo-turno', component: TurnoFormView, meta: privada },
    { path: '/turnos/:id', name: 'turno', component: TurnoView, meta: privada },
    { path: '/turnos/:id/editar', name: 'editar-turno', component: TurnoFormView, meta: privada },
    { path: '/pacientes', name: 'pacientes', component: PacientesView, meta: privada },
    { path: '/pacientes/:id', name: 'paciente', component: PacienteView, meta: privada },
    { path: '/consultorio', name: 'consultorio', component: ConsultorioView, meta: privada },
    {
      path: '/cambiar-contrasena',
      name: 'cambiar-contrasena',
      component: CambiarContrasenaView,
      meta: privada,
    },
    {
      path: '/servicios',
      name: 'servicios',
      component: ServiciosView,
      meta: { requiereAutenticacion: true, roles: ['admin'] },
    },

    { path: '/:pathMatch(.*)*', redirect: '/agenda' },
  ],
})

// Antes de cada navegación se revisa la sesión y el rol del usuario.
router.beforeEach(async (destino) => {
  const { usuario, perfil } = await cargarSesion()

  if (destino.meta.requiereAutenticacion && !usuario) {
    return '/login'
  }

  // Usuario sin perfil o dado de baja: no puede usar el sistema
  if (usuario && (!perfil || !perfil.activo)) {
    await cerrarSesion()
    return { path: '/login', query: { motivo: 'sin-acceso' } }
  }

  if (usuario && destino.meta.soloInvitados) {
    return '/agenda'
  }

  if (destino.meta.roles && !destino.meta.roles.includes(perfil.rol)) {
    return '/agenda'
  }
})

export default router
