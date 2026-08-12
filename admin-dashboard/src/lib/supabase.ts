import { createClient } from '@supabase/supabase-js'
import type { Database } from './database.types'

// Falls back to the project's public (publishable) key so production builds work
// even if env vars aren't set. The publishable key is safe to ship — RLS protects
// data. Override via VITE_SUPABASE_* env vars when needed.
const url =
  (import.meta.env.VITE_SUPABASE_URL as string) ||
  'https://wpqkvpyvoocoerxjllhu.supabase.co'
const key =
  (import.meta.env.VITE_SUPABASE_ANON_KEY as string) ||
  'sb_publishable_Y2jsTv7NCkmQuYTK_iN-WQ_6VSV7xgy'

export const supabase = createClient<Database>(url, key, {
  auth: { persistSession: true, autoRefreshToken: true },
})
