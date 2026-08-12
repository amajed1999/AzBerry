import * as React from 'react'
import { Volume2, VolumeX, Plus, RefreshCw } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { PageHeader } from '@/components/Layout'
import { Button, Badge, Select } from '@/components/ui/primitives'
import { useAuth } from '@/context/AuthContext'
import type { Tables, Enums } from '@/lib/database.types'
import {
  ORDER_STATUS_FLOW,
  ORDER_STATUS_LABEL,
  ORDER_STATUS_COLOR,
  PAYMENT_METHOD_LABEL,
  nextStatus,
} from '@/lib/constants'
import { formatMoney, timeAgo } from '@/lib/utils'

type OrderRow = Tables<'orders'> & { branches: { name_ar: string } | null }
type Branch = Pick<Tables<'branches'>, 'id' | 'name_ar'>
type DriverLite = {
  id: string
  branch_id: string | null
  is_online: boolean
  users: { name: string | null } | null
}

// Columns shown on the live board (delivered/cancelled excluded)
const BOARD: Enums<'order_status'>[] = ORDER_STATUS_FLOW.filter(
  (s) => s !== 'delivered'
)

function beep() {
  try {
    const ctx = new (window.AudioContext ||
      (window as unknown as { webkitAudioContext: typeof AudioContext })
        .webkitAudioContext)()
    const o = ctx.createOscillator()
    const g = ctx.createGain()
    o.connect(g)
    g.connect(ctx.destination)
    o.frequency.value = 880
    g.gain.setValueAtTime(0.001, ctx.currentTime)
    g.gain.exponentialRampToValueAtTime(0.3, ctx.currentTime + 0.02)
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4)
    o.start()
    o.stop(ctx.currentTime + 0.4)
  } catch {
    /* ignore */
  }
}

