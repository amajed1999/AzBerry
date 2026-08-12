import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/i18n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    // Our key is a publishable key (sb_publishable_...).
    publishableKey: AppConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: AzBerryApp()));
}

class AzBerryApp extends ConsumerWidget {
  const AzBerryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final lang = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'AzBerry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: appRouter,
      locale: Locale(lang),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Set the global palette + language BEFORE pages paint (they read these
        // via AppColors.mode / tr()), so everything updates in the same frame.
        AppColors.mode = Theme.of(context).brightness;
        AppLocale.current = lang;
        return Directionality(
          textDirection: lang == 'en' ? TextDirection.ltr : TextDirection.rtl,
          // Re-inflate the page subtree when the language changes so that even
          // const widgets (which don't rebuild on their own) re-evaluate tr().
          child: KeyedSubtree(key: ValueKey(lang), child: child!),
        );
      },
    );
  }
}
