# 🫐 AzBerry — منصّة توصيل العصائر والمشروبات

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" />
  <img alt="React" src="https://img.shields.io/badge/React-18-61DAFB?logo=react&logoColor=black" />
  <img alt="TypeScript" src="https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript&logoColor=white" />
  <img alt="Vite" src="https://img.shields.io/badge/Vite-5-646CFF?logo=vite&logoColor=white" />
  <img alt="Tailwind CSS" src="https://img.shields.io/badge/Tailwind_CSS-3-06B6D4?logo=tailwindcss&logoColor=white" />
  <img alt="Riverpod" src="https://img.shields.io/badge/Riverpod-2-4B32C3" />
  <img alt="Supabase" src="https://img.shields.io/badge/Supabase-Postgres%20%2B%20RLS-3FCF8E?logo=supabase&logoColor=white" />
  <img alt="Deno" src="https://img.shields.io/badge/Edge_Functions-Deno-000000?logo=deno&logoColor=white" />
  <img alt="Vercel" src="https://img.shields.io/badge/Deploy-Vercel-000000?logo=vercel&logoColor=white" />
</p>

<p align="center">
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-Android%20%C2%B7%20iOS%20%C2%B7%20Web-16A34A" />
  <img alt="RTL" src="https://img.shields.io/badge/RTL-عربي-16A34A" />
  <img alt="Status" src="https://img.shields.io/badge/status-active-success" />
</p>

منصّة توصيل متكاملة لسلسلة محلات عصائر طبيعية، سلاش، سلطات فواكه، مكسات بروتين، ومشروبات طاقة —
تمكّن الزبون من الطلب من أقرب فرع والدفع وتتبّع الطلب لحظياً حتى الاستلام، مع تحكّم كامل عبر لوحة إدارة مركزية.

> **Monorepo** يضم ثلاثة تطبيقات + الباك إند، كلها على مشروع Supabase واحد.

---

## 📦 مكوّنات المنصّة

| المجلد | الوصف | التقنية | الحالة |
|---|---|---|---|
| [`admin-dashboard/`](admin-dashboard) | لوحة التحكم (11 قسماً) | React + TypeScript + Tailwind + Vite | ✅ يعمل |
| [`customer-app/`](customer-app) | تطبيق الزبون | Flutter + Riverpod + go_router | ✅ يعمل |
| [`driver-app/`](driver-app) | تطبيق السائق | Flutter + Riverpod + go_router | ✅ يعمل |
| [`supabase/`](supabase) | مخطط قاعدة البيانات + الدوال | Postgres + RLS + Edge Functions (Deno) | ✅ منشور |

---

## 🏗️ المعمارية

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  تطبيق الزبون  │   │  تطبيق السائق  │   │ لوحة التحكم    │
│   (Flutter)  │   │   (Flutter)  │   │   (React)    │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          ▼
             ┌────────────────────────────┐
             │          Supabase          │
             │  Postgres + RLS  ·  Auth   │
             │  Realtime · Storage        │
             │  Edge Functions (تسعير)    │
             └────────────────────────────┘
```

- **الأمان**: Row Level Security على كل الجداول، بصلاحيات متعددة المستويات
  (زبون / سائق / كاشير / مدير فرع / مدير دولة / مدير عام).
- **التسعير الآمن**: يُحسب حصراً في الخادم عبر Edge Function `place-order`
  (العميل لا يرسل أسعاراً — يُعاد حساب كل شيء من قاعدة البيانات).
- **لحظي**: تتبّع حالة الطلب عبر Supabase Realtime.

---

## ✨ أبرز المزايا

### تطبيق الزبون
اختيار الفرع الأقرب · تصفّح الأصناف والبحث · تخصيص المنتج (حجم/إضافات/سكر/ثلج) ·
السلة والدفع (7 طرق) · اختيار عنوان التوصيل · كود الخصم · تتبّع الطلب لحظياً ·
العناوين · المفضلة · تقييم الطلبات · نقاط الولاء.

### تطبيق السائق
دخول للسائقين · مفتاح متصل/غير متصل · الطلبات المتاحة وقبولها ·
تفاصيل الطلب والعنوان والزبون · تحديث الحالة (بالطريق/تسليم) · ملخّص يومي (طلبات/أرباح/نقد).

### لوحة التحكم (11 قسماً)
الرئيسية · الطلبات الحية (Realtime + تنبيه صوتي) · المنتجات · الأصناف · الفروع ·
السائقون · الزبائن (حظر/نقاط) · أكواد الخصم · المخزون (تنبيه نقص) · التقارير (تصدير Excel/PDF) · البانرات.
مع رفع الصور إلى Supabase Storage.

---

## 🗄️ قاعدة البيانات

20+ جدولاً مع علاقات وفهارس وسياسات RLS، أبرزها:
`countries · branches · categories · products · product_sizes · product_addons ·
branch_products · users · addresses · favorites · orders · order_items ·
order_status_history · drivers · promo_codes · reviews · banners · inventory_items`.

المخطط الكامل في [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql).

### Edge Functions
- **`place-order`** — مسار الدفع الآمن: يعيد حساب الأسعار والضريبة والخصم ويتحقق من الحد الأدنى وينشئ الطلب.
- **`validate-promo`** — معاينة كود الخصم في السلة.

التفاصيل في [`supabase/functions/README.md`](supabase/functions/README.md).

---

## 🚀 التشغيل محلياً

### لوحة التحكم
```bash
cd admin-dashboard
npm install
npm run dev            # http://localhost:5173
```

### تطبيق الزبون / السائق
```bash
cd customer-app        # أو driver-app
flutter pub get
flutter run            # جهاز/محاكي، أو: flutter run -d chrome
```

> مفاتيح Supabase العامة مضمّنة كقيم افتراضية، أو مرّرها عبر `--dart-define` /
> متغيّرات البيئة. لا يُخزَّن مفتاح `service_role` في أي عميل.

---

## ☁️ النشر

كل التفاصيل في [`DEPLOYMENT.md`](DEPLOYMENT.md):
- **لوحة التحكم** → Vercel (الإعداد جاهز في `admin-dashboard/vercel.json`).
- **تطبيقا Flutter** → Google Play / App Store (توقيع أندرويد مُعدّ)، أو الويب.

---

## 🔑 حسابات الاختبار

| الدور | الدخول |
|---|---|
| مدير عام (لوحة التحكم) | `admin@azberry.com` / `Azberry#2026` |
| زبون | `cust1@test.com` / `Test#1234` |
| سائق | `driver1@test.com` / `Test#1234` |

---

## 🧩 متطلبات إعداد أصلية (خارج البرمجة)

قبل إطلاق المتاجر تحتاج إعداد حسابات/مفاتيح المنصّات:
مزوّد SMS لرمز OTP · تسجيل Google/Apple · مفاتيح Google Maps ·
إشعارات FCM · بوّابات الدفع (ZainCash / FastPay / Qi Card…) · أيقونات وسياسة خصوصية.

---

<sub>🤖 بُنيت هذه المنصّة بمساعدة [Claude Code](https://claude.com/claude-code).</sub>
