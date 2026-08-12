# AzBerry — تطبيق الزبون (Flutter)

تطبيق الزبون لطلب العصائر والمشروبات، متصل بنفس مشروع Supabase الخاص بـ AzBerry.
مشروع مستقل تماماً داخل `azberry/customer-app/`.

## التقنيات
- **Flutter 3.x** + Dart
- **Riverpod** لإدارة الحالة
- **go_router** للتنقّل
- **supabase_flutter** للباك إند
- RTL عربي كامل + خط **Cairo** (google_fonts)

## الشاشات المنجزة (المرحلة الأولى)
| الشاشة | الملف |
|---|---|
| تسجيل الدخول (هاتف + OTP + تصفّح كضيف) | `features/auth/presentation/login_screen.dart` |
| الرئيسية (اختيار الفرع، الأصناف، البحث، شبكة المنتجات، شارة السلة) | `features/home/…` |
| المنتج (الحجم، الإضافات، السكر/الثلج، ملاحظات، السعر الحيّ) | `features/product/…` |
| السلة والدفع (الكميات، نوع الطلب، طرق الدفع، الملخّص) | `features/cart/…` |
| تتبّع الطلب (خط زمني للحالة + Realtime) | `features/tracking/…` |
| الحساب (سجل الطلبات + خروج) | `features/profile/…` |

## البنية (Clean-ish Architecture)
```
lib/
  core/      config, theme, router, utils
  data/      models, repositories
  providers/ Riverpod providers (state)
  features/  <feature>/presentation/…
```

## التشغيل
```bash
flutter pub get
flutter run          # على محاكي/جهاز
# أو للويب:
flutter run -d chrome
```

يمكن تمرير مفاتيح مختلفة وقت التشغيل:
```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## ما يحتاج إعداداً إضافياً (خارج الكود)
- **رمز OTP عبر SMS**: يتطلب تفعيل مزوّد رسائل في Supabase (Auth → Providers → Phone،
  مثل OTPIQ/Twilio). بدونه يعمل زر «تصفّح كضيف» والتصفّح فقط، ولا يُرسَل رمز فعلي.
- **Google / Apple Sign-In**: يتطلب إعداداً أصلياً (OAuth client + معرّفات المنصّات) —
  مُخطّط له ولم يُنفَّذ في هذه المرحلة.
- **خرائط Google**: لاختيار العنوان وتتبّع السائق — مرحلة لاحقة.

## ملاحظات
- تسعير الطلب هنا يُحسب في العميل مؤقتاً (MVP). في الإنتاج يجب أن تعيد **Edge Function**
  حساب السعر/الضريبة/الخصم بمفتاح الخدمة (الخطوة 5).
- إتمام الطلب يتطلب تسجيل دخول (سياسات RLS تشترط `user_id = auth.uid()`).
- تم التحقق: `flutter analyze` → No issues، و`flutter build web` → نجح.
