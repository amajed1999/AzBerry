// AzBerry — apply-referral
// A signed-in user enters a friend's referral code. Both the referrer and the
// new user get loyalty points (once). All balance changes run with the service
// role so clients can never award points to themselves directly.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const REWARD = 50 // points for each side

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'مطلوب تسجيل الدخول' }, 401)

    const url = Deno.env.get('SUPABASE_URL')!
    const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: u } = await userClient.auth.getUser()
    const user = u.user
    if (!user) return json({ error: 'جلسة غير صالحة' }, 401)

    const { code } = (await req.json()) as { code?: string }
    const norm = (code ?? '').trim().toUpperCase()
    if (!norm) return json({ error: 'أدخل كود الإحالة' }, 400)

    const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)

    const { data: me } = await admin
      .from('users')
      .select('id, points_balance, referred_by, referral_code')
      .eq('id', user.id)
      .maybeSingle()
    if (!me) return json({ error: 'الحساب غير موجود' }, 400)
    if (me.referred_by) return json({ error: 'لقد استخدمت كود إحالة مسبقاً' }, 400)
    if (norm === (me.referral_code ?? '')) return json({ error: 'لا يمكنك استخدام كودك الخاص' }, 400)

    const { data: referrer } = await admin
      .from('users')
      .select('id, points_balance')
      .eq('referral_code', norm)
      .maybeSingle()
    if (!referrer || referrer.id === me.id) return json({ error: 'كود الإحالة غير صالح' }, 400)

    // Credit both sides + link the referral.
    await admin
      .from('users')
      .update({ points_balance: (me.points_balance ?? 0) + REWARD, referred_by: referrer.id })
      .eq('id', me.id)
    await admin
      .from('users')
      .update({ points_balance: (referrer.points_balance ?? 0) + REWARD })
      .eq('id', referrer.id)

    await admin.from('point_transactions').insert([
      { user_id: me.id, amount: REWARD, reason: 'referral_signup' },
      { user_id: referrer.id, amount: REWARD, reason: 'referral_reward' },
    ])

    return json({ reward: REWARD, new_balance: (me.points_balance ?? 0) + REWARD }, 200)
  } catch (e) {
    return json({ error: `خطأ: ${e}` }, 500)
  }
})

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })
}