export default function LiveOrders() {
  const { session } = useAuth()
  const [orders, setOrders] = React.useState<OrderRow[]>([])
  const [branches, setBranches] = React.useState<Branch[]>([])
  const [drivers, setDrivers] = React.useState<DriverLite[]>([])
  const [branchFilter, setBranchFilter] = React.useState('')
  const [sound, setSound] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const soundRef = React.useRef(sound)
  soundRef.current = sound

  const fetchOrders = React.useCallback(async () => {
    const { data } = await supabase
      .from('orders')
      .select('*, branches(name_ar)')
      .not('status', 'in', '(delivered,cancelled)')
      .order('created_at', { ascending: false })
    setOrders((data as unknown as OrderRow[]) ?? [])
  }, [])

  React.useEffect(() => {
    fetchOrders()
    supabase
      .from('branches')
      .select('id, name_ar')
      .order('name_ar')
      .then(({ data }) => setBranches(data ?? []))
    supabase
      .from('drivers')
      .select('id, branch_id, is_online, users(name)')
      .eq('is_active', true)
      .then(({ data }) => setDrivers((data as unknown as DriverLite[]) ?? []))

    // Realtime subscription
    const channel = supabase
      .channel('orders-live')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'orders' },
        (payload) => {
          if (payload.eventType === 'INSERT' && soundRef.current) beep()
          fetchOrders()
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [fetchOrders])

  async function advance(o: OrderRow) {
    const ns = nextStatus(o.status)
    if (!ns) return
    setBusy(true)
    await supabase.from('orders').update({ status: ns }).eq('id', o.id)
    setBusy(false)
    fetchOrders()
  }

  async function cancel(o: OrderRow) {
    setBusy(true)
    await supabase.from('orders').update({ status: 'cancelled' }).eq('id', o.id)
    setBusy(false)
    fetchOrders()
  }

  // Manually assign (or unassign) a driver to an order.
  async function assignDriver(o: OrderRow, driverId: string) {
    setBusy(true)
    await supabase
      .from('orders')
      .update({ driver_id: driverId || null })
      .eq('id', o.id)
    setBusy(false)
    fetchOrders()
  }

  // Dev helper: create a demo order to see realtime + the board working
  async function createTestOrder() {
    if (!session) return
    const branch = branches.find((b) => b.id === branchFilter) ?? branches[0]
    if (!branch) return
    const total = 5000 + Math.floor(Math.random() * 20000)
    setBusy(true)
    await supabase.from('orders').insert({
      user_id: session.user.id,
      branch_id: branch.id,
      order_type: 'delivery',
      subtotal: total - 2000,
      delivery_fee: 2000,
      total,
      payment_method: 'cash',
      notes: 'طلب تجريبي',
    })
    setBusy(false)
  }

  const filtered = branchFilter
    ? orders.filter((o) => o.branch_id === branchFilter)
    : orders

  return (
    <>
      <PageHeader
        title="الطلبات الحية"
        subtitle={`${filtered.length} طلب نشط`}
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
            <Button variant="outline" size="sm" onClick={() => setSound((s) => !s)}>
              {sound ? <Volume2 className="h-4 w-4" /> : <VolumeX className="h-4 w-4" />}
            </Button>
            <Button variant="outline" size="sm" onClick={fetchOrders}>
              <RefreshCw className="h-4 w-4" />
            </Button>
            <Button size="sm" onClick={createTestOrder} disabled={busy}>
              <Plus className="h-4 w-4" /> طلب تجريبي
            </Button>
          </div>
        }
      />

      <div className="flex gap-4 overflow-x-auto p-6">
        {BOARD.map((status) => {
          const col = filtered.filter((o) => o.status === status)
          return (
            <div key={status} className="flex w-72 shrink-0 flex-col">
              <div className="mb-3 flex items-center justify-between">
                <span className="font-bold text-slate-700">
                  {ORDER_STATUS_LABEL[status]}
                </span>
                <Badge className={ORDER_STATUS_COLOR[status]}>{col.length}</Badge>
              </div>
              <div className="space-y-3">
                {col.map((o) => {
                  const ns = nextStatus(o.status)
                  return (
                    <div
                      key={o.id}
                      className="rounded-xl border border-slate-200 bg-white p-3 shadow-sm"
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-mono text-xs text-slate-400">
                          #{o.id.slice(0, 8)}
                        </span>
                        <span className="text-xs text-slate-400">
                          {timeAgo(o.created_at)}
                        </span>
                      </div>
                      <div className="mt-1 text-sm font-semibold text-slate-700">
                        {o.branches?.name_ar ?? '—'}
                      </div>
                      <div className="mt-2 flex items-center justify-between">
                        <span className="text-lg font-extrabold text-brand-700">
                          {formatMoney(o.total)}
                        </span>
                        <Badge className="border-slate-200 bg-slate-50 text-slate-600">
                          {PAYMENT_METHOD_LABEL[o.payment_method]}
                        </Badge>
                      </div>
                      {/* Manual driver assignment */}
                      <div className="mt-2">
                        <Select
                          className="h-8 text-xs"
                          value={o.driver_id ?? ''}
                          disabled={busy}
                          onChange={(e) => assignDriver(o, e.target.value)}
                        >
                          <option value="">— بلا سائق —</option>
                          {drivers
                            .filter((d) => !d.branch_id || d.branch_id === o.branch_id)
                            .map((d) => (
                              <option key={d.id} value={d.id}>
                                {(d.users?.name ?? 'سائق') + (d.is_online ? ' 🟢' : ' ⚪')}
                              </option>
                            ))}
                        </Select>
                      </div>
                      <div className="mt-2 flex gap-2">
                        {ns && (
                          <Button
                            size="sm"
                            className="flex-1"
                            disabled={busy}
                            onClick={() => advance(o)}
                          >
                            {ORDER_STATUS_LABEL[ns]} ←
                          </Button>
                        )}
                        <Button
                          size="sm"
                          variant="danger"
                          disabled={busy}
                          onClick={() => cancel(o)}
                        >
                          إلغاء
                        </Button>
                      </div>
                    </div>
                  )
                })}
                {col.length === 0 && (
                  <div className="rounded-xl border border-dashed border-slate-200 py-8 text-center text-sm text-slate-300">
                    لا يوجد
                  </div>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </>
  )
}
