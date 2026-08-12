import 'translations.dart';

/// Lightweight i18n: the Arabic string is the key. In English mode we look it up
/// in [kEn]; if missing we fall back to the Arabic text (never a blank string).
class AppLocale {
  /// 'ar' or 'en' — set by the app root from the locale provider.
  static String current = 'ar';
  static bool get isEn => current == 'en';
}

/// Translate an Arabic UI string to the active language.
String tr(String ar) => AppLocale.isEn ? (kEn[ar] ?? ar) : ar;
