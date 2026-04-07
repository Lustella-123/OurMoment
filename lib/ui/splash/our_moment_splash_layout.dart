import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 앱 시작·인증 대기 시 공통 비주얼 (그라데이션 + 하트 + 로딩).
class OurMomentSplashLayout extends StatelessWidget {
  const OurMomentSplashLayout({
    super.key,
    required this.palette,
    this.showStatusText = false,
    this.statusText,
  });

  final AppThemePalette palette;
  final bool showStatusText;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: ThemeData.estimateBrightnessForColor(palette.c1) == Brightness.dark
              ? Colors.white
              : const Color(0xFF2D2D2D),
        );
    final subStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ThemeData.estimateBrightnessForColor(palette.c2) == Brightness.dark
              ? Colors.white70
              : const Color(0xFF6B5B63),
          height: 1.35,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.c1,
            palette.c2,
            palette.c3,
            palette.c4.withValues(alpha: 0.92),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.55),
                    boxShadow: [
                      BoxShadow(
                        color: palette.c4.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 56,
                    color: palette.c4,
                  ),
                ),
                const SizedBox(height: 28),
                Text('Our moment', style: titleStyle),
                if (showStatusText && statusText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    statusText!,
                    textAlign: TextAlign.center,
                    style: subStyle,
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: palette.c4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
