import * as React from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { Button, Input } from '@/components/ui/primitives'

export default function Login() {
  const navigate = useNavigate()
  const [email, setEmail] = React.useState('')
  const [password, setPassword] = React.useState('')
  const [err, setErr] = React.useState<string | null>(null)
  const [loading, setLoading] = React.useState(false)

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setErr(null)
    setLoading(true)
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    setLoading(false)
    if (error) {
      setErr(error.message)
      return
    }
    navigate('/')
  }

  return (
    <div className="flex h-full items-center justify-center bg-gradient-to-br from-brand-50 to-slate-100 p-4">
      <div className="w-full max-w-sm rounded-2xl border border-slate-200 bg-white p-8 shadow-lg">
        <div className="mb-6 text-center">
          <div className="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-brand-600 text-3xl">
            🫐
          </div>
          <h1 className="text-2xl font-extrabold text-slate-800">AzBerry</h1>
          <p className="text-sm text-slate-400">لوحة تحكم الإدارة</p>
        </div>

        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-600">
              البريد الإلكتروني
            </label>
            <Input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@azberry.com"
              dir="ltr"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-600">
              كلمة المرور
            </label>
            <Input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              dir="ltr"
            />
          </div>

          {err && (
            <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">
              {err}
            </div>
          )}

          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? 'جارِ الدخول…' : 'تسجيل الدخول'}
          </Button>
        </form>
      </div>
    </div>
  )
}
