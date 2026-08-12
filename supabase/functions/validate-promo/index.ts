// AzBerry — validate-promo
// Validates a discount code against a subtotal/branch and returns the discount.
// Callable without auth (used for cart preview). Uses the service role to read
// promo_codes (which are hidden from clients by RLS).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface Body {
  code: string
  branch_id: string
  subtotal: number
  delivery_fee?: number
}

export interface PromoResult {
  valid: boolean
  message: string
  type?: 'percentage' | 'fixed' | 'free_delivery'
  discount: number // discount applied to subtotal
  delivery_waived: boolean
  promo_id?: string
}

export async function evaluatePromo(
  admin: ReturnType<typeof createClient>,
  code: string,
  branchId: string,
  subtotal: number,
  deliveryFee: number,
): Promise<PromoResult> {
  const fail = (message: string): PromoResult => ({
    valid: false,
    message,
    discount: 0,
    delivery_waived: false,
  })

  const { data: promo } = await admin
    .from('promo_codes')
    .select('*')
    .eq('code', code.trim().toUpperCase())
    .eq('is_active', true)
    .maybeSingle()

  if (!promo) return fail('كود الخصم غير صالح')

  const now = new Date()
  if (promo.valid_from && new Date(promo.valid_from) > now) return fail('كود الخصم لم يبدأ بعد')
  if (promo.valid_to && new Date(promo.valid_to) < now) return fail('انتهت صلاحية كود الخصم')
  if (promo.usage_limit != null && promo.used_count >= promo.usage_limit) {
    return fail('تم استنفاد كود الخصم')
  }
  if (subtotal < Number(promo.min_order)) {
    return fail(`الحد الأدنى لاستخدام الكود ${promo.min_order}`)
  }
  if (
    promo.branch_ids &&
    Array.isArray(promo.branch_ids) &&
    promo.branch_ids.length > 0 &&
    !promo.branch_ids.includes(branchId)
  ) {
    return fail('الكود غير متاح لهذا الفرع')
  }

  if (promo.type === 'free_delivery') {
    return {
      valid: true,
      message: 'توصيل مجاني',
      type: 'free_delivery',
      discount: 0,
      delivery_waived: true,
      promo_id: promo.id,
    }
  }

  let discount = 0
  if (promo.type === 'percentage') {
    discount = Math.round((subtotal * Number(promo.value)) / 100)
  } else {
    discount = Number(promo.value)
  }
  if (promo.max_discount != null) discount = Math.min(discount, Number(promo.max_discount))
  discount = Math.min(discount, subtotal) // never exceed subtotal

  return {
    valid: true,
    message: 'تم تطبيق الخصم',
    type: promo.type,
    discount,
    delivery_waived: false,
    promo_id: promo.id,
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const body = (await req.json()) as Body
    if (!body.code || !body.branch_id) {
      return json({ valid: false, message: 'بيانات ناقصة', discount: 0, delivery_waived: false }, 400)
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const result = await evaluatePromo(
      admin,
      body.code,
      body.branch_id,
      Number(body.subtotal) || 0,
      Number(body.delivery_fee) || 0,
    )
    return json(result, 200)
  } catch (e) {
    return json({ valid: false, message: `خطأ: ${e}`, discount: 0, delivery_waived: false }, 500)
  }
})

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })
}
