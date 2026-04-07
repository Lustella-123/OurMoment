import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'our_moment_splash_layout.dart';

/// `main()` 초기화 전·중 표시 (로케일 로드 전이라 짧은 기본 문구).
class AppStartupSplash extends StatelessWidget {
  const AppStartupSplash({
    super.key,
    required this.palette,
  });

  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OurMomentSplashLayout(palette: palette),
    );
  }
}
