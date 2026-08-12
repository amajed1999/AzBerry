/// AzBerry backend configuration.
///
/// The anon/publishable key is safe to ship in client apps (RLS protects data).
/// You can override these at build time with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wpqkvpyvoocoerxjllhu.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_Y2jsTv7NCkmQuYTK_iN-WQ_6VSV7xgy',
  );

  /// Default currency label (Iraqi branches).
  static const currency = 'د.ع';
}
