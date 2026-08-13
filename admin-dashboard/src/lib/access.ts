// ─────────────────────────────────────────────────────────────────────────
// RBAC — single source of truth for what each staff role may see/do in the UI.
// The database (RLS + guard triggers) is the real enforcer; this layer keeps
// the interface honest so a role never sees a section or button it can't use.
// ─────────────────────────────────────────────────────────────────────────

export type UserRole =
  | 'customer'
  | 'driver'
  | 'cashier'
  | 'branch_manager'
  | 'country_manager'
  | 'super_admin'

const ALL_STAFF: UserRole[] = [
  'super_admin',
  'country_manager',
  'branch_manager',
  'cashier',
]

/** Which sidebar routes each role may open. */
export const ROUTE_ACCESS: Record<string, UserRole[]> = {
  '/': ALL_STAFF,
  '/orders': ALL_STAFF,
  '/products': ['super_admin', 'country_manager'],
  '/categories': ['super_admin', 'country_manager'],
  '/branches': ['super_admin', 'country_manager', 'branch_manager'],
  '/drivers': ['super_admin', 'country_manager', 'branch_manager'],
  '/customers': ['super_admin', 'country_manager'],
  '/promos': ['super_admin', 'country_manager'],
  '/inventory': ['super_admin', 'country_manager', 'branch_manager'],
  '/reports': ['super_admin', 'country_manager', 'branch_manager'],
  '/banners': ['super_admin', 'country_manager'],
}

export function canAccessRoute(role: string | null | undefined, path: string): boolean {
  if (!role) return false
  return ROUTE_ACCESS[path]?.includes(role as UserRole) ?? false
}

/**
 * Actions the database restricts to super_admin via guard triggers
 * (changing a user's role / points / wallet / block flag). The UI hides these
 * for everyone else so the buttons never silently fail.
 */
export function isSuperAdmin(role: string | null | undefined): boolean {
  return role === 'super_admin'
}
