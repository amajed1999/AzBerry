import { NavLink, Outlet, useNavigate, useLocation } from 'react-router-dom'
import {
  LayoutDashboard,
  ClipboardList,
  Package,
  Store,
  LogOut,
  Tags,
  Image,
  Bike,
  Users,
  Ticket,
  Boxes,
  BarChart3,
} from 'lucide-react'
import { useAuth } from '@/context/AuthContext'
import { canAccessRoute } from '@/lib/access'
import { cn } from '@/lib/utils'

const NAV = [
  { to: '/', label: 'الرئيسية', icon: LayoutDashboard, end: true },
  { to: '/orders', label: 'الطلبات الحية', icon: ClipboardList, end: false },
  { to: '/products', label: 'إدارة المنتجات', icon: Package, end: false },
  { to: '/categories', label: 'الأصناف', icon: Tags, end: false },
  { to: '/branches', label: 'الفروع', icon: Store, end: false },
  { to: '/drivers', label: 'السائقون', icon: Bike, end: false },
  { to: '/customers', label: 'الزبائن', icon: Users, end: false },
  { to: '/promos', label: 'أكواد الخصم', icon: Ticket, end: false },
  { to: '/inventory', label: 'المخزون', icon: Boxes, end: false },
  { to: '/reports', label: 'التقارير', icon: BarChart3, end: false },
  { to: '/banners', label: 'البانرات', icon: Image, end: false },
]

const ROLE_LABEL: Record<string, string> = {
  super_admin: 'مدير عام',
  country_manager: 'مدير دولة',
  branch_manager: 'مدير فرع',
  cashier: 'كاشير',
}

export default function Layout() {
  const { profile, signOut } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  // Only show sidebar items this role may open.
  const visibleNav = NAV.filter((item) => canAccessRoute(profile?.role, item.to))
  // Guard the routed content too (covers typed URLs / stale links).
  const canView = canAccessRoute(profile?.role, location.pathname)

  return (
    <div className="flex h-full">
      {/* Sidebar */}
      <aside className="flex w-64 shrink-0 flex-col border-l border-slate-200 bg-white">
        <div className="border-b border-slate-100 p-5">
          <img
            src="/logo.jpg"
            alt="AzBerry"
            className="h-9 w-auto max-w-[150px] object-contain"
          />
          <div className="mt-1.5 text-xs text-slate-400">لوحة التحكم</div>
        </div>

        <nav className="flex-1 space-y-1 p-3">
          {visibleNav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold transition-colors',
                  isActive
                    ? 'bg-brand-50 text-brand-700'
                    : 'text-slate-600 hover:bg-slate-50'
                )
              }
            >
              <item.icon className="h-5 w-5" />
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="border-t border-slate-100 p-3">
          <div className="mb-2 flex items-center gap-2 px-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-100 text-sm font-bold text-slate-600">
              {(profile?.name || profile?.email || '?').charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0 flex-1">
              <div className="truncate text-sm font-semibold text-slate-700">
                {profile?.name || profile?.email}
              </div>
              <div className="text-xs text-slate-400">
                {ROLE_LABEL[profile?.role ?? ''] ?? profile?.role}
              </div>
            </div>
          </div>
          <button
            onClick={async () => {
              await signOut()
              navigate('/login')
            }}
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-red-600 hover:bg-red-50"
          >
            <LogOut className="h-4 w-4" />
            تسجيل الخروج
          </button>
        </div>
      </aside>

      {/* Main */}
      <main className="flex-1 overflow-auto">
        {canView ? <Outlet /> : <NoAccess />}
      </main>
    </div>
  )
}

function NoAccess() {
  return (
    <div className="flex h-full flex-col items-center justify-center gap-3 p-6 text-center">
      <div className="text-5xl">🔒</div>
      <h2 className="text-xl font-bold text-slate-800">لا تملك صلاحية هذا القسم</h2>
      <p className="max-w-md text-sm text-slate-500">
        هذا القسم غير متاح لدورك الحالي. تواصل مع المدير العام إن كنت تحتاج الوصول.
      </p>
    </div>
  )
}

export function PageHeader({
  title,
  subtitle,
  action,
}: {
  title: string
  subtitle?: string
  action?: React.ReactNode
}) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-slate-200 bg-white px-6 py-4">
      <div className="flex items-center gap-2">
        <Store className="hidden h-5 w-5 text-brand-600 sm:block" />
        <div>
          <h1 className="text-xl font-extrabold text-slate-800">{title}</h1>
          {subtitle && <p className="text-sm text-slate-400">{subtitle}</p>}
        </div>
      </div>
      {action}
    </div>
  )
}
