<script setup>
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { sesion, cerrarSesion, tieneRol } from '@/services/auth'
import { ROLES, nombreCompleto } from '@/services/consultorio'

const router = useRouter()
const cerrandoSesion = ref(false)

const inicial = computed(() => sesion.perfil?.nombre?.[0]?.toUpperCase() ?? '?')

async function salir() {
  try {
    cerrandoSesion.value = true
    await cerrarSesion()
    router.push('/login')
  } catch (error) {
    alert(error.message)
  } finally {
    cerrandoSesion.value = false
  }
}
</script>

<template>
  <header class="barra">
    <div class="barra-superior">
      <RouterLink to="/agenda" class="marca">
        <img src="/favicon.svg" alt="" />
        <span>Odontoybrackets</span>
      </RouterLink>

      <div class="usuario">
        <div class="usuario-datos">
          <strong>{{ nombreCompleto(sesion.perfil) }}</strong>
          <small>{{ ROLES[sesion.perfil?.rol] }} · {{ sesion.consultorio?.nombre }}</small>
        </div>
        <span class="avatar" aria-hidden="true">{{ inicial }}</span>
      </div>
    </div>

    <nav class="barra-enlaces">
      <RouterLink to="/agenda">Agenda</RouterLink>
      <RouterLink to="/pacientes">Pacientes</RouterLink>
      <RouterLink v-if="tieneRol('admin')" to="/servicios">Servicios</RouterLink>
      <RouterLink to="/consultorio">Mi consultorio</RouterLink>
      <RouterLink to="/cambiar-contrasena">Cambiar contraseña</RouterLink>
      <button type="button" class="salir" :disabled="cerrandoSesion" @click="salir">
        {{ cerrandoSesion ? 'Cerrando...' : 'Cerrar sesión' }}
      </button>
    </nav>
  </header>
</template>

<style scoped>
.barra {
  background: linear-gradient(90deg, #35b6d9, var(--violeta));
  color: var(--blanco);
}

.barra-superior {
  max-width: 1180px;
  margin: 0 auto;
  padding: 12px 16px 6px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.marca {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--blanco);
  text-decoration: none;
  font-family: Georgia, 'Times New Roman', serif;
  font-style: italic;
  font-size: 22px;
}

.marca img {
  width: 34px;
  height: 34px;
  background: var(--blanco);
  border-radius: 8px;
  padding: 3px;
}

.usuario {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.usuario-datos {
  display: grid;
  text-align: right;
  font-size: 14px;
  min-width: 0;
}

.usuario-datos small {
  color: rgba(255, 255, 255, 0.85);
  font-size: 12px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.avatar {
  display: grid;
  place-items: center;
  flex-shrink: 0;
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.25);
  border: 2px solid var(--blanco);
  font-weight: 700;
}

.barra-enlaces {
  max-width: 1180px;
  margin: 0 auto;
  padding: 4px 16px 0;
  display: flex;
  gap: 4px;
  overflow-x: auto;
}

.barra-enlaces a,
.salir {
  padding: 9px 12px;
  color: var(--blanco);
  text-decoration: none;
  font: inherit;
  font-size: 14px;
  white-space: nowrap;
  border-radius: 8px 8px 0 0;
  background: none;
  border: none;
  cursor: pointer;
}

.barra-enlaces a:hover,
.salir:hover {
  background: rgba(255, 255, 255, 0.15);
}

.barra-enlaces a.router-link-active {
  background: var(--gris-claro);
  color: var(--violeta);
  font-weight: 600;
}

.salir { margin-left: auto; }

@media (max-width: 600px) {
  .usuario-datos { display: none; }
  .salir { margin-left: 0; }
}
</style>
