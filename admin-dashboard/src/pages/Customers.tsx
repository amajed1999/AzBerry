import * as React from 'react'
import { Search, Ban, CheckCircle2, Gift } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { PageHeader } from '@/components/Layout'
import { Button, Badge, Input, Card } from '@/components/ui/primitives'
import { formatMoney } from '@/lib/utils'
import { useAuth } from '@/context/AuthContext'
import { isSuperAdmin } from '@/lib/access'
import type { Tables } from '@/lib/database.types'

type User = Tables<'users'>

export default function Customers() {
  const { profile } = useAuth()
  const canManage = isSuperAdmin(profile?.role)
  const [rows, setRows] = React.useState<User[]>([])
  const [search, setSearch] = React.useState('')
  const [busy, setBusy] = React.useState<string | null>(null)

  const load = React.useCallback(async () => {
    const { data } = await supabase
      .from('users')
      .select('*')
      .eq('role', 'customer')
      .order('created_at', { ascending: false })
    setRows(data ?? [])
  }, [])
  React.useEffect(() => {
    load()
  }, [load])

  async function toggleBlock(u: User) {
    setBusy(u.id)
    await supabase.from('users').update({ is_blocked: !u.is_blocked }).eq('id', u.id)
    setBusy(null)
    load()
  }

  async function addPoints(u: User) {
    const input = prompt(`إضافة نقاط تعويضية لـ ${u.name || u.phone || 'الزبون'} (رصيده ${u.points_balance}):`, '50')
    if (input == null) return
    const add = Number(input)
    if (!Number.isFinite(add) || add === 0) return
    setBusy(u.id)
    await supabase
      .from('users')
      .update({ points_balance: Math.max(0, u.points_balance + add) })
      .eq('id', u.id)
    setBusy(null)
    load()
  }

  const filtered = rows.filter((u) => {
    const q = search.trim().toLowerCase()
    if (!q) return true
    return (
      (u.name ?? '').toLowerCase().includes(q) ||
      (u.phone ?? '').includes(q) ||
      (u.email ?? '').toLowerCase().includes(q)
    )
  })

  return (
    <>
      <PageHeader title="الزبائن" subtitle={`${rows.length} زبون`} />
      <div className="p-6">
        <div className="mb-4 relative max-w-md">
          <Search className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <Input
            className="pr-9"
            placeholder="بحث بالاسم أو الهاتف…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="bg-slate-50 text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">الزبون</th>
                  <th className="px-4 py-3 font-semibold">الهاتف</th>
                  <th className="px-4 py-3 font-semibold">النقاط</th>
                  <th className="px-4 py-3 font-semibold">المحفظة</th>
                  <th className="px-4 py-3 font-semibold">الحالة</th>
                  <th className="px-4 py-3 font-semibold">إجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filtered.map((u) => (
                  <tr key={u.id} className="hover:bg-slate-50/60">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-slate-100 font-bold text-slate-600">
                          {(u.name || u.phone || '?').charAt(0)}
                        </div>
                        <span className="font-semibold text-slate-800">
                          {u.name || 'بدون اسم'}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-slate-600" dir="ltr">
                      {u.phone || '—'}
                    </td>
                    <td className="px-4 py-3 font-semibold text-brand-700">{u.points_balance}</td>
                    <td className="px-4 py-3 text-slate-600">{formatMoney(u.wallet_balance)}</td>
                    <td className="px-4 py-3">
                      <Badge
                        className={
                          u.is_blocked
                            ? 'border-red-200 bg-red-50 text-red-700'
                            : 'border-green-200 bg-green-50 text-green-700'
                        }
                      >
                        {u.is_blocked ? 'محظور' : 'نشط'}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">
                      {canManage ? (
                        <div className="flex gap-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            disabled={busy === u.id}
                            onClick={() => addPoints(u)}
                          >
                            <Gift className="h-4 w-4 text-brand-600" /> نقاط
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            disabled={busy === u.id}
                            onClick={() => toggleBlock(u)}
                          >
                            {u.is_blocked ? (
                              <>
                                <CheckCircle2 className="h-4 w-4 text-green-600" /> رفع الحظر
                              </>
                            ) : (
                              <>
                                <Ban className="h-4 w-4 text-red-600" /> حظر
                              </>
                            )}
                          </Button>
                        </div>
                      ) : (
                        <span className="text-xs text-slate-400">عرض فقط</span>
                      )}
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={6} className="py-10 text-center text-slate-300">
                      لا يوجد زبائن
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
        <p className="mt-3 text-xs text-slate-400">
          ملاحظة: تعديل النقاط/الحظر متاح للمدير العام فقط (RLS). في الإنتاج يُفضّل تمرير
          تعديل الأرصدة عبر Edge Function لتسجيل العمليات.
        </p>
      </div>
    </>
  )
}
