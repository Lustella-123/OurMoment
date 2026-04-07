import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/our_moment_app.dart';
import 'firebase_options.dart';
import 'services/auth_repository.dart';
import 'services/calendar_events_repository.dart';
import 'services/couple_repository.dart';
import 'services/moments_repository.dart';
import 'services/todos_repository.dart';
import 'services/user_repository.dart';
import 'state/app_settings.dart';
import 'state/main_shell_controller.dart';
import 'theme/app_theme.dart';
import 'ui/splash/app_startup_splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? bootstrapError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
  } catch (e) {
    bootstrapError = '초기 연결에 실패했습니다. 네트워크를 확인해 주세요.';
    debugPrint('main firebase init failed: $e');
  }
  runApp(_BootstrapRoot(startupError: bootstrapError));
}

class _BootstrapRoot extends StatefulWidget {
  const _BootstrapRoot({this.startupError});

  final String? startupError;

  @override
  State<_BootstrapRoot> createState() => _BootstrapRootState();
}

class _BootstrapRootState extends State<_BootstrapRoot> {
  Widget? _ready;
  AppThemePalette _startupPalette = AppTheme.defaultPalette;
  String? _startupError;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    _startupError = widget.startupError;
    unawaited(_init());
  }

  Future<void> _init() async {
    if (_initializing) return;
    setState(() => _initializing = true);
    try {
      final startedAt = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      final settings = AppSettings(prefs);
      await settings.load();
      if (mounted) {
        setState(() => _startupPalette = settings.themePalette);
      }

      await initializeDateFormatting('ko');
      await initializeDateFormatting('en');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 8));
      }

      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        debugPrint('MobileAds.initialize 실패: $e');
      }

      final elapsed = DateTime.now().difference(startedAt);
      final remain = const Duration(seconds: 2) - elapsed;
      if (remain > Duration.zero) {
        await Future<void>.delayed(remain);
      }

      if (!mounted) return;
      setState(() {
        _startupError = null;
        _ready = MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider(create: (_) => MainShellController()),
            Provider(create: (_) => AuthRepository()),
            Provider(create: (_) => UserRepository()),
            Provider(create: (_) => CoupleRepository()),
            Provider(create: (_) => MomentsRepository()),
            Provider(create: (_) => CalendarEventsRepository()),
            Provider(create: (_) => TodosRepository()),
          ],
          child: const OurMomentApp(),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _startupError = '연결이 불안정합니다. 잠시 후 다시 시도해 주세요.';
      });
      debugPrint('앱 초기화 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 42),
                  const SizedBox(height: 10),
                  Text(_startupError!, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _initializing ? null : () => unawaited(_init()),
                    child: _initializing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_ready == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AppStartupSplash(palette: _startupPalette),
      );
    }
    return _ready!;
  }
}
