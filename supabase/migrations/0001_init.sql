-- ============================================================================
-- AzBerry Delivery Platform — Database Schema (Step 1)
-- Target: Supabase (PostgreSQL 15+)
-- Includes: enums, tables, relationships, indexes, helper functions,
--           triggers, and Row Level Security (RLS) policies.
--
-- Safe to run once on a fresh Supabase project (SQL Editor or migration).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0) Extensions
-- ----------------------------------------------------------------------------
create extension if not exists "pgcrypto";     -- gen_random_uuid()
create extension if not exists "postgis";       -- geography/distance (optional, for delivery radius)

-- ----------------------------------------------------------------------------
-- 1) Enums
-- ----------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type user_role as enum
      ('customer', 'driver', 'cashier', 'branch_manager', 'country_manager', 'super_admin');
  end if;

  if not exists (select 1 from pg_type where typname = 'app_language') then
    create type app_language as enum ('ar', 'en');
  end if;

  if not exists (select 1 from pg_type where typname = 'order_type') then
    create type order_type as enum ('delivery', 'pickup');
  end if;

  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type order_status as enum
      ('pending', 'confirmed', 'preparing', 'ready', 'on_the_way', 'delivered', 'cancelled');
  end if;

  if not exists (select 1 from pg_type where typname = 'payment_method') then
    create type payment_method as enum
      ('cash', 'zaincash', 'asiahawala', 'fastpay', 'qicard', 'card', 'wallet');
  end if;

  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type payment_status as enum ('pending', 'paid', 'failed', 'refunded');
  end if;

  if not exists (select 1 from pg_type where typname = 'promo_type') then
    create type promo_type as enum ('percentage', 'fixed', 'free_delivery');
  end if;

  if not exists (select 1 from pg_type where typname = 'banner_action') then
    create type banner_action as enum ('none', 'product', 'category', 'url');
  end if;
end$$;

-- ----------------------------------------------------------------------------
-- 2) Generic updated_at trigger function
-- ----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================================
-- 3) TABLES
-- ============================================================================

