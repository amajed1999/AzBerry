import * as React from 'react'
import { Plus, Pencil, Trash2, AlertTriangle, Package2 } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { PageHeader } from '@/components/Layout'
import { Button, Badge, Input, Select, Modal, Card } from '@/components/ui/primitives'
import type { Tables, TablesInsert } from '@/lib/database.types'

type Item = Tables<'inventory_items'>
type Branch = Pick<Tables<'branches'>, 'id' | 'name_ar'>

const EMPTY: TablesInsert<'inventory_items'> = {
  branch_id: '',
  name: '',
  unit: 'كغم',
  quantity: 0,
  min_threshold: 0,
}

export default function Inventory() {
  const [rows, setRows] = React.useState<Item[]>([])
  const [branches, setBranches] = React.useState<Branch[]>([])
  const [branchFilter, setBranchFilter] = React.useState('')
  const [open, setOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<Item | null>(null)
  const [form, setForm] = React.useState<TablesInsert<'inventory_items'>>(EMPTY)
  const [saving, setSaving] = React.useState(false)

  const load = React.useCallback(async () => {
    const [{ data: i }, { data: b }] = await Promise.all([
      supabase.from('inventory_items').select('*').order('name'),
      supabase.from('branches').select('id, name_ar').order('name_ar'),
    ])
    setRows(i ?? [])
    setBranches(b ?? [])
  }, [])
  React.useEffect(() => {
    load()
  }, [load])

  const branchName = (id: string) => branches.find((b) => b.id === id)?.name_ar ?? '—'

  function openNew() {
    setEditing(null)
    setForm({ ...EMPTY, branch_id: branchFilter || branches[0]?.id || '' })
    setOpen(true)
  }
  function openEdit(it: Item) {
    setEditing(it)
    setForm({
      branch_id: it.branch_id,
      name: it.name,
      unit: it.unit,
      quantity: it.quantity,
      min_threshold: it.min_threshold,
    })
    setOpen(true)
  }

  async function save(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    if (editing) {
      await supabase.from('inventory_items').update(form).eq('id', editing.id)
    } else {
      await supabase.from('inventory_items').insert(form)
    }
    setSaving(false)
    setOpen(false)
    load()
  }

  async function remove(it: Item) {
    if (!confirm(`حذف «${it.name}»؟`)) return
    await supabase.from('inventory_items').delete().eq('id', it.id)
    load()
  }

  async function adjust(it: Item, delta: number) {
    const q = Math.max(0, Number(it.quantity) + delta)
    await supabase.from('inventory_items').update({ quantity: q }).eq('id', it.id)
    load()
  }

  const filtered = branchFilter ? rows.filter((r) => r.branch_id === branchFilter) : rows
  const lowCount = filtered.filter((r) => Number(r.quantity) <= Number(r.min_threshold)).length

  return (
    <>
      <PageHeader
        title="المخزون"
        subtitle={`${filtered.length} مادة${lowCount ? ` • ${lowCount} تحت الحد` : ''}`}
        action={
          <div className="flex items-center gap-2">
            <Select
              value={branchFilter}
              onChange={(e) => setBranchFilter(e.target.value)}
              className="w-44"
            >
              <option value="">كل الفروع</option>
              {branches.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name_ar}
                </option>
              ))}
            </Select>
            <Button onClick={openNew}>
              <Plus className="h-4 w-4" /> مادة جديدة
            </Button>
          </div>
        }
      />
      <div className="p-6">
        {lowCount > 0 && (
          <div className="mb-4 flex items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            <AlertTriangle className="h-4 w-4" />
            {lowCount} مادة وصلت أو أقل من الحد الأدنى — يُنصح بإعادة التزويد.
          </div>
        )}
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="bg-slate-50 text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">المادة</th>
                  <th className="px-4 py-3 font-semibold">الفرع</th>
                  <th className="px-4 py-3 font-semibold">الكمية</th>
                  <th className="px-4 py-3 font-semibold">الحد الأدنى</th>
                  <th className="px-4 py-3 font-semibold">الحالة</th>
                  <th className="px-4 py-3 font-semibold">إجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filtered.map((it) => {
                  const low = Number(it.quantity) <= Number(it.min_threshold)
                  return (
                    <tr key={it.id} className="hover:bg-slate-50/60">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2 font-semibold text-slate-800">
                          <Package2 className="h-4 w-4 text-slate-400" />
                          {it.name}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-slate-600">{branchName(it.branch_id)}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => adjust(it, -1)}
                            className="rounded bg-slate-100 px-2 text-slate-600 hover:bg-slate-200"
                          >
                            −
                          </button>
                          <span className="min-w-[3rem] text-center font-semibold">
                            {it.quantity} {it.unit}
                          </span>
                          <button
                            onClick={() => adjust(it, 1)}
                            className="rounded bg-slate-100 px-2 text-slate-600 hover:bg-slate-200"
                          >
                            +
                          </button>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-slate-500">
                        {it.min_threshold} {it.unit}
                      </td>
                      <td className="px-4 py-3">
                        <Badge
                          className={
                            low
                              ? 'border-red-200 bg-red-50 text-red-700'
                              : 'border-green-200 bg-green-50 text-green-700'
                          }
                        >
                          {low ? 'منخفض' : 'متوفّر'}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex gap-1">
                          <Button variant="ghost" size="sm" onClick={() => openEdit(it)}>
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm" onClick={() => remove(it)}>
                            <Trash2 className="h-4 w-4 text-red-600" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={6} className="py-10 text-center text-slate-300">
                      لا توجد مواد
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? 'تعديل مادة' : 'مادة جديدة'}>
        <form onSubmit={save} className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-600">اسم المادة</label>
            <Input
              required
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-600">الفرع</label>
            <Select
              required
              value={form.branch_id}
              onChange={(e) => setForm({ ...form, branch_id: e.target.value })}
            >
              <option value="" disabled>
                اختر الفرع
              </option>
              {branches.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name_ar}
                </option>
              ))}
            </Select>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">الكمية</label>
              <Input
                type="number"
                step="any"
                value={form.quantity ?? 0}
                onChange={(e) => setForm({ ...form, quantity: Number(e.target.value) })}
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">الوحدة</label>
              <Input
                value={form.unit ?? ''}
                onChange={(e) => setForm({ ...form, unit: e.target.value })}
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">حد أدنى</label>
              <Input
                type="number"
                step="any"
                value={form.min_threshold ?? 0}
                onChange={(e) => setForm({ ...form, min_threshold: Number(e.target.value) })}
              />
            </div>
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
