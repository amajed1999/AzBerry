import * as React from 'react'
import { Plus, Pencil, Trash2, Ticket } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { PageHeader } from '@/components/Layout'
import { Button, Badge, Input, Select, Modal, Card } from '@/components/ui/primitives'
import { formatMoney } from '@/lib/utils'
import type { Tables, TablesInsert } from '@/lib/database.types'

type Promo = Tables<'promo_codes'>

const EMPTY: TablesInsert<'promo_codes'> = {
  code: '',
  type: 'percentage',
  value: 0,
  min_order: 0,
  max_discount: null,
  usage_limit: null,
  valid_from: null,
  valid_to: null,
  is_active: true,
}

const TYPE_LABEL: Record<string, string> = {
  percentage: 'نسبة %',
  fixed: 'مبلغ ثابت',
  free_delivery: 'توصيل مجاني',
}

function toDateInput(iso: string | null): string {
  if (!iso) return ''
  return iso.slice(0, 10)
}

export default function PromoCodes() {
  const [rows, setRows] = React.useState<Promo[]>([])
  const [open, setOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<Promo | null>(null)
  const [form, setForm] = React.useState<TablesInsert<'promo_codes'>>(EMPTY)
  const [saving, setSaving] = React.useState(false)

  const load = React.useCallback(async () => {
    const { data } = await supabase
      .from('promo_codes')
      .select('*')
      .order('created_at', { ascending: false })
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
  function openEdit(p: Promo) {
    setEditing(p)
    setForm({
      code: p.code,
      type: p.type,
      value: p.value,
      min_order: p.min_order,
      max_discount: p.max_discount,
      usage_limit: p.usage_limit,
      valid_from: p.valid_from,
      valid_to: p.valid_to,
      is_active: p.is_active,
    })
    setOpen(true)
  }

  async function save(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    const payload = { ...form, code: (form.code ?? '').trim().toUpperCase() }
    if (editing) {
      await supabase.from('promo_codes').update(payload).eq('id', editing.id)
    } else {
      await supabase.from('promo_codes').insert(payload)
    }
    setSaving(false)
    setOpen(false)
    load()
  }

  async function remove(p: Promo) {
    if (!confirm(`حذف الكود ${p.code}؟`)) return
    await supabase.from('promo_codes').delete().eq('id', p.id)
    load()
  }

  return (
    <>
      <PageHeader
        title="أكواد الخصم"
        subtitle={`${rows.length} كود`}
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" /> كود جديد
          </Button>
        }
      />
      <div className="p-6">
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="bg-slate-50 text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">الكود</th>
                  <th className="px-4 py-3 font-semibold">النوع</th>
                  <th className="px-4 py-3 font-semibold">القيمة</th>
                  <th className="px-4 py-3 font-semibold">حد أدنى</th>
                  <th className="px-4 py-3 font-semibold">الاستخدام</th>
                  <th className="px-4 py-3 font-semibold">الصلاحية</th>
                  <th className="px-4 py-3 font-semibold">الحالة</th>
                  <th className="px-4 py-3 font-semibold">إجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {rows.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/60">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2 font-mono font-bold text-slate-800">
                        <Ticket className="h-4 w-4 text-brand-600" />
                        {p.code}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-slate-600">{TYPE_LABEL[p.type]}</td>
                    <td className="px-4 py-3 font-semibold text-brand-700">
                      {p.type === 'percentage'
                        ? `${p.value}%`
                        : p.type === 'free_delivery'
                          ? '—'
                          : formatMoney(p.value)}
                    </td>
                    <td className="px-4 py-3 text-slate-500">{formatMoney(p.min_order)}</td>
                    <td className="px-4 py-3 text-slate-500">
                      {p.used_count}
                      {p.usage_limit != null ? ` / ${p.usage_limit}` : ''}
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-400">
                      {p.valid_to ? `حتى ${toDateInput(p.valid_to)}` : 'مفتوح'}
                    </td>
                    <td className="px-4 py-3">
                      <Badge
                        className={
                          p.is_active
                            ? 'border-green-200 bg-green-50 text-green-700'
                            : 'border-slate-200 bg-slate-100 text-slate-500'
                        }
                      >
                        {p.is_active ? 'مفعّل' : 'موقوف'}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex gap-1">
                        <Button variant="ghost" size="sm" onClick={() => openEdit(p)}>
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => remove(p)}>
                          <Trash2 className="h-4 w-4 text-red-600" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
                {rows.length === 0 && (
                  <tr>
                    <td colSpan={8} className="py-10 text-center text-slate-300">
                      لا توجد أكواد
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? 'تعديل كود' : 'كود جديد'}>
        <form onSubmit={save} className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <Field label="الكود">
              <Input
                required
                dir="ltr"
                className="font-mono uppercase"
                value={form.code}
                onChange={(e) => setForm({ ...form, code: e.target.value })}
              />
            </Field>
            <Field label="النوع">
              <Select
                value={form.type}
                onChange={(e) => setForm({ ...form, type: e.target.value as Promo['type'] })}
              >
                <option value="percentage">نسبة %</option>
                <option value="fixed">مبلغ ثابت</option>
                <option value="free_delivery">توصيل مجاني</option>
              </Select>
            </Field>
          </div>

          {form.type !== 'free_delivery' && (
            <div className="grid grid-cols-2 gap-3">
              <Field label={form.type === 'percentage' ? 'النسبة %' : 'المبلغ'}>
                <Input
                  type="number"
                  min={0}
                  value={form.value ?? 0}
                  onChange={(e) => setForm({ ...form, value: Number(e.target.value) })}
                />
              </Field>
              {form.type === 'percentage' && (
                <Field label="أقصى خصم (اختياري)">
                  <Input
                    type="number"
                    min={0}
                    value={form.max_discount ?? ''}
                    onChange={(e) =>
                      setForm({
                        ...form,
                        max_discount: e.target.value ? Number(e.target.value) : null,
                      })
                    }
                  />
                </Field>
              )}
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <Field label="الحد الأدنى للطلب">
              <Input
                type="number"
                min={0}
                value={form.min_order ?? 0}
                onChange={(e) => setForm({ ...form, min_order: Number(e.target.value) })}
              />
            </Field>
            <Field label="حد الاستخدام (اختياري)">
              <Input
                type="number"
                min={0}
                value={form.usage_limit ?? ''}
                onChange={(e) =>
                  setForm({
                    ...form,
                    usage_limit: e.target.value ? Number(e.target.value) : null,
                  })
                }
              />
            </Field>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Field label="يبدأ من (اختياري)">
              <Input
                type="date"
                value={toDateInput(form.valid_from ?? null)}
                onChange={(e) =>
                  setForm({ ...form, valid_from: e.target.value ? e.target.value : null })
                }
              />
            </Field>
            <Field label="ينتهي في (اختياري)">
              <Input
                type="date"
                value={toDateInput(form.valid_to ?? null)}
                onChange={(e) =>
                  setForm({ ...form, valid_to: e.target.value ? e.target.value : null })
                }
              />
            </Field>
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

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="mb-1 block text-sm font-semibold text-slate-600">{label}</label>
      {children}
    </div>
  )
}
