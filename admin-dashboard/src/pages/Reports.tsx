import * as React from 'react'
import { Download, Printer, TrendingUp, ShoppingBag, DollarSign, XCircle } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { PageHeader } from '@/components/Layout'
import { Button, Card, CardBody, Input } from '@/components/ui/primitives'
import { formatMoney } from '@/lib/utils'
import type { Tables } from '@/lib/database.types'

type OrderLite = Pick<
  Tables<'orders'>,
  'id' | 'branch_id' | 'total' | 'status' | 'created_at'
>
type ItemLite = Pick<Tables<'order_items'>, 'order_id' | 'product_id' | 'quantity' | 'unit_price'>

function isoDaysAgo(n: number) {
  const d = new Date()
  d.setDate(d.getDate() - n)
  d.setHours(0, 0, 0, 0)
  return d.toISOString().slice(0, 10)
}

function downloadCsv(filename: string, rows: (string | number)[][]) {
  const csv = rows
    .map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(','))
    .join('\n')
  // BOM so Excel reads Arabic UTF-8 correctly
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}

export default function Reports() {
  const [from, setFrom] = React.useState(isoDaysAgo(30))
  const [to, setTo] = React.useState(isoDaysAgo(0))
  const [loading, setLoading] = React.useState(false)
  const [orders, setOrders] = React.useState<OrderLite[]>([])
  const [items, setItems] = React.useState<ItemLite[]>([])
  const [branchName, setBranchName] = React.useState<Record<string, string>>({})
  const [productName, setProductName] = React.useState<Record<string, string>>({})

  const run = React.useCallback(async () => {
    setLoading(true)
    const toEnd = new Date(to)
    toEnd.setDate(toEnd.getDate() + 1) // inclusive end day

    const { data: ords } = await supabase
      .from('orders')
      .select('id, branch_id, total, status, created_at')
      .gte('created_at', new Date(from).toISOString())
      .lt('created_at', toEnd.toISOString())
      .order('created_at', { ascending: false })

    const orderList = (ords ?? []) as OrderLite[]
    setOrders(orderList)

    const ids = orderList.map((o) => o.id)
    let itemList: ItemLite[] = []
    if (ids.length) {
      const { data: its } = await supabase
        .from('order_items')
        .select('order_id, product_id, quantity, unit_price')
        .in('order_id', ids)
      itemList = (its ?? []) as ItemLite[]
    }
    setItems(itemList)

    const [{ data: b }, { data: p }] = await Promise.all([
      supabase.from('branches').select('id, name_ar'),
      supabase.from('products').select('id, name_ar'),
    ])
    setBranchName(Object.fromEntries((b ?? []).map((x) => [x.id, x.name_ar])))
    setProductName(Object.fromEntries((p ?? []).map((x) => [x.id, x.name_ar])))
    setLoading(false)
  }, [from, to])

  React.useEffect(() => {
    run()
  }, [run])

  // --- Aggregations ---------------------------------------------------------
  const valid = orders.filter((o) => o.status !== 'cancelled')
  const revenue = valid.reduce((s, o) => s + Number(o.total), 0)
  const cancelled = orders.length - valid.length
  const avg = valid.length ? Math.round(revenue / valid.length) : 0

  const byBranch = React.useMemo(() => {
    const m = new Map<string, { count: number; total: number }>()
    for (const o of valid) {
      const e = m.get(o.branch_id) ?? { count: 0, total: 0 }
      e.count++
      e.total += Number(o.total)
      m.set(o.branch_id, e)
    }
    return [...m.entries()]
      .map(([id, v]) => ({ id, ...v }))
      .sort((a, b) => b.total - a.total)
  }, [valid])

  const topProducts = React.useMemo(() => {
    const validIds = new Set(valid.map((o) => o.id))
    const m = new Map<string, { qty: number; total: number }>()
    for (const it of items) {
      if (!validIds.has(it.order_id)) continue
      const e = m.get(it.product_id) ?? { qty: 0, total: 0 }
      e.qty += Number(it.quantity)
      e.total += Number(it.unit_price) * Number(it.quantity)
      m.set(it.product_id, e)
    }
    return [...m.entries()]
      .map(([id, v]) => ({ id, ...v }))
      .sort((a, b) => b.qty - a.qty)
      .slice(0, 10)
  }, [items, valid])

  const byHour = React.useMemo(() => {
    const arr = new Array(24).fill(0)
    for (const o of valid) arr[new Date(o.created_at).getHours()]++
    const max = Math.max(1, ...arr)
    return arr.map((count, hour) => ({ hour, count, pct: Math.round((count / max) * 100) }))
  }, [valid])

  const kpis = [
    { label: 'إجمالي المبيعات', value: formatMoney(revenue), icon: DollarSign, color: 'bg-green-50 text-green-600' },
    { label: 'عدد الطلبات', value: valid.length, icon: ShoppingBag, color: 'bg-blue-50 text-blue-600' },
    { label: 'متوسط الطلب', value: formatMoney(avg), icon: TrendingUp, color: 'bg-purple-50 text-purple-600' },
    { label: 'طلبات ملغاة', value: cancelled, icon: XCircle, color: 'bg-red-50 text-red-600' },
  ]

  function exportExcel() {
    const rows: (string | number)[][] = [
      ['تقرير AzBerry', `${from} → ${to}`],
      [],
      ['ملخّص'],
      ['إجمالي المبيعات', revenue],
      ['عدد الطلبات', valid.length],
      ['متوسط الطلب', avg],
      ['طلبات ملغاة', cancelled],
      [],
      ['المبيعات حسب الفرع'],
      ['الفرع', 'عدد الطلبات', 'المبيعات'],
      ...byBranch.map((b) => [branchName[b.id] ?? b.id, b.count, b.total]),
      [],
      ['الأكثر مبيعاً'],
      ['المنتج', 'الكمية', 'الإيراد'],
      ...topProducts.map((p) => [productName[p.id] ?? p.id, p.qty, p.total]),
    ]
    downloadCsv(`azberry-report-${from}_${to}.csv`, rows)
  }

  return (
    <>
      <PageHeader
        title="التقارير"
        subtitle="المبيعات والمنتجات وأوقات الذروة"
        action={
          <div className="flex flex-wrap items-center gap-2 print:hidden">
            <Input type="date" value={from} onChange={(e) => setFrom(e.target.value)} className="w-40" />
            <span className="text-slate-400">→</span>
            <Input type="date" value={to} onChange={(e) => setTo(e.target.value)} className="w-40" />
            <Button variant="outline" size="sm" onClick={exportExcel}>
              <Download className="h-4 w-4" /> Excel
            </Button>
            <Button variant="outline" size="sm" onClick={() => window.print()}>
              <Printer className="h-4 w-4" /> PDF
            </Button>
          </div>
        }
      />
      <div className="p-6" id="report-area">
        {loading ? (
          <div className="py-20 text-center text-slate-400">جارِ تحضير التقرير…</div>
        ) : (
          <div className="space-y-6">
            {/* KPIs */}
            <div className="grid grid-cols-2 gap-4 xl:grid-cols-4">
              {kpis.map((k) => (
                <Card key={k.label}>
                  <CardBody className="flex items-center gap-4">
                    <div className={`flex h-12 w-12 items-center justify-center rounded-xl ${k.color}`}>
                      <k.icon className="h-6 w-6" />
                    </div>
                    <div>
                      <div className="text-sm text-slate-400">{k.label}</div>
                      <div className="text-2xl font-extrabold text-slate-800">{k.value}</div>
                    </div>
                  </CardBody>
                </Card>
              ))}
            </div>

            <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
              {/* Sales by branch */}
              <Card>
                <div className="border-b border-slate-100 p-4 font-bold text-slate-700">
                  المبيعات حسب الفرع
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-right text-sm">
                    <thead className="bg-slate-50 text-slate-500">
                      <tr>
                        <th className="px-4 py-2 font-semibold">الفرع</th>
                        <th className="px-4 py-2 font-semibold">الطلبات</th>
                        <th className="px-4 py-2 font-semibold">المبيعات</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {byBranch.map((b) => (
                        <tr key={b.id}>
                          <td className="px-4 py-2 font-semibold text-slate-700">
                            {branchName[b.id] ?? '—'}
                          </td>
                          <td className="px-4 py-2 text-slate-500">{b.count}</td>
                          <td className="px-4 py-2 font-semibold text-brand-700">
                            {formatMoney(b.total)}
                          </td>
                        </tr>
                      ))}
                      {byBranch.length === 0 && (
                        <tr>
                          <td colSpan={3} className="py-8 text-center text-slate-300">
                            لا بيانات
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </Card>

              {/* Top products */}
              <Card>
                <div className="border-b border-slate-100 p-4 font-bold text-slate-700">
                  الأكثر مبيعاً
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-right text-sm">
                    <thead className="bg-slate-50 text-slate-500">
                      <tr>
                        <th className="px-4 py-2 font-semibold">المنتج</th>
                        <th className="px-4 py-2 font-semibold">الكمية</th>
                        <th className="px-4 py-2 font-semibold">الإيراد</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {topProducts.map((p) => (
                        <tr key={p.id}>
                          <td className="px-4 py-2 font-semibold text-slate-700">
                            {productName[p.id] ?? '—'}
                          </td>
                          <td className="px-4 py-2 text-slate-500">{p.qty}</td>
                          <td className="px-4 py-2 font-semibold text-brand-700">
                            {formatMoney(p.total)}
                          </td>
                        </tr>
                      ))}
                      {topProducts.length === 0 && (
                        <tr>
                          <td colSpan={3} className="py-8 text-center text-slate-300">
                            لا بيانات
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </Card>
            </div>

            {/* Peak hours */}
            <Card>
              <div className="border-b border-slate-100 p-4 font-bold text-slate-700">
                أوقات الذروة (عدد الطلبات حسب الساعة)
              </div>
              <CardBody>
                <div className="flex items-end gap-1" style={{ height: 160 }}>
                  {byHour.map((h) => (
                    <div key={h.hour} className="flex flex-1 flex-col items-center gap-1">
                      <div
                        className="w-full rounded-t bg-brand-500"
                        style={{ height: `${Math.max(2, h.pct)}%` }}
                        title={`الساعة ${h.hour}: ${h.count} طلب`}
                      />
                      <span className="text-[9px] text-slate-400">{h.hour}</span>
                    </div>
                  ))}
                </div>
              </CardBody>
            </Card>
          </div>
        )}
      </div>
    </>
  )
}
