import * as React from 'react'
import { Upload, Loader2 } from 'lucide-react'
import { uploadImage } from '@/lib/storage'

/**
 * Reusable image upload field. Uploads to the given public bucket and calls
 * onChange with the resulting public URL. Writes are restricted to staff by RLS.
 */
export function ImageUploadField({
  bucket,
  value,
  onChange,
  label = 'الصورة',
  aspect = 'square',
}: {
  bucket: string
  value: string | null | undefined
  onChange: (url: string | null) => void
  label?: string
  aspect?: 'square' | 'wide'
}) {
  const [uploading, setUploading] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)

  async function onPick(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    setError(null)
    setUploading(true)
    try {
      const url = await uploadImage(bucket, file)
      onChange(url)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'تعذّر رفع الصورة')
    } finally {
      setUploading(false)
      e.target.value = ''
    }
  }

  const previewClass =
    aspect === 'wide' ? 'h-20 w-36 rounded-lg' : 'h-20 w-20 rounded-xl'

  return (
    <div>
      <label className="mb-1 block text-sm font-semibold text-slate-600">{label}</label>
      <div className="flex items-center gap-3">
        <div
          className={`${previewClass} shrink-0 overflow-hidden border border-slate-200 bg-brand-50`}
        >
          {value ? (
            <img src={value} alt="" className="h-full w-full object-cover" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-2xl">🖼️</div>
          )}
        </div>
        <div className="flex-1">
          <label className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50">
            {uploading ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Upload className="h-4 w-4" />
            )}
            {uploading ? 'جارِ الرفع…' : 'رفع صورة'}
            <input
              type="file"
              accept="image/*"
              className="hidden"
              disabled={uploading}
              onChange={onPick}
            />
          </label>
          {value && (
            <button
              type="button"
              onClick={() => onChange(null)}
              className="mr-2 text-sm text-red-600 hover:underline"
            >
              إزالة
            </button>
          )}
          {error && <div className="mt-1 text-xs text-red-600">{error}</div>}
        </div>
      </div>
    </div>
  )
}
