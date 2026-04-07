import 'package:flutter/foundation.dart';

/// 하단 탭 전환 (일기 작성 후 홈 등)
class MainShellController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void setIndex(int i) {
    if (i < 0 || i > 4) return;
    if (_index == i) return;
    _index = i;
    notifyListeners();
  }

  void goHome() => setIndex(0);
}
