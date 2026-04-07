import 'package:flutter/material.dart';

class AppThemePalette {
  const AppThemePalette({
    required this.id,
    required this.name,
    required this.c1,
    required this.c2,
    required this.c3,
    required this.c4,
  });

  final String id;
  final String name;
  final Color c1;
  final Color c2;
  final Color c3;
  final Color c4;

  Color get background => c1;
  Color get accent => c4;
}

class AppTheme {
  AppTheme._();

  static const List<AppThemePalette> palettes = [
    AppThemePalette(
      id: 'mono_white',
      name: 'Mono',
      c1: Color(0xFFFFFFFF),
      c2: Color(0xFFF7F7F7),
      c3: Color(0xFFEDEDED),
      c4: Color(0xFFFF7FA0),
    ),
    AppThemePalette(
      id: 'main',
      name: '메인 핑크',
      c1: Color(0xFFFFF5E4),
      c2: Color(0xFFFFE3E1),
      c3: Color(0xFFFFD1D1),
      c4: Color(0xFFFF9494),
    ),
    AppThemePalette(
      id: 'rose_mist',
      name: '로즈 핑크',
      c1: Color(0xFFF9F5F6),
      c2: Color(0xFFF8E8EE),
      c3: Color(0xFFFDCEDF),
      c4: Color(0xFFF2BED1),
    ),
    AppThemePalette(
      id: 'olive_garden',
      name: '올리브 그린',
      c1: Color(0xFFEDF1D6),
      c2: Color(0xFF9DC08B),
      c3: Color(0xFF609966),
      c4: Color(0xFF40513B),
    ),
    AppThemePalette(
      id: 'aqua_breeze',
      name: '아쿠아 블루',
      c1: Color(0xFFE3FDFD),
      c2: Color(0xFFCBF1F5),
      c3: Color(0xFFA6E3E9),
      c4: Color(0xFF71C9CE),
    ),
    AppThemePalette(
      id: 'indigo_dream',
      name: '인디고 바이올렛',
      c1: Color(0xFFF4EEFF),
      c2: Color(0xFFDCD6F7),
      c3: Color(0xFFA6B1E1),
      c4: Color(0xFF424874),
    ),
    AppThemePalette(
      id: 'sunset_coral',
      name: '선셋 코랄',
      c1: Color(0xFFFFF1EC),
      c2: Color(0xFFFFE0D6),
      c3: Color(0xFFFFC2B8),
      c4: Color(0xFFFD7F6F),
    ),
    AppThemePalette(
      id: 'sky_lilac',
      name: '스카이 라일락',
      c1: Color(0xFFF7F6FF),
      c2: Color(0xFFE8E6FF),
      c3: Color(0xFFD2CCFF),
      c4: Color(0xFF7F7FD5),
    ),
    AppThemePalette(
      id: 'mint_soda',
      name: '민트 소다',
      c1: Color(0xFFF2FFFA),
      c2: Color(0xFFDDF9EE),
      c3: Color(0xFFB9F0DA),
      c4: Color(0xFF39B185),
    ),
  ];

  static AppThemePalette get defaultPalette => palettes.first;

  static AppThemePalette paletteById(String? id) {
    return palettes.firstWhere((p) => p.id == id, orElse: () => defaultPalette);
  }

  static ThemeData light({required AppThemePalette palette}) {
    final background = palette.background;
    final accent = palette.accent;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: background,
          primary: accent,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          surfaceTint: Colors.transparent,
          secondary: palette.c3,
          tertiary: palette.c2,
        );

    final outline = scheme.outline.withValues(alpha: 0.35);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: palette.c1,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Color.lerp(palette.c1, palette.c2, 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color.lerp(palette.c1, palette.c2, 0.35),
        indicatorColor: palette.c3.withValues(alpha: 0.42),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.lerp(palette.c1, palette.c2, 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark({required AppThemePalette palette}) {
    final accent = palette.accent;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          primary: accent,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          surfaceTint: Colors.transparent,
          secondary: palette.c3.withValues(alpha: 0.85),
          tertiary: palette.c2.withValues(alpha: 0.7),
        );

    final outline = scheme.outline.withValues(alpha: 0.45);
    final bg = Color.lerp(Colors.black, scheme.surface, 0.7)!;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: bg,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Color.lerp(scheme.surface, scheme.surfaceContainerHigh, 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color.lerp(
          scheme.surfaceContainerLow,
          scheme.surfaceContainer,
          0.5,
        ),
        indicatorColor: scheme.primary.withValues(alpha: 0.34),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.75),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
