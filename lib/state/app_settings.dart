import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

const _kLang = 'settings_language';
const _kBg = 'settings_bg_color';
const _kAccent = 'settings_accent_color';
const _kThemeId = 'settings_theme_id';
const _kPremium = 'settings_premium_stub';
const _kCalShowAnniversaries = 'calendar_show_anniversaries';
const _kCalShowBirthdays = 'calendar_show_birthdays';

class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);

  final SharedPreferences _prefs;

  String _languageCode = 'ko';
  late AppThemePalette _themePalette;

  /// 스토어 연동 전까지 로컬 플래그 (나중에 Firestore·영수증 검증으로 대체)
  bool _premiumLocalStub = false;
  bool _calendarShowAnniversaries = true;
  bool _calendarShowBirthdays = true;

  String get languageCode => _languageCode;
  AppThemePalette get themePalette => _themePalette;
  Color get backgroundColor => _themePalette.background;
  Color get accentColor => _themePalette.accent;
  bool get isPremium => _premiumLocalStub;

  /// 달력에 연애 기념일(100일 단위·주년) 표시
  bool get calendarShowAnniversaries => _calendarShowAnniversaries;

  /// 달력에 생일(유저 문서 birthMonth/birthDay) 표시
  bool get calendarShowBirthdays => _calendarShowBirthdays;

  Future<void> load() async {
    _languageCode = _prefs.getString(_kLang) ?? 'ko';
    final savedThemeId = _prefs.getString(_kThemeId);
    final bg = _prefs.getInt(_kBg);
    final ac = _prefs.getInt(_kAccent);
    if (savedThemeId != null && savedThemeId.isNotEmpty) {
      _themePalette = AppTheme.paletteById(savedThemeId);
    } else if (bg != null || ac != null) {
      // 과거 배경/포인트 저장값이 있으면 가장 가까운 프리셋으로 마이그레이션.
      final oldBg = bg != null ? Color(bg) : AppTheme.defaultPalette.background;
      final oldAccent = ac != null ? Color(ac) : AppTheme.defaultPalette.accent;
      _themePalette = _closestPalette(oldBg, oldAccent);
      await _prefs.setString(_kThemeId, _themePalette.id);
    } else {
      _themePalette = AppTheme.defaultPalette;
    }
    _premiumLocalStub = _prefs.getBool(_kPremium) ?? false;
    _calendarShowAnniversaries =
        _prefs.getBool(_kCalShowAnniversaries) ?? true;
    _calendarShowBirthdays = _prefs.getBool(_kCalShowBirthdays) ?? true;
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    if (code != 'ko' && code != 'en') return;
    _languageCode = code;
    await _prefs.setString(_kLang, code);
    notifyListeners();
  }

  Future<void> setThemeById(String id) async {
    _themePalette = AppTheme.paletteById(id);
    await _prefs.setString(_kThemeId, _themePalette.id);
    // 이전 키는 더 이상 사용하지 않음.
    await _prefs.remove(_kBg);
    await _prefs.remove(_kAccent);
    notifyListeners();
  }

  /// 개발·데모용. 실제 출시 시 구독 영수증 검증 후 제거하거나 서버 연동.
  Future<void> setPremiumLocalStub(bool value) async {
    _premiumLocalStub = value;
    await _prefs.setBool(_kPremium, value);
    notifyListeners();
  }

  Future<void> setCalendarShowAnniversaries(bool value) async {
    _calendarShowAnniversaries = value;
    await _prefs.setBool(_kCalShowAnniversaries, value);
    notifyListeners();
  }

  Future<void> setCalendarShowBirthdays(bool value) async {
    _calendarShowBirthdays = value;
    await _prefs.setBool(_kCalShowBirthdays, value);
    notifyListeners();
  }

  AppThemePalette _closestPalette(Color bg, Color accent) {
    double score(AppThemePalette p) {
      return _distance(bg, p.background) + _distance(accent, p.accent);
    }

    var best = AppTheme.defaultPalette;
    var bestScore = score(best);
    for (final p in AppTheme.palettes.skip(1)) {
      final s = score(p);
      if (s < bestScore) {
        best = p;
        bestScore = s;
      }
    }
    return best;
  }

  double _distance(Color a, Color b) {
    final dr = (a.r - b.r) * 255.0;
    final dg = (a.g - b.g) * 255.0;
    final db = (a.b - b.b) * 255.0;
    return dr * dr + dg * dg + db * db;
  }
}
