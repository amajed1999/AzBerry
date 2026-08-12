import * as React from 'react'
import { Plus, Pencil } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { PageHeader } from '@/components/Layout'
import { Button, Badge, Input, Select, Modal, Card } from '@/components/ui/primitives'
import { ImageUploadField } from '@/components/ImageUploadField'
import { formatMoney } from '@/lib/utils'
import type { Tables, TablesInsert } from '@/lib/database.types'

type Branch = Tables<'branches'>
type Country = Tables<'countries'>

const EMPTY: TablesInsert<'branches'> = {
  country_id: '',
  name_ar: '',
  name_en: '',
  image_url: null,
  lat: 33.3152,
  lng: 44.3661,
  phone: '',
  open_time: '10:00',
  close_time: '03:00',
  delivery_radius_km: 5,
  delivery_fee: 0,
  min_order: 0,
  is_active: true,
  is_busy: false,
}

export default function Branches() {
  const [rows, setRows] = React.useState<Branch[]>([])
  const [countries, setCountries] = React.useState<Country[]>([])
  const [open, setOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<Branch | null>(null)
  const [form, setForm] = React.useState<TablesInsert<'branches'>>(EMPTY)
  const [saving, setSaving] = React.useState(false)

  const load = React.useCallback(async () => {
    const [{ data: b }, { data: c }] = await Promise.all([
      supabase.from('branches').select('*').order('name_ar'),
      supabase.from('countries').select('*').order('name'),
    ])
    setRows(b ?? [])
    setCountries(c ?? [])
  }, [])
  React.useEffect(() => {
    load()
  }, [load])

  const countryName = (id: string) => countries.find((c) => c.id === id)?.name ?? '—'

  function openNew() {
    setEditing(null)
    setForm({ ...EMPTY, country_id: countries[0]?.id ?? '' })
    setOpen(true)
  }
  function openEdit(b: Branch) {
    setEditing(b)
    setForm({
      country_id: b.country_id,
      name_ar: b.name_ar,
      name_en: b.name_en,
      image_url: b.image_url,
      lat: b.lat,
      lng: b.lng,
      phone: b.phone,
      open_time: b.open_time,
      close_time: b.close_time,
      delivery_radius_km: b.delivery_radius_km,
      delivery_fee: b.delivery_fee,
      min_order: b.min_order,
      is_active: b.is_active,
      is_busy: b.is_busy,
    })
    setOpen(true)
  }

  async function save(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    if (editing) {
      await supabase.from('branches').update(form).eq('id', editing.id)
    } else {
      await supabase.from('branches').insert(form)
    }
    setSaving(false)
    setOpen(false)
    load()
  }

  async function toggle(b: Branch, field: 'is_active' | 'is_busy') {
    const patch =
      field === 'is_active' ? { is_active: !b.is_active } : { is_busy: !b.is_busy }
    await supabase.from('branches').update(patch).eq('id', b.id)
    load()
  }

  return (
    <>
      <PageHeader
        title="إدارة الفروع"
        subtitle={`${rows.length} فرع`}
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" /> فرع جديد
          </Button>
        }
      />
      <div className="p-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {rows.map((b) => (
            <Card key={b.id} className="overflow-hidden">
              <div className="h-28 bg-brand-50">
                {b.image_url ? (
                  <img src={b.image_url} alt={b.name_ar} className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full items-center justify-center text-3xl">🏪</div>
                )}
              </div>
              <div className="p-3">
                <div className="flex items-center justify-between">
                  <div className="font-bold text-slate-800">{b.name_ar}</div>
                  <span className="text-xs text-slate-400">{countryName(b.country_id)}</span>
                </div>
                <div className="mt-1 text-xs text-slate-500">
                  توصيل {formatMoney(b.delivery_fee)} • حد أدنى {formatMoney(b.min_order)}
                </div>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  <button onClick={() => toggle(b, 'is_active')}>
                    <Badge
                      className={
                        b.is_active
                          ? 'border-green-200 bg-green-50 text-green-700'
                          : 'border-slate-200 bg-slate-100 text-slate-500'
                      }
                    >
                      {b.is_active ? 'مفتوح' : 'مغلق'}
                    </Badge>
                  </button>
                  <button onClick={() => toggle(b, 'is_busy')}>
                    <Badge
                      className={
                        b.is_busy
                          ? 'border-amber-200 bg-amber-50 text-amber-700'
                          : 'border-slate-200 bg-slate-50 text-slate-500'
                      }
                    >
                      {b.is_busy ? 'مزدحم' : 'عادي'}
                    </Badge>
                  </button>
                  <Button variant="ghost" size="sm" onClick={() => openEdit(b)}>
                    <Pencil className="h-4 w-4" /> تعديل
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? 'تعديل فرع' : 'فرع جديد'}>
        <form onSubmit={save} className="space-y-4">
          <ImageUploadField
            bucket="branch-images"
            label="صورة الفرع"
            value={form.image_url}
            onChange={(url) => setForm({ ...form, image_url: url })}
          />
          <div className="grid grid-cols-2 gap-3">
            <Field label="الاسم (عربي)">
              <Input
                required
                value={form.name_ar}
                onChange={(e) => setForm({ ...form, name_ar: e.target.value })}
              />
            </Field>
            <Field label="الاسم (إنجليزي)">
              <Input
                required
                dir="ltr"
                value={form.name_en}
                onChange={(e) => setForm({ ...form, name_en: e.target.value })}
              />
            </Field>
          </div>
          <Field label="الدولة">
            <Select
              required
              value={form.country_id}
              onChange={(e) => setForm({ ...form, country_id: e.target.value })}
            >
              <option value="" disabled>
                اختر الدولة
              </option>
              {countries.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </Select>
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="خط العرض (lat)">
              <Input
                type="number"
                step="any"
                value={form.lat}
                onChange={(e) => setForm({ ...form, lat: Number(e.target.value) })}
              />
            </Field>
            <Field label="خط الطول (lng)">
              <Input
                type="number"
                step="any"
                value={form.lng}
                onChange={(e) => setForm({ ...form, lng: Number(e.target.value) })}
              />
            </Field>
          </div>
          <Field label="الهاتف">
            <Input
              dir="ltr"
              value={form.phone ?? ''}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
            />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="وقت الفتح">
              <Input
                type="time"
                value={form.open_time ?? '10:00'}
                onChange={(e) => setForm({ ...form, open_time: e.target.value })}
              />
            </Field>
            <Field label="وقت الإغلاق">
              <Input
                type="time"
                value={form.close_time ?? '03:00'}
                onChange={(e) => setForm({ ...form, close_time: e.target.value })}
              />
            </Field>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <Field label="رسوم التوصيل">
              <Input
                type="number"
                value={form.delivery_fee ?? 0}
                onChange={(e) => setForm({ ...form, delivery_fee: Number(e.target.value) })}
              />
            </Field>
            <Field label="الحد الأدنى">
              <Input
                type="number"
                value={form.min_order ?? 0}
                onChange={(e) => setForm({ ...form, min_order: Number(e.target.value) })}
              />
            </Field>
            <Field label="نطاق (كم)">
              <Input
                type="number"
                step="any"
                value={form.delivery_radius_km ?? 5}
                onChange={(e) => setForm({ ...form, delivery_radius_km: Number(e.target.value) })}
              />
            </Field>
          </div>
          <div className="flex gap-6">
            <label className="flex items-center gap-2 text-sm font-semibold text-slate-600">
              <input
                type="checkbox"
                className="h-4 w-4 accent-brand-600"
                checked={form.is_active ?? true}
                onChange={(e) => setForm({ ...form, is_active: e.target.checked })}
              />
              مفتوح
            </label>
            <label className="flex items-center gap-2 text-sm font-semibold text-slate-600">
              <input
                type="checkbox"
                className="h-4 w-4 accent-brand-600"
                checked={form.is_busy ?? false}
                onChange={(e) => setForm({ ...form, is_busy: e.target.checked })}
              />
              مزدحم
            </label>
          </div>
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

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="mb-1 block text-sm font-semibold text-slate-600">{label}</label>
      {children}
    </div>
  )
}
