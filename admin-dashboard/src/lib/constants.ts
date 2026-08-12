import type { Enums } from './database.types'

export const ORDER_STATUS_FLOW: Enums<'order_status'>[] = [
  'pending',
  'confirmed',
  'preparing',
  'ready',
  'on_the_way',
  'delivered',
]

export const ORDER_STATUS_LABEL: Record<Enums<'order_status'>, string> = {
  pending: 'قيد الانتظار',
  confirmed: 'مؤكّد',
  preparing: 'قيد التحضير',
  ready: 'جاهز',
  on_the_way: 'بالطريق',
  delivered: 'تم التسليم',
  cancelled: 'ملغى',
}

export const ORDER_STATUS_COLOR: Record<Enums<'order_status'>, string> = {
  pending: 'bg-amber-100 text-amber-700 border-amber-200',
  confirmed: 'bg-blue-100 text-blue-700 border-blue-200',
  preparing: 'bg-indigo-100 text-indigo-700 border-indigo-200',
  ready: 'bg-purple-100 text-purple-700 border-purple-200',
  on_the_way: 'bg-cyan-100 text-cyan-700 border-cyan-200',
  delivered: 'bg-green-100 text-green-700 border-green-200',
  cancelled: 'bg-red-100 text-red-700 border-red-200',
}

export const PAYMENT_METHOD_LABEL: Record<Enums<'payment_method'>, string> = {
  cash: 'نقداً',
  zaincash: 'ZainCash',
  asiahawala: 'AsiaHawala',
  fastpay: 'FastPay',
  qicard: 'Qi Card',
  card: 'بطاقة',
  wallet: 'المحفظة',
}

export function nextStatus(
  s: Enums<'order_status'>
): Enums<'order_status'> | null {
  const i = ORDER_STATUS_FLOW.indexOf(s)
  if (i === -1 || i === ORDER_STATUS_FLOW.length - 1) return null
  return ORDER_STATUS_FLOW[i + 1]
}
