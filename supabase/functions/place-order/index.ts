// AzBerry — place-order
// The SECURE checkout path. Never trusts client prices: it recomputes every
// price from the database with the service role, validates the promo code,
// enforces branch min-order, then creates the order + items atomically.
//
// Requires a signed-in user (Authorization: Bearer <jwt>).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface ItemInput {
  product_id: string
  size_id?: string | null
  addon_ids?: string[]
  quantity: number
  notes?: string | null
}

interface Body {
  branch_id: string
  order_type: 'delivery' | 'pickup'
  payment_method: string
  items: ItemInput[]
  promo_code?: string | null
  address_id?: string | null
  notes?: string | null
}

// Inlined promo evaluation (kept self-contained so this function has no
// cross-function imports). Mirrors the standalone validate-promo function.
interface PromoResult {
  valid: boolean
  message: string
  discount: number
  delivery_waived: boolean
  promo_id?: string
}

async function evaluatePromo(
  admin: ReturnType<typeof createClient>,
  code: string,
  branchId: string,
  subtotal: number,
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
  if (subtotal < Number(promo.min_order)) return fail(`الحد الأدنى لاستخدام الكود ${promo.min_order}`)
  if (
    promo.branch_ids &&
    Array.isArray(promo.branch_ids) &&
    promo.branch_ids.length > 0 &&
    !promo.branch_ids.includes(branchId)
  ) {
    return fail('الكود غير متاح لهذا الفرع')
  }

  if (promo.type === 'free_delivery') {
    return { valid: true, message: 'توصيل مجاني', discount: 0, delivery_waived: true, promo_id: promo.id }
  }

  let discount =
    promo.type === 'percentage'
      ? Math.round((subtotal * Number(promo.value)) / 100)
      : Number(promo.value)
  if (promo.max_discount != null) discount = Math.min(discount, Number(promo.max_discount))
  discount = Math.min(discount, subtotal)

  return { valid: true, message: 'تم تطبيق الخصم', discount, delivery_waived: false, promo_id: promo.id }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'مطلوب تسجيل الدخول' }, 401)

    const url = Deno.env.get('SUPABASE_URL')!
    // Client bound to the caller's JWT — used only to identify the user.
    const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: userData } = await userClient.auth.getUser()
    const user = userData.user
    if (!user) return json({ error: 'جلسة غير صالحة' }, 401)

    // Privileged client for reads/writes that bypass RLS.
    const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)

    const body = (await req.json()) as Body
    if (!body.branch_id || !Array.isArray(body.items) || body.items.length === 0) {
      return json({ error: 'بيانات الطلب ناقصة' }, 400)
    }

    // --- Branch + country tax --------------------------------------------
    const { data: branch } = await admin
      .from('branches')
      .select('id, delivery_fee, min_order, is_active, country_id')
      .eq('id', body.branch_id)
      .maybeSingle()
    if (!branch || !branch.is_active) return json({ error: 'الفرع غير متاح' }, 400)

    const { data: country } = await admin
      .from('countries')
      .select('tax_rate')
      .eq('id', branch.country_id)
      .maybeSingle()
    const taxRate = Number(country?.tax_rate ?? 0)

    // --- Recompute item prices from the DB -------------------------------
    const productIds = [...new Set(body.items.map((i) => i.product_id))]
    const { data: products } = await admin
      .from('products')
      .select('id, base_price, is_active')
      .in('id', productIds)

    const { data: overrides } = await admin
      .from('branch_products')
      .select('product_id, price_override, is_available')
      .eq('branch_id', branch.id)
      .in('product_id', productIds)

    const sizeIds = body.items.map((i) => i.size_id).filter(Boolean) as string[]
    const { data: sizes } = sizeIds.length
      ? await admin.from('product_sizes').select('id, product_id, price_modifier').in('id', sizeIds)
      : { data: [] as any[] }

    const addonIds = [...new Set(body.items.flatMap((i) => i.addon_ids ?? []))]
    const { data: addons } = addonIds.length
      ? await admin.from('product_addons').select('id, product_id, name_ar, price').in('id', addonIds)
      : { data: [] as any[] }

    const productMap = new Map((products ?? []).map((p) => [p.id, p]))
    const overrideMap = new Map((overrides ?? []).map((o) => [o.product_id, o]))
    const sizeMap = new Map((sizes ?? []).map((s) => [s.id, s]))
    const addonMap = new Map((addons ?? []).map((a) => [a.id, a]))

    let subtotal = 0
    const itemRows: Record<string, unknown>[] = []

    for (const it of body.items) {
      const product = productMap.get(it.product_id)
      if (!product || !product.is_active) return json({ error: `منتج غير متاح` }, 400)

      const ov = overrideMap.get(it.product_id)
      if (ov && ov.is_available === false) return json({ error: 'أحد المنتجات غير متوفّر بالفرع' }, 400)

      const base = ov?.price_override != null ? Number(ov.price_override) : Number(product.base_price)

      let sizeMod = 0
      if (it.size_id) {
        const size = sizeMap.get(it.size_id)
        if (!size || size.product_id !== it.product_id) return json({ error: 'حجم غير صالح' }, 400)
        sizeMod = Number(size.price_modifier)
      }

      const chosenAddons = (it.addon_ids ?? []).map((id) => addonMap.get(id)).filter(Boolean)
      const addonsSum = chosenAddons.reduce((s, a) => s + Number(a!.price), 0)

      const qty = Math.max(1, Math.floor(Number(it.quantity) || 1))
      const unitPrice = base + sizeMod + addonsSum
      subtotal += unitPrice * qty

      itemRows.push({
        product_id: it.product_id,
        size_id: it.size_id ?? null,
        quantity: qty,
        unit_price: unitPrice,
        addons_json: chosenAddons.map((a) => ({ id: a!.id, name: a!.name_ar, price: a!.price })),
        notes: it.notes ?? null,
      })
    }

    // --- Min order -------------------------------------------------------
    if (subtotal < Number(branch.min_order)) {
      return json({ error: `الحد الأدنى للطلب ${branch.min_order}` }, 400)
    }

    // --- Delivery + promo + tax + total ----------------------------------
    let deliveryFee = body.order_type === 'delivery' ? Number(branch.delivery_fee) : 0
    let discount = 0
    let promoId: string | undefined

    if (body.promo_code) {
      const promo = await evaluatePromo(admin, body.promo_code, branch.id, subtotal)
      if (!promo.valid) return json({ error: promo.message }, 400)
      if (promo.delivery_waived) deliveryFee = 0
      discount = promo.discount
      promoId = promo.promo_id
    }

    const taxable = Math.max(0, subtotal - discount)
    const tax = Math.round(taxable * taxRate)
    const total = subtotal - discount + deliveryFee + tax

    // --- Create order + items --------------------------------------------
    const { data: order, error: orderErr } = await admin
      .from('orders')
      .insert({
        user_id: user.id,
        branch_id: branch.id,
        order_type: body.order_type,
        subtotal,
        delivery_fee: deliveryFee,
        tax,
        discount,
        total,
        payment_method: body.payment_method,
        address_id: body.address_id ?? null,
        notes: body.notes ?? null,
      })
      .select('id')
      .single()
    if (orderErr) return json({ error: `تعذّر إنشاء الطلب: ${orderErr.message}` }, 500)

    const orderId = order.id
    await admin.from('order_items').insert(itemRows.map((r) => ({ ...r, order_id: orderId })))

    // Record promo usage (best-effort)
    if (promoId) {
      await admin.from('promo_usage').insert({ promo_id: promoId, user_id: user.id, order_id: orderId })
      await admin.rpc('increment_promo_usage', { p_promo_id: promoId }).then(
        () => {},
        () => {},
      )
    }

    return json(
      {
        order_id: orderId,
        breakdown: { subtotal, discount, delivery_fee: deliveryFee, tax, total },
      },
      200,
    )
  } catch (e) {
    return json({ error: `خطأ غير متوقع: ${e}` }, 500)
  }
})

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })
}
