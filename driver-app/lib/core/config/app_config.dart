/// AzBerry driver-app backend configuration (shares the same Supabase project).
class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wpqkvpyvoocoerxjllhu.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_Y2jsTv7NCkmQuYTK_iN-WQ_6VSV7xgy',
  );
  static const currency = 'د.ع';
}
