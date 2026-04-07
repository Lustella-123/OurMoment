import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'auth_wrapper.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';

class OurMomentApp extends StatelessWidget {
  const OurMomentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, _) {
        return MaterialApp(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(palette: settings.themePalette),
          darkTheme: AppTheme.dark(palette: settings.themePalette),
          themeMode: ThemeMode.system,
          locale: Locale(settings.languageCode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
