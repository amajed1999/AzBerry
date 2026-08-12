import * as React from 'react'
import { Plus, Pencil, Trash2 } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { PageHeader } from '@/components/Layout'
import { Button, Badge, Input, Select, Modal, Card } from '@/components/ui/primitives'
import { ImageUploadField } from '@/components/ImageUploadField'
import type { Tables, TablesInsert } from '@/lib/database.types'

type Banner = Tables<'banners'>
type Country = Tables<'countries'>

const EMPTY: TablesInsert<'banners'> = {
  image_url: '',
  action_type: 'none',
  action_value: null,
  country_id: null,
  sort_order: 0,
  is_active: true,
}

const ACTION_LABEL: Record<string, string> = {
  none: 'بدون',
  product: 'منتج',
  category: 'صنف',
  url: 'رابط',
}

export default function Banners() {
  const [rows, setRows] = React.useState<Banner[]>([])
  const [countries, setCountries] = React.useState<Country[]>([])
  const [open, setOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<Banner | null>(null)
  const [form, setForm] = React.useState<TablesInsert<'banners'>>(EMPTY)
  const [saving, setSaving] = React.useState(false)

  const load = React.useCallback(async () => {
    const [{ data: b }, { data: c }] = await Promise.all([
      supabase.from('banners').select('*').order('sort_order'),
      supabase.from('countries').select('*').order('name'),
    ])
    setRows(b ?? [])
    setCountries(c ?? [])
  }, [])
  React.useEffect(() => {
    load()
  }, [load])

  const countryName = (id: string | null) =>
    id ? countries.find((c) => c.id === id)?.name ?? '—' : 'كل الدول'

  function openNew() {
    setEditing(null)
    setForm(EMPTY)
    setOpen(true)
  }
  function openEdit(b: Banner) {
    setEditing(b)
    setForm({
      image_url: b.image_url,
      action_type: b.action_type,
      action_value: b.action_value,
      country_id: b.country_id,
      sort_order: b.sort_order,
      is_active: b.is_active,
    })
    setOpen(true)
  }

  async function save(e: React.FormEvent) {
    e.preventDefault()
    if (!form.image_url) return
    setSaving(true)
    if (editing) {
      await supabase.from('banners').update(form).eq('id', editing.id)
    } else {
      await supabase.from('banners').insert(form)
    }
    setSaving(false)
    setOpen(false)
    load()
  }

  async function remove(b: Banner) {
    if (!confirm('حذف هذا البانر؟')) return
    await supabase.from('banners').delete().eq('id', b.id)
    load()
  }

  return (
    <>
      <PageHeader
        title="البانرات"
        subtitle={`${rows.length} بانر`}
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" /> بانر جديد
          </Button>
        }
      />
      <div className="p-6">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {rows.map((b) => (
            <Card key={b.id} className="overflow-hidden">
              <div className="aspect-[8/3] bg-slate-100">
                {b.image_url && (
                  <img src={b.image_url} alt="" className="h-full w-full object-cover" />
                )}
              </div>
              <div className="flex items-center justify-between p-3">
                <div className="flex items-center gap-2">
                  <Badge className="border-slate-200 bg-slate-50 text-slate-600">
                    {ACTION_LABEL[b.action_type]}
                  </Badge>
                  <span className="text-xs text-slate-400">{countryName(b.country_id)}</span>
                  <Badge
                    className={
                      b.is_active
                        ? 'border-green-200 bg-green-50 text-green-700'
                        : 'border-slate-200 bg-slate-100 text-slate-500'
                    }
                  >
                    {b.is_active ? 'مفعّل' : 'موقوف'}
                  </Badge>
                </div>
                <div className="flex gap-1">
                  <Button variant="ghost" size="sm" onClick={() => openEdit(b)}>
                    <Pencil className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="sm" onClick={() => remove(b)}>
                    <Trash2 className="h-4 w-4 text-red-600" />
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? 'تعديل بانر' : 'بانر جديد'}>
        <form onSubmit={save} className="space-y-4">
          <ImageUploadField
            bucket="banner-images"
            label="صورة البانر (إلزامية)"
            aspect="wide"
            value={form.image_url}
            onChange={(url) => setForm({ ...form, image_url: url ?? '' })}
          />
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">نوع الإجراء</label>
              <Select
                value={form.action_type ?? 'none'}
                onChange={(e) => setForm({ ...form, action_type: e.target.value as Banner['action_type'] })}
              >
                <option value="none">بدون</option>
                <option value="product">فتح منتج</option>
                <option value="category">فتح صنف</option>
                <option value="url">فتح رابط</option>
              </Select>
            </div>
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">الدولة</label>
              <Select
                value={form.country_id ?? ''}
                onChange={(e) => setForm({ ...form, country_id: e.target.value || null })}
              >
                <option value="">كل الدول</option>
                {countries.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </Select>
            </div>
          </div>
          {form.action_type !== 'none' && (
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">
                قيمة الإجراء ({ACTION_LABEL[form.action_type ?? 'none']})
              </label>
              <Input
                dir="ltr"
                placeholder={form.action_type === 'url' ? 'https://…' : 'المعرّف (id)'}
                value={form.action_value ?? ''}
                onChange={(e) => setForm({ ...form, action_value: e.target.value || null })}
              />
            </div>
          )}
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
            <Button type="submit" disabled={saving || !form.image_url}>
              {saving ? 'جارِ الحفظ…' : 'حفظ'}
            </Button>
          </div>
        </form>
      </Modal>
    </>
  )
}
