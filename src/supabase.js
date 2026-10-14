import { createClient } from '@supabase/supabase-js'

const urlSupabase = import.meta.env.VITE_SUPABASE_URL
const clavePublicableSupabase = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!urlSupabase || !clavePublicableSupabase) {
  throw new Error(
    'Faltan VITE_SUPABASE_URL o VITE_SUPABASE_PUBLISHABLE_KEY. Copiá .env.example como .env y completalo.',
  )
}

// Única conexión reutilizable. Solo la importan los archivos de src/services.
export const supabase = createClient(urlSupabase, clavePublicableSupabase)
