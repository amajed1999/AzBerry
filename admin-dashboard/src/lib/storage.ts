import { supabase } from './supabase'

/**
 * Uploads an image to a public storage bucket and returns its public URL.
 * Writes are restricted by RLS to staff (is_staff()).
 */
export async function uploadImage(
  bucket: string,
  file: File,
  keyPrefix = ''
): Promise<string> {
  const ext = file.name.split('.').pop()?.toLowerCase() || 'jpg'
  const path = `${keyPrefix}${crypto.randomUUID()}.${ext}`

  const { error } = await supabase.storage.from(bucket).upload(path, file, {
    cacheControl: '3600',
    upsert: false,
    contentType: file.type || undefined,
  })
  if (error) throw error

  const { data } = supabase.storage.from(bucket).getPublicUrl(path)
  return data.publicUrl
}
