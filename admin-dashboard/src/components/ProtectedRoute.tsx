import { Navigate } from 'react-router-dom'
import { useAuth, isStaffRole } from '@/context/AuthContext'

export default function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { session, profile, loading } = useAuth()

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center text-slate-400">
        جارِ التحميل…
      </div>
    )
  }

  if (!session) return <Navigate to="/login" replace />

  if (!isStaffRole(profile?.role)) {
    return (
      <div className="flex h-full flex-col items-center justify-center gap-3 p-6 text-center">
        <div className="text-5xl">🔒</div>
        <h2 className="text-xl font-bold text-slate-800">لا تملك صلاحية الوصول</h2>
        <p className="max-w-md text-sm text-slate-500">
          هذا الحساب ليس ضمن فريق الإدارة. يجب أن يكون دورك أحد:
          كاشير / مدير فرع / مدير دولة / مدير عام. تواصل مع المدير العام لترقية حسابك.
        </p>
      </div>
    )
  }

  return <>{children}</>
}
