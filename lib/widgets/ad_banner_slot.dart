import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../state/app_settings.dart';

/// Google 테스트 배너 단위. 출시 전 AdMob에서 발급한 단위 ID로 교체하세요.
String get _bannerAdUnitId {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ca-app-pub-3940256099942544/2934735716';
    case TargetPlatform.android:
      return 'ca-app-pub-3940256099942544/6300978111';
    default:
      return 'ca-app-pub-3940256099942544/2934735716';
  }
}

class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _failed = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.settings.isPremium) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant AdBannerSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.isPremium != widget.settings.isPremium) {
      if (widget.settings.isPremium) {
        final old = _ad;
        _ad = null;
        if (old != null) unawaited(old.dispose());
        _loaded = false;
        _failed = false;
      } else {
        _failed = false;
        _load();
      }
    }
  }

  void _load() {
    final old = _ad;
    _ad = null;
    if (old != null) {
      unawaited(old.dispose());
    }
    _failed = false;
    _loaded = false;
    _loading = true;
    final ad = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _loaded = true;
            _loading = false;
          });
        },
        onAdFailedToLoad: (ad, err) {
          unawaited(ad.dispose());
          debugPrint('Banner failed: $err');
          if (mounted) {
            setState(() {
              _failed = true;
              _ad = null;
              _loaded = false;
              _loading = false;
            });
          }
        },
      ),
    );
    unawaited(ad.load());
    _ad = ad;
  }

  @override
  void dispose() {
    final ad = _ad;
    if (ad != null) unawaited(ad.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.settings.isPremium) return const SizedBox.shrink();
    if (_failed) return const SizedBox.shrink();
    final h = _loaded && _ad != null ? _ad!.size.height.toDouble() : 0.0;
    if (h <= 0) {
      return _loading
          ? SizedBox(
              height: 50,
              child: Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink();
    }
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: h,
      child: AdWidget(ad: _ad!),
    );
  }
}
