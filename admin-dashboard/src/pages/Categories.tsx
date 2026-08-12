import * as React from 'react'
import { Plus, Pencil } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { PageHeader } from '@/components/Layout'
import { Button, Badge, Input, Modal, Card } from '@/components/ui/primitives'
import { ImageUploadField } from '@/components/ImageUploadField'
import type { Tables, TablesInsert } from '@/lib/database.types'

type Category = Tables<'categories'>

const EMPTY: TablesInsert<'categories'> = {
  name_ar: '',
  name_en: '',
  image_url: null,
  sort_order: 0,
  is_active: true,
}

export default function Categories() {
  const [rows, setRows] = React.useState<Category[]>([])
  const [open, setOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<Category | null>(null)
  const [form, setForm] = React.useState<TablesInsert<'categories'>>(EMPTY)
  const [saving, setSaving] = React.useState(false)

  const load = React.useCallback(async () => {
    const { data } = await supabase.from('categories').select('*').order('sort_order')
    setRows(data ?? [])
  }, [])
  React.useEffect(() => {
    load()
  }, [load])

  function openNew() {
    setEditing(null)
    setForm(EMPTY)
    setOpen(true)
  }
  function openEdit(c: Category) {
    setEditing(c)
    setForm({
      name_ar: c.name_ar,
      name_en: c.name_en,
      image_url: c.image_url,
      sort_order: c.sort_order,
      is_active: c.is_active,
    })
    setOpen(true)
  }

  async function save(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    if (editing) {
      await supabase.from('categories').update(form).eq('id', editing.id)
    } else {
      await supabase.from('categories').insert(form)
    }
    setSaving(false)
    setOpen(false)
    load()
  }

  return (
    <>
      <PageHeader
        title="إدارة الأصناف"
        subtitle={`${rows.length} صنف`}
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" /> صنف جديد
          </Button>
        }
      />
      <div className="p-6">
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {rows.map((c) => (
            <Card key={c.id} className="overflow-hidden">
              <div className="h-28 bg-brand-50">
                {c.image_url ? (
                  <img src={c.image_url} alt={c.name_ar} className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full items-center justify-center text-3xl">🍹</div>
                )}
              </div>
              <div className="p-3">
                <div className="flex items-center justify-between">
                  <div className="font-bold text-slate-800">{c.name_ar}</div>
                  <Badge
                    className={
                      c.is_active
                        ? 'border-green-200 bg-green-50 text-green-700'
                        : 'border-slate-200 bg-slate-100 text-slate-500'
                    }
                  >
                    {c.is_active ? 'مفعّل' : 'موقوف'}
                  </Badge>
                </div>
                <div className="text-xs text-slate-400" dir="ltr">
                  {c.name_en}
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  className="mt-3 w-full"
                  onClick={() => openEdit(c)}
                >
                  <Pencil className="h-4 w-4" /> تعديل
                </Button>
              </div>
            </Card>
          ))}
        </div>
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? 'تعديل صنف' : 'صنف جديد'}>
        <form onSubmit={save} className="space-y-4">
          <ImageUploadField
            bucket="category-images"
            label="صورة الصنف"
            value={form.image_url}
            onChange={(url) => setForm({ ...form, image_url: url })}
          />
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">الاسم (عربي)</label>
              <Input
                required
                value={form.name_ar}
                onChange={(e) => setForm({ ...form, name_ar: e.target.value })}
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">الاسم (إنجليزي)</label>
              <Input
                required
                dir="ltr"
                value={form.name_en}
                onChange={(e) => setForm({ ...form, name_en: e.target.value })}
              />
            </div>
          </div>
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-600">الترتيب</label>
            <Input
              type="number"
              value={form.sort_order ?? 0}
              onChange={(e) => setForm({ ...form, sort_order: Number(e.target.value) })}
            />
          </div>
          <label className="flex items-center gap-2 text-sm font-semibold text-slate-600">
            <input
              type="checkbox"
              className="h-4 w-4 accent-brand-600"
              checked={form.is_active ?? true}
              onChange={(e) => setForm({ ...form, is_active: e.target.checked })}
            />
            مفعّل
          </label>
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="outline" onClick={() => setOpen(false)}>
              إلغاء
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? 'جارِ الحفظ…' : 'حفظ'}
            </Button>
          </div>
        </form>
      </Modal>
    </>
  )
}
