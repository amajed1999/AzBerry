import * as React from 'react'
import { TrendingUp, ShoppingBag, Clock, DollarSign } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { Card, CardBody } from '@/components/ui/primitives'
import { PageHeader } from '@/components/Layout'
import { formatMoney } from '@/lib/utils'

type Stats = {
  todayOrders: number
  todayRevenue: number
  activeOrders: number
  avgOrder: number
}

export default function Dashboard() {
  const [stats, setStats] = React.useState<Stats | null>(null)

  React.useEffect(() => {
    ;(async () => {
      const startOfDay = new Date()
      startOfDay.setHours(0, 0, 0, 0)

      const { data: today } = await supabase
        .from('orders')
        .select('total, status')
        .gte('created_at', startOfDay.toISOString())

      const { count: active } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true })
        .not('status', 'in', '(delivered,cancelled)')

      const list = today ?? []
      const revenue = list
        .filter((o) => o.status !== 'cancelled')
        .reduce((s, o) => s + Number(o.total), 0)

      setStats({
        todayOrders: list.length,
        todayRevenue: revenue,
        activeOrders: active ?? 0,
        avgOrder: list.length ? Math.round(revenue / list.length) : 0,
      })
    })()
  }, [])

  const cards = [
    {
      label: 'طلبات اليوم',
      value: stats?.todayOrders ?? '—',
      icon: ShoppingBag,
      color: 'bg-blue-50 text-blue-600',
    },
    {
      label: 'مبيعات اليوم',
      value: stats ? formatMoney(stats.todayRevenue) : '—',
      icon: DollarSign,
      color: 'bg-green-50 text-green-600',
    },
    {
      label: 'طلبات نشطة الآن',
      value: stats?.activeOrders ?? '—',
      icon: Clock,
      color: 'bg-amber-50 text-amber-600',
    },
    {
      label: 'متوسط قيمة الطلب',
      value: stats ? formatMoney(stats.avgOrder) : '—',
      icon: TrendingUp,
      color: 'bg-purple-50 text-purple-600',
    },
  ]

  return (
    <>
      <PageHeader title="الرئيسية" subtitle="نظرة عامة على أداء اليوم" />
      <div className="p-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {cards.map((c) => (
            <Card key={c.label}>
              <CardBody className="flex items-center gap-4">
                <div
                  className={`flex h-12 w-12 items-center justify-center rounded-xl ${c.color}`}
                >
                  <c.icon className="h-6 w-6" />
                </div>
                <div>
                  <div className="text-sm text-slate-400">{c.label}</div>
                  <div className="text-2xl font-extrabold text-slate-800">
                    {c.value}
                  </div>
                </div>
              </CardBody>
            </Card>
          ))}
        </div>

        <Card className="mt-6">
          <CardBody>
            <p className="text-sm text-slate-500">
              💡 هذه الأرقام تُحتسب من جدول الطلبات مباشرةً. بمجرد وصول طلبات
              حقيقية من التطبيق ستتحدّث تلقائياً. الرسوم البيانية ومقارنات الفروع
              ستُضاف في تكرار لاحق.
            </p>
          </CardBody>
        </Card>
      </div>
    </>
  )
}