-- --- countries --------------------------------------------------------------
create table if not exists public.countries (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  currency    text not null,            -- e.g. 'IQD', 'JOD', 'EGP', 'USD', 'CAD'
  tax_rate    numeric(5,4) not null default 0,   -- 0.0000 .. 1.0000
  phone_code  text not null,            -- e.g. '+964'
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- --- users (profile linked to auth.users) -----------------------------------
create table if not exists public.users (
  id               uuid primary key references auth.users(id) on delete cascade,
  phone            text,
  name             text,
  email            text,
  role             user_role not null default 'customer',
  language         app_language not null default 'ar',
  country_id       uuid references public.countries(id) on delete set null,
  points_balance   integer not null default 0 check (points_balance >= 0),
  wallet_balance   numeric(12,2) not null default 0 check (wallet_balance >= 0),
  -- Scope for staff roles (needed for multi-level RLS):
  scope_country_id uuid references public.countries(id) on delete set null,
  scope_branch_id  uuid,   -- FK added after branches table exists
  is_blocked       boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- --- branches ---------------------------------------------------------------
create table if not exists public.branches (
  id                 uuid primary key default gen_random_uuid(),
  country_id         uuid not null references public.countries(id) on delete restrict,
  name_ar            text not null,
  name_en            text not null,
  lat                double precision not null,
  lng                double precision not null,
  phone              text,
  open_time          time not null default '10:00',
  close_time         time not null default '03:00',   -- past-midnight close (10:00 -> 03:00)
  delivery_radius_km numeric(6,2) not null default 5,
  delivery_fee       numeric(10,2) not null default 0,
  min_order          numeric(10,2) not null default 0,
  is_active          boolean not null default true,
  is_busy            boolean not null default false,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- Now that branches exists, add the deferred FK on users.scope_branch_id
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'users_scope_branch_id_fkey'
  ) then
    alter table public.users
      add constraint users_scope_branch_id_fkey
      foreign key (scope_branch_id) references public.branches(id) on delete set null;
  end if;
end$$;

-- --- addresses --------------------------------------------------------------
create table if not exists public.addresses (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.users(id) on delete cascade,
  label        text,                    -- 'home', 'work', ...
  lat          double precision not null,
  lng          double precision not null,
  address_text text,
  building     text,
  notes        text,
  is_default   boolean not null default false,
  created_at   timestamptz not null default now()
);

-- --- categories -------------------------------------------------------------
create table if not exists public.categories (
  id         uuid primary key default gen_random_uuid(),
  name_ar    text not null,
  name_en    text not null,
  image_url  text,
  sort_order integer not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

-- --- products ---------------------------------------------------------------
create table if not exists public.products (
  id             uuid primary key default gen_random_uuid(),
  category_id    uuid not null references public.categories(id) on delete restrict,
  name_ar        text not null,
  name_en        text not null,
  description_ar text,
  description_en text,
  image_url      text,
  base_price     numeric(10,2) not null check (base_price >= 0),
  calories       integer,
  is_active      boolean not null default true,
  sort_order     integer not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- --- product_sizes ----------------------------------------------------------
create table if not exists public.product_sizes (
  id             uuid primary key default gen_random_uuid(),
  product_id     uuid not null references public.products(id) on delete cascade,
  size_name      text not null,          -- 'small' | 'medium' | 'large'
  price_modifier numeric(10,2) not null default 0
);

-- --- product_addons ---------------------------------------------------------
create table if not exists public.product_addons (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  name_ar    text not null,
  name_en    text not null,
  price      numeric(10,2) not null default 0 check (price >= 0)
);

-- --- branch_products (per-branch availability & price override) --------------
create table if not exists public.branch_products (
  id             uuid primary key default gen_random_uuid(),
  branch_id      uuid not null references public.branches(id) on delete cascade,
  product_id     uuid not null references public.products(id) on delete cascade,
  is_available   boolean not null default true,
  price_override numeric(10,2),
  unique (branch_id, product_id)
);

-- --- drivers ----------------------------------------------------------------
create table if not exists public.drivers (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null unique references public.users(id) on delete cascade,
  branch_id    uuid references public.branches(id) on delete set null,
  vehicle_type text,
  plate_number text,
  is_online    boolean not null default false,
  current_lat  double precision,
  current_lng  double precision,
  rating       numeric(3,2) not null default 5.0 check (rating >= 0 and rating <= 5),
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- --- orders -----------------------------------------------------------------
create table if not exists public.orders (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.users(id) on delete restrict,
  branch_id      uuid not null references public.branches(id) on delete restrict,
  driver_id      uuid references public.drivers(id) on delete set null,
  order_type     order_type not null default 'delivery',
  status         order_status not null default 'pending',
  subtotal       numeric(12,2) not null default 0,
  delivery_fee   numeric(10,2) not null default 0,
  tax            numeric(10,2) not null default 0,
  discount       numeric(10,2) not null default 0,
  total          numeric(12,2) not null default 0,
  payment_method payment_method not null default 'cash',
  payment_status payment_status not null default 'pending',
  address_id     uuid references public.addresses(id) on delete set null,
  scheduled_at   timestamptz,
  notes          text,
  created_at     timestamptz not null default now(),
  delivered_at   timestamptz,
  updated_at     timestamptz not null default now()
);

-- --- order_items ------------------------------------------------------------
create table if not exists public.order_items (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete restrict,
  size_id     uuid references public.product_sizes(id) on delete set null,
  quantity    integer not null default 1 check (quantity > 0),
  unit_price  numeric(10,2) not null,
  addons_json jsonb not null default '[]'::jsonb,  -- [{id,name,price}, ...]
  notes       text
);

-- --- order_status_history ---------------------------------------------------
create table if not exists public.order_status_history (
  id         uuid primary key default gen_random_uuid(),
  order_id   uuid not null references public.orders(id) on delete cascade,
  status     order_status not null,
  changed_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- --- promo_codes ------------------------------------------------------------
create table if not exists public.promo_codes (
  id           uuid primary key default gen_random_uuid(),
  code         text not null unique,
  type         promo_type not null,
  value        numeric(10,2) not null default 0,       -- % or fixed amount
  min_order    numeric(10,2) not null default 0,
  max_discount numeric(10,2),
  usage_limit  integer,                                 -- null = unlimited
  used_count   integer not null default 0,
  valid_from   timestamptz,
  valid_to     timestamptz,
  branch_ids   uuid[],                                  -- null/empty = all branches
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- --- promo_usage ------------------------------------------------------------
create table if not exists public.promo_usage (
  id       uuid primary key default gen_random_uuid(),
  promo_id uuid not null references public.promo_codes(id) on delete cascade,
  user_id  uuid not null references public.users(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  used_at  timestamptz not null default now()
);

-- --- reviews ----------------------------------------------------------------
create table if not exists public.reviews (
  id         uuid primary key default gen_random_uuid(),
  order_id   uuid not null unique references public.orders(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  rating     integer not null check (rating between 1 and 5),
  comment    text,
  created_at timestamptz not null default now()
);

-- --- banners ----------------------------------------------------------------
create table if not exists public.banners (
  id           uuid primary key default gen_random_uuid(),
  image_url    text not null,
  action_type  banner_action not null default 'none',
  action_value text,                 -- product_id / category_id / url
  country_id   uuid references public.countries(id) on delete cascade,
  sort_order   integer not null default 0,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

-- --- notifications ----------------------------------------------------------
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users(id) on delete cascade,
  title_ar   text,
  title_en   text,
  body_ar    text,
  body_en    text,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

-- --- inventory_items --------------------------------------------------------
create table if not exists public.inventory_items (
  id            uuid primary key default gen_random_uuid(),
  branch_id     uuid not null references public.branches(id) on delete cascade,
  name          text not null,
  unit          text,                       -- 'kg', 'liter', 'pcs'
  quantity      numeric(12,2) not null default 0,
  min_threshold numeric(12,2) not null default 0,
  updated_at    timestamptz not null default now()
);

-- ============================================================================
-- 4) INDEXES
-- ============================================================================
create index if not exists idx_users_role            on public.users(role);
create index if not exists idx_users_scope_branch     on public.users(scope_branch_id);
create index if not exists idx_users_scope_country    on public.users(scope_country_id);
create index if not exists idx_addresses_user         on public.addresses(user_id);
create index if not exists idx_branches_country       on public.branches(country_id);
create index if not exists idx_branches_active        on public.branches(is_active);
create index if not exists idx_products_category      on public.products(category_id);
create index if not exists idx_product_sizes_product  on public.product_sizes(product_id);
create index if not exists idx_product_addons_product on public.product_addons(product_id);
create index if not exists idx_branch_products_branch on public.branch_products(branch_id);
create index if not exists idx_drivers_branch         on public.drivers(branch_id);
create index if not exists idx_drivers_online         on public.drivers(is_online);
create index if not exists idx_orders_user            on public.orders(user_id);
create index if not exists idx_orders_branch_status   on public.orders(branch_id, status);
create index if not exists idx_orders_driver          on public.orders(driver_id);
create index if not exists idx_orders_created         on public.orders(created_at desc);
create index if not exists idx_order_items_order      on public.order_items(order_id);
create index if not exists idx_status_history_order   on public.order_status_history(order_id);
create index if not exists idx_promo_usage_promo      on public.promo_usage(promo_id);
create index if not exists idx_reviews_order          on public.reviews(order_id);
create index if not exists idx_banners_country        on public.banners(country_id);
create index if not exists idx_notifications_user     on public.notifications(user_id, is_read);
create index if not exists idx_inventory_branch       on public.inventory_items(branch_id);

-- ============================================================================
-- 5) updated_at triggers
-- ============================================================================
do $$
declare t text;
begin
  foreach t in array array[
    'countries','users','branches','products','drivers',
    'orders','promo_codes','inventory_items'
  ]
  loop
    execute format(
      'drop trigger if exists trg_%1$s_updated_at on public.%1$s;
       create trigger trg_%1$s_updated_at before update on public.%1$s
       for each row execute function public.set_updated_at();', t);
  end loop;
end$$;

-- ============================================================================
-- 6) Auto-create profile row when an auth user is created
-- ============================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, phone, email, name)
  values (
    new.id,
    new.phone,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- 7) Record order status changes into history
-- ============================================================================
create or replace function public.log_order_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (tg_op = 'INSERT') or (new.status is distinct from old.status) then
    insert into public.order_status_history (order_id, status, changed_by)
    values (new.id, new.status, auth.uid());
  end if;
  if new.status = 'delivered' and new.delivered_at is null then
    new.delivered_at = now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_orders_status_history_ins on public.orders;
create trigger trg_orders_status_history_ins
  after insert on public.orders
  for each row execute function public.log_order_status();

drop trigger if exists trg_orders_status_history_upd on public.orders;
create trigger trg_orders_status_history_upd
  before update on public.orders
  for each row execute function public.log_order_status();

-- ============================================================================
-- 8) RLS helper functions (SECURITY DEFINER -> bypass RLS, avoid recursion)
-- ============================================================================
create or replace function public.my_role()
returns user_role
language sql
stable
security definer
set search_path = public
as $$ select role from public.users where id = auth.uid() $$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select coalesce((select role = 'super_admin' from public.users where id = auth.uid()), false) $$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select role in ('cashier','branch_manager','country_manager','super_admin')
    from public.users where id = auth.uid()
  ), false)
$$;

create or replace function public.my_scope_branch()
returns uuid
language sql
stable
security definer
set search_path = public
as $$ select scope_branch_id from public.users where id = auth.uid() $$;

create or replace function public.my_scope_country()
returns uuid
language sql
stable
security definer
set search_path = public
as $$ select scope_country_id from public.users where id = auth.uid() $$;

-- Can the current user manage/see this branch, based on their role scope?
create or replace function public.can_manage_branch(target_branch uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare r user_role;
begin
  select role into r from public.users where id = auth.uid();
  if r is null then return false; end if;
  if r = 'super_admin' then return true; end if;
  if r = 'country_manager' then
    return exists (
      select 1 from public.branches b
      where b.id = target_branch and b.country_id = my_scope_country()
    );
  end if;
  if r in ('branch_manager','cashier') then
    return target_branch = my_scope_branch();
  end if;
  return false;
end;
$$;

-- driver id of the current user (if any)
create or replace function public.my_driver_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$ select id from public.drivers where user_id = auth.uid() $$;

-- ============================================================================
-- 9) ENABLE RLS on all tables
-- ============================================================================
do $$
declare t text;
begin
  foreach t in array array[
    'countries','users','addresses','branches','categories','products',
    'product_sizes','product_addons','branch_products','drivers','orders',
    'order_items','order_status_history','promo_codes','promo_usage',
    'reviews','banners','notifications','inventory_items'
  ]
  loop
    execute format('alter table public.%I enable row level security;', t);
  end loop;
end$$;

-- ============================================================================
-- 10) POLICIES
-- Notes:
--   * "anon" + "authenticated" can browse the public catalog (guest browsing).
--   * Sensitive writes (order pricing, wallet/points, payment status) should be
--     performed by Edge Functions using the SERVICE ROLE key, which bypasses RLS.
--     The customer-facing INSERT policies below are intentionally conservative.
-- ============================================================================

-- ---------- countries -------------------------------------------------------
drop policy if exists countries_read on public.countries;
create policy countries_read on public.countries
  for select to anon, authenticated using (is_active or public.is_staff());

drop policy if exists countries_write on public.countries;
create policy countries_write on public.countries
  for all to authenticated
  using (public.is_super_admin()) with check (public.is_super_admin());

-- ---------- users -----------------------------------------------------------
drop policy if exists users_select_self on public.users;
create policy users_select_self on public.users
  for select to authenticated
  using (id = auth.uid() or public.is_staff());

-- Users may update their own profile fields. (Role / balances must not be
-- changed by the client — enforce via Edge Functions / service role.)
drop policy if exists users_update_self on public.users;
create policy users_update_self on public.users
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists users_admin_all on public.users;
create policy users_admin_all on public.users
  for all to authenticated
  using (public.is_super_admin()) with check (public.is_super_admin());

-- ---------- addresses -------------------------------------------------------
drop policy if exists addresses_owner on public.addresses;
create policy addresses_owner on public.addresses
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists addresses_staff_read on public.addresses;
create policy addresses_staff_read on public.addresses
  for select to authenticated using (public.is_staff());

-- ---------- branches --------------------------------------------------------
drop policy if exists branches_read on public.branches;
create policy branches_read on public.branches
  for select to anon, authenticated
  using (is_active or public.can_manage_branch(id));

drop policy if exists branches_write on public.branches;
create policy branches_write on public.branches
  for all to authenticated
  using (public.can_manage_branch(id)) with check (public.can_manage_branch(id));

-- ---------- categories ------------------------------------------------------
drop policy if exists categories_read on public.categories;
create policy categories_read on public.categories
  for select to anon, authenticated using (is_active or public.is_staff());

drop policy if exists categories_write on public.categories;
create policy categories_write on public.categories
  for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- ---------- products --------------------------------------------------------
drop policy if exists products_read on public.products;
create policy products_read on public.products
  for select to anon, authenticated using (is_active or public.is_staff());

drop policy if exists products_write on public.products;
create policy products_write on public.products
  for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- ---------- product_sizes ---------------------------------------------------
drop policy if exists product_sizes_read on public.product_sizes;
create policy product_sizes_read on public.product_sizes
  for select to anon, authenticated using (true);

drop policy if exists product_sizes_write on public.product_sizes;
create policy product_sizes_write on public.product_sizes
  for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- ---------- product_addons --------------------------------------------------
drop policy if exists product_addons_read on public.product_addons;
create policy product_addons_read on public.product_addons
  for select to anon, authenticated using (true);

drop policy if exists product_addons_write on public.product_addons;
create policy product_addons_write on public.product_addons
  for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- ---------- branch_products -------------------------------------------------
drop policy if exists branch_products_read on public.branch_products;
create policy branch_products_read on public.branch_products
  for select to anon, authenticated using (true);

drop policy if exists branch_products_write on public.branch_products;
create policy branch_products_write on public.branch_products
  for all to authenticated
  using (public.can_manage_branch(branch_id))
  with check (public.can_manage_branch(branch_id));

-- ---------- drivers ---------------------------------------------------------
-- Customers can read driver location/phone only for a driver assigned to one of
-- their active orders; drivers read/update their own row; staff manage by branch.
drop policy if exists drivers_self on public.drivers;
create policy drivers_self on public.drivers
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.can_manage_branch(branch_id)
    or exists (
      select 1 from public.orders o
      where o.driver_id = drivers.id and o.user_id = auth.uid()
        and o.status not in ('delivered','cancelled')
    )
  );

drop policy if exists drivers_update_self on public.drivers;
create policy drivers_update_self on public.drivers
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists drivers_staff_write on public.drivers;
create policy drivers_staff_write on public.drivers
  for all to authenticated
  using (public.can_manage_branch(branch_id))
  with check (public.can_manage_branch(branch_id));

-- ---------- orders ----------------------------------------------------------
drop policy if exists orders_customer_select on public.orders;
create policy orders_customer_select on public.orders
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.can_manage_branch(branch_id)
    or driver_id = public.my_driver_id()
    -- unassigned orders available to online drivers of the same branch:
    or (
      driver_id is null
      and status in ('ready','confirmed','preparing')
      and exists (
        select 1 from public.drivers d
        where d.user_id = auth.uid() and d.branch_id = orders.branch_id
      )
    )
  );

-- Customer creates their own order. Server-side (Edge Function) should recompute
-- and overwrite pricing; this policy only guarantees ownership.
drop policy if exists orders_customer_insert on public.orders;
create policy orders_customer_insert on public.orders
  for insert to authenticated
  with check (user_id = auth.uid());

-- Customer may cancel only before preparation starts.
drop policy if exists orders_customer_cancel on public.orders;
create policy orders_customer_cancel on public.orders
  for update to authenticated
  using (user_id = auth.uid() and status in ('pending','confirmed'))
  with check (user_id = auth.uid() and status in ('pending','confirmed','cancelled'));

-- Assigned driver may advance their order status.
drop policy if exists orders_driver_update on public.orders;
create policy orders_driver_update on public.orders
  for update to authenticated
  using (driver_id = public.my_driver_id())
  with check (driver_id = public.my_driver_id());

-- Staff manage orders in their scope.
drop policy if exists orders_staff_all on public.orders;
create policy orders_staff_all on public.orders
  for all to authenticated
  using (public.can_manage_branch(branch_id))
  with check (public.can_manage_branch(branch_id));

-- ---------- order_items -----------------------------------------------------
drop policy if exists order_items_select on public.order_items;
create policy order_items_select on public.order_items
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and (
          o.user_id = auth.uid()
          or public.can_manage_branch(o.branch_id)
          or o.driver_id = public.my_driver_id()
        )
    )
  );

