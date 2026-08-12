import * as React from 'react'
import { Plus, Pencil, Star, Circle } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { PageHeader } from '@/components/Layout'
import { Button, Badge, Input, Select, Modal, Card } from '@/components/ui/primitives'
import type { Tables } from '@/lib/database.types'

type DriverRow = Tables<'drivers'> & {
  users: { name: string | null; phone: string | null } | null
  branches: { name_ar: string } | null
}
type Branch = Pick<Tables<'branches'>, 'id' | 'name_ar'>

export default function Drivers() {
  const [rows, setRows] = React.useState<DriverRow[]>([])
  const [branches, setBranches] = React.useState<Branch[]>([])
  const [open, setOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<DriverRow | null>(null)

  // form
  const [phone, setPhone] = React.useState('')
  const [branchId, setBranchId] = React.useState('')
  const [vehicle, setVehicle] = React.useState('')
  const [plate, setPlate] = React.useState('')
  const [active, setActive] = React.useState(true)
  const [error, setError] = React.useState<string | null>(null)
  const [saving, setSaving] = React.useState(false)

  const load = React.useCallback(async () => {
    const [{ data: d }, { data: b }] = await Promise.all([
      supabase
        .from('drivers')
        .select('*, users(name, phone), branches(name_ar)')
        .order('created_at', { ascending: false }),
      supabase.from('branches').select('id, name_ar').order('name_ar'),
    ])
    setRows((d as unknown as DriverRow[]) ?? [])
    setBranches(b ?? [])
  }, [])
  React.useEffect(() => {
    load()
  }, [load])

  function openNew() {
    setEditing(null)
    setPhone('')
    setBranchId(branches[0]?.id ?? '')
    setVehicle('')
    setPlate('')
    setActive(true)
    setError(null)
    setOpen(true)
  }
  function openEdit(d: DriverRow) {
    setEditing(d)
    setPhone(d.users?.phone ?? '')
    setBranchId(d.branch_id ?? '')
    setVehicle(d.vehicle_type ?? '')
    setPlate(d.plate_number ?? '')
    setActive(d.is_active)
    setError(null)
    setOpen(true)
  }

  async function save(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setSaving(true)
    try {
      if (editing) {
        await supabase
          .from('drivers')
          .update({
            branch_id: branchId || null,
            vehicle_type: vehicle || null,
            plate_number: plate || null,
            is_active: active,
          })
          .eq('id', editing.id)
      } else {
        // Look up an existing user account by phone (the person must have signed
        // up through the app first — we cannot create auth users from here).
        const digits = phone.replace(/\D/g, '')
        if (!digits) throw new Error('أدخل رقم هاتف صحيح')
        const { data: found } = await supabase
          .from('users')
          .select('id, role')
          .ilike('phone', `%${digits}%`)
          .limit(1)
        const user = (found ?? [])[0]
        if (!user) {
          throw new Error('لا يوجد مستخدم بهذا الرقم — يجب أن يسجّل عبر التطبيق أولاً')
        }
        // Promote to driver role + create the drivers row.
        await supabase.from('users').update({ role: 'driver' }).eq('id', user.id)
        const { error: insErr } = await supabase.from('drivers').insert({
          user_id: user.id,
          branch_id: branchId || null,
          vehicle_type: vehicle || null,
          plate_number: plate || null,
          is_active: active,
        })
        if (insErr) throw insErr
      }
      setOpen(false)
      load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'خطأ')
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <PageHeader
        title="إدارة السائقين"
        subtitle={`${rows.length} سائق`}
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" /> إضافة سائق
          </Button>
        }
      />
      <div className="p-6">
        {rows.length === 0 ? (
          <Card>
            <div className="p-10 text-center text-slate-400">
              لا يوجد سائقون بعد. اضغط «إضافة سائق» بعد أن يسجّل الشخص في التطبيق برقم هاتفه.
            </div>
          </Card>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {rows.map((d) => (
              <Card key={d.id} className="p-4">
                <div className="flex items-center justify-between">
                  <div className="font-bold text-slate-800">{d.users?.name || 'سائق'}</div>
                  <div className="flex items-center gap-1 text-amber-500">
                    <Star className="h-4 w-4 fill-amber-400" />
                    <span className="text-sm font-semibold">{Number(d.rating).toFixed(1)}</span>
                  </div>
                </div>
                <div className="text-xs text-slate-400" dir="ltr">
                  {d.users?.phone || '—'}
                </div>
                <div className="mt-2 text-sm text-slate-600">
                  {d.branches?.name_ar || 'بلا فرع'}
                  {d.vehicle_type ? ` • ${d.vehicle_type}` : ''}
                  {d.plate_number ? ` • ${d.plate_number}` : ''}
                </div>
                <div className="mt-3 flex items-center gap-2">
                  <Badge
                    className={
                      d.is_online
                        ? 'border-green-200 bg-green-50 text-green-700'
                        : 'border-slate-200 bg-slate-100 text-slate-500'
                    }
                  >
                    <Circle
                      className={`ml-1 h-2 w-2 ${d.is_online ? 'fill-green-500' : 'fill-slate-400'}`}
                    />
                    {d.is_online ? 'متصل' : 'غير متصل'}
                  </Badge>
                  <Badge
                    className={
                      d.is_active
                        ? 'border-blue-200 bg-blue-50 text-blue-700'
                        : 'border-red-200 bg-red-50 text-red-700'
                    }
                  >
                    {d.is_active ? 'مفعّل' : 'موقوف'}
                  </Badge>
                  <Button variant="ghost" size="sm" className="mr-auto" onClick={() => openEdit(d)}>
                    <Pencil className="h-4 w-4" /> تعديل
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title={editing ? 'تعديل سائق' : 'إضافة سائق'}>
        <form onSubmit={save} className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-600">رقم هاتف السائق</label>
            <Input
              dir="ltr"
              required={!editing}
              disabled={!!editing}
              placeholder="7XX XXX XXXX"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
            />
            {!editing && (
              <p className="mt-1 text-xs text-slate-400">
                يجب أن يكون الشخص قد سجّل في التطبيق بهذا الرقم.
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-600">الفرع</label>
            <Select value={branchId} onChange={(e) => setBranchId(e.target.value)}>
              <option value="">بلا فرع</option>
              {branches.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name_ar}
                </option>
              ))}
            </Select>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">نوع المركبة</label>
              <Input
                placeholder="دراجة نارية…"
                value={vehicle}
                onChange={(e) => setVehicle(e.target.value)}
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-semibold text-slate-600">رقم اللوحة</label>
              <Input dir="ltr" value={plate} onChange={(e) => setPlate(e.target.value)} />
            </div>
          </div>
          <label className="flex items-center gap-2 text-sm font-semibold text-slate-600">
            <input
              type="checkbox"
              className="h-4 w-4 accent-brand-600"
              checked={active}
              onChange={(e) => setActive(e.target.checked)}
            />
            مفعّل
          </label>
          {error && <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{error}</div>}
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
