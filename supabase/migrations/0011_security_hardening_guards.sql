-- ============================================================================
-- AzBerry — Security hardening (guards)  [applied to cloud 2026-08-12]
-- Fixes:
--   1. users: block customers from self-escalating role / inflating wallet /
--      points / unblocking / re-scoping (privilege-escalation + fraud).
--   2. orders: block customers/drivers from altering financial + ownership
--      columns; remove direct customer INSERT (orders go through place-order).
--   3. drivers: a driver may change only availability/location, not rating /
--      branch / active flag.
--   4. pin search_path on gen_referral_code.
--
-- Strategy: BEFORE-UPDATE guard triggers (SECURITY DEFINER). service_role
-- (Edge Functions) and staff/super_admin keep full access; the `authenticated`
-- Postgres role is shared by customers AND staff, so column-level GRANT revokes
-- were avoided (they would also block staff and break RLS helper functions).
-- ============================================================================

-- ---------- Item 1: users --------------------------------------------------
create or replace function public.guard_users_protected_cols()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.role() = 'service_role' or public.is_super_admin() then
    return new;
  end if;
  if new.role             is distinct from old.role
     or new.wallet_balance   is distinct from old.wallet_balance
     or new.points_balance   is distinct from old.points_balance
     or new.is_blocked       is distinct from old.is_blocked
     or new.scope_branch_id  is distinct from old.scope_branch_id
     or new.scope_country_id is distinct from old.scope_country_id
     or new.referral_code    is distinct from old.referral_code
     or new.referred_by      is distinct from old.referred_by then
    raise exception 'AZB_PROTECTED: modifying protected user fields is not allowed';
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_users_protected on public.users;
create trigger trg_guard_users_protected
  before update on public.users
  for each row execute function public.guard_users_protected_cols();

-- ---------- Item 2: orders -------------------------------------------------
create or replace function public.guard_orders_financials()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.role() = 'service_role' or public.is_staff() then
    return new;
  end if;
  if new.subtotal       is distinct from old.subtotal
     or new.delivery_fee   is distinct from old.delivery_fee
     or new.tax            is distinct from old.tax
     or new.discount       is distinct from old.discount
     or new.total          is distinct from old.total
     or new.payment_status is distinct from old.payment_status
     or new.user_id        is distinct from old.user_id
     or new.branch_id      is distinct from old.branch_id then
    raise exception 'AZB_PROTECTED: modifying protected order fields is not allowed';
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_orders_financials on public.orders;
create trigger trg_guard_orders_financials
  before update on public.orders
  for each row execute function public.guard_orders_financials();

drop policy if exists orders_customer_insert on public.orders;
drop policy if exists order_items_insert     on public.order_items;

-- ---------- Item 3: drivers ------------------------------------------------
create or replace function public.guard_drivers_self()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.role() = 'service_role' or public.is_staff() then
    return new;
  end if;
  if new.rating       is distinct from old.rating
     or new.is_active    is distinct from old.is_active
     or new.branch_id    is distinct from old.branch_id
     or new.user_id      is distinct from old.user_id
     or new.vehicle_type is distinct from old.vehicle_type
     or new.plate_number is distinct from old.plate_number then
    raise exception 'AZB_PROTECTED: drivers may change availability/location only';
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_drivers_self on public.drivers;
create trigger trg_guard_drivers_self
  before update on public.drivers
  for each row execute function public.guard_drivers_self();

-- ---------- Item 4a: search_path -------------------------------------------
create or replace function public.gen_referral_code()
returns text language sql set search_path = public as $$
  select upper(substr(md5(gen_random_uuid()::text), 1, 6));
$$;
