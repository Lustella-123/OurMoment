import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';

import '../core/constants.dart';

/// 사랑의 온도 UI. 점수·일일 캡 로직은 Firebase 연동 후 `LoveTemperatureService` 등으로 분리 예정.
class LoveTemperatureCard extends StatelessWidget {
  const LoveTemperatureCard({
    super.key,
    required this.degrees,
    required this.accent,
  });

  final int degrees;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = (degrees.clamp(0, kLoveTemperatureMax) / kLoveTemperatureMax)
        .clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat_rounded, color: accent),
                const SizedBox(width: 8),
                Text(
                  l10n.homeLoveTemperature,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$degrees°',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: accent.withValues(alpha: 0.15),
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeLoveTemperatureHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
