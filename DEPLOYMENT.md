# AzBerry — دليل النشر (Deployment)

ثلاثة تطبيقات على مشروع Supabase واحد (`azberry`, ref `wpqkvpyvoocoerxjllhu`):

| التطبيق | التقنية | هدف النشر |
|---|---|---|
| `admin-dashboard/` | React + Vite | **Vercel** (ويب) |
| `customer-app/` | Flutter | **Google Play / App Store** (+ ويب اختياري) |
| `driver-app/` | Flutter | **Google Play / App Store** (+ ويب اختياري) |

الباك إند (قاعدة البيانات + RLS + Edge Functions + Storage) **منشور ويعمل بالفعل** على Supabase Cloud.

---

## 1) لوحة التحكم → Vercel

الإعداد جاهز في [`admin-dashboard/vercel.json`](admin-dashboard/vercel.json) (framework=vite، إعادة توجيه SPA).

### عبر واجهة Vercel
1. ادفع المجلد `admin-dashboard/` إلى مستودع Git (GitHub/GitLab).
2. Vercel → New Project → استورد المستودع، واضبط **Root Directory = `admin-dashboard`**.
3. أضف متغيّرات البيئة (Settings → Environment Variables):
   - `VITE_SUPABASE_URL` = `https://wpqkvpyvoocoerxjllhu.supabase.co`
   - `VITE_SUPABASE_ANON_KEY` = `sb_publishable_Y2jsTv7NCkmQuYTK_iN-WQ_6VSV7xgy`
4. Deploy. (Vercel يكتشف Vite تلقائياً: build=`npm run build`, output=`dist`.)

### عبر Vercel CLI
```bash
cd admin-dashboard
npm i -g vercel
vercel --prod
```

> المفتاح `anon/publishable` عام وآمن للعميل (RLS يحمي البيانات). لا تضع مفتاح `service_role` في الويب أبداً.

### بديل: Cloudflare Pages / Netlify
- Build command: `npm run build` — Output: `dist`
- أضف قاعدة إعادة توجيه SPA: كل المسارات → `/index.html` (موجودة في `vercel.json`، وفي Netlify تُضاف عبر `_redirects`).

---

## 2 و 3) تطبيقا Flutter (الزبون والسائق)

نفس الخطوات لكلا المجلدين (`customer-app/`, `driver-app/`).

### تمرير مفاتيح Supabase
القيم الافتراضية مضمّنة في `lib/core/config/app_config.dart`، أو مرّرها وقت البناء:
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://wpqkvpyvoocoerxjllhu.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_Y2jsTv7NCkmQuYTK_iN-WQ_6VSV7xgy
```

### معرّفات التطبيقات (applicationId)
- الزبون: `com.azberry.customer`
- السائق: `com.azberry.driver`

### أندرويد — التوقيع للإصدار (Release signing)
1. أنشئ keystore (مرة واحدة، احتفظ به بأمان):
   ```bash
   keytool -genkey -v -keystore azberry-customer.jks -keyalg RSA -keysize 2048 -validity 10000 -alias azberry
   ```
2. انسخ `android/key.properties.example` → `android/key.properties` واملأ القيم وضع مسار الـ`.jks`.
3. `build.gradle.kts` **مُعدّ مسبقاً**: يستخدم التوقيع الحقيقي عند وجود `key.properties`، ويتراجع لتوقيع debug إن لم يوجد (كي لا ينكسر البناء).
4. ابنِ حزمة النشر:
   ```bash
   flutter build appbundle --release   # ملف .aab لـ Google Play
   flutter build apk --release         # ملف .apk للتوزيع المباشر
   ```
   الناتج: `build/app/outputs/bundle/release/app-release.aab`

> ⚠️ لا ترفع `key.properties` ولا ملف `.jks` إلى Git (مضافة في `.gitignore`).

### iOS (يتطلب macOS + Xcode)
```bash
flutter build ipa --release
```
ثم الرفع عبر Xcode/Transporter إلى App Store Connect. يتطلب حساب Apple Developer + شهادات + Provisioning Profiles.

### الويب (اختياري — لكلا التطبيقين)
```bash
flutter build web --release
```
انشر مجلد `build/web` على Vercel/Netlify/Cloudflare Pages (static).

---

## متطلبات متبقية قبل نشر المتاجر (إعداد أصلي)
هذه ليست برمجة بل حسابات/مفاتيح/إعدادات منصّة:
- **مزوّد SMS** لرمز OTP (Supabase Auth → Phone provider، مثل OTPIQ).
- **Google / Apple Sign-In**: OAuth clients + إعدادات المنصّات.
- **Google Maps** SDK: مفاتيح لاختيار العنوان وتتبّع السائق.
- **FCM** للإشعارات.
- **بوّابات الدفع**: ZainCash / FastPay / Qi… (عقود ومفاتيح).
- أيقونات التطبيق وصور المتجر وسياسة الخصوصية (مطلوبة للقبول).

## حسابات الاختبار
- مدير لوحة التحكم: `admin@azberry.com` / `Azberry#2026`
- زبون: `cust1@test.com` / `Test#1234`
- سائق: `driver1@test.com` / `Test#1234`