drop policy if exists order_items_insert on public.order_items;
create policy order_items_insert on public.order_items
  for insert to authenticated
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.user_id = auth.uid()
        and o.status = 'pending'
    )
  );

drop policy if exists order_items_staff on public.order_items;
create policy order_items_staff on public.order_items
  for all to authenticated
  using (
    exists (select 1 from public.orders o
            where o.id = order_items.order_id and public.can_manage_branch(o.branch_id))
  )
  with check (
    exists (select 1 from public.orders o
            where o.id = order_items.order_id and public.can_manage_branch(o.branch_id))
  );

-- ---------- order_status_history --------------------------------------------
drop policy if exists status_history_select on public.order_status_history;
create policy status_history_select on public.order_status_history
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_status_history.order_id
        and (o.user_id = auth.uid()
             or public.can_manage_branch(o.branch_id)
             or o.driver_id = public.my_driver_id())
    )
  );
-- Inserts are done by the trigger (security definer); no client insert policy.

-- ---------- promo_codes -----------------------------------------------------
-- Clients should validate promos via an Edge Function, not read the table.
-- Only staff can read/manage. (Validation function uses service role.)
drop policy if exists promo_codes_staff on public.promo_codes;
create policy promo_codes_staff on public.promo_codes
  for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- ---------- promo_usage -----------------------------------------------------
