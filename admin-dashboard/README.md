# AzBerry — لوحة التحكم (Admin Dashboard)

لوحة تحكم React + TypeScript + Tailwind متصلة بمشروع Supabase الخاص بـ AzBerry.
مشروع مستقل تماماً عن أي مشروع آخر في مجلد Downloads.

## المزايا الحالية
- 🔐 تسجيل دخول (Supabase Auth) + حماية المسارات حسب الدور (staff فقط).
- 📊 الرئيسية: مبيعات اليوم، عدد الطلبات، الطلبات النشطة، متوسط قيمة الطلب.
- 🟢 **الطلبات الحية (Realtime)**: لوحة أعمدة حسب الحالة، تنبيه صوتي عند طلب جديد،
  فلترة حسب الفرع، تقديم حالة الطلب أو إلغاؤه. (زر "طلب تجريبي" لاختبار الـ Realtime.)
- 📦 **إدارة المنتجات**: إضافة/تعديل، فلترة وبحث، تفعيل/إيقاف منتج.

## التشغيل

```bash
npm install
npm run dev
```

ثم افتح http://localhost:5173

> بيانات الاتصال موجودة في `.env.local` (مفتاح publishable عام آمن للعميل).

## إنشاء أول حساب مدير (Super Admin)

لوحة التحكم تتطلب حساباً بدور إداري. الخطوات:

1. أنشئ مستخدماً في: Supabase Dashboard → **azberry** → Authentication → Users → **Add user**
   (بريد + كلمة مرور، وفعّل Auto Confirm).
2. رقِّه إلى مدير عام عبر SQL Editor:

```sql
update public.users
set role = 'super_admin'
where email = 'admin@azberry.com';  -- ضع بريدك
```

3. سجّل الدخول باللوحة بنفس البريد وكلمة المرور.

## البنية
```
src/
  lib/         supabase client, types, utils, constants
  context/     AuthContext (session + profile + role)
  components/  Layout, Sidebar, ProtectedRoute, ui/primitives
  pages/       Login, Dashboard, LiveOrders, Products
```

## ملاحظات
- الأسعار بالدينار العراقي (IQD) في البيانات التجريبية.
- العمليات الحساسة (تسعير الطلب، الدفع، النقاط) ستمر عبر Edge Functions لاحقاً.
- الوضع من اليمين لليسار (RTL) وخط Cairo مفعّلان افتراضياً.