drop policy if exists promo_usage_owner on public.promo_usage;
create policy promo_usage_owner on public.promo_usage
  for select to authenticated
  using (user_id = auth.uid() or public.is_staff());
-- Inserts happen server-side (service role).

-- ---------- reviews ---------------------------------------------------------
drop policy if exists reviews_read on public.reviews;
create policy reviews_read on public.reviews
  for select to anon, authenticated using (true);

drop policy if exists reviews_owner_insert on public.reviews;
create policy reviews_owner_insert on public.reviews
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.orders o
      where o.id = reviews.order_id
        and o.user_id = auth.uid()
        and o.status = 'delivered'
    )
  );

drop policy if exists reviews_staff on public.reviews;
create policy reviews_staff on public.reviews
  for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- ---------- banners ---------------------------------------------------------
drop policy if exists banners_read on public.banners;
create policy banners_read on public.banners
  for select to anon, authenticated using (is_active or public.is_staff());

drop policy if exists banners_write on public.banners;
create policy banners_write on public.banners
  for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- ---------- notifications ---------------------------------------------------
drop policy if exists notifications_owner on public.notifications;
create policy notifications_owner on public.notifications
  for select to authenticated using (user_id = auth.uid());

drop policy if exists notifications_owner_update on public.notifications;
create policy notifications_owner_update on public.notifications
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists notifications_staff on public.notifications;
create policy notifications_staff on public.notifications
  for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- ---------- inventory_items -------------------------------------------------
drop policy if exists inventory_manage on public.inventory_items;
create policy inventory_manage on public.inventory_items
  for all to authenticated
  using (public.can_manage_branch(branch_id))
  with check (public.can_manage_branch(branch_id));

-- ============================================================================
-- Done. Next steps (await approval):
--   * Storage buckets (product/branch images) + storage policies
--   * Edge Functions: price calc, promo validation, payment confirmation
--   * Seed data (countries, sample branches/categories/products)
-- ============================================================================
