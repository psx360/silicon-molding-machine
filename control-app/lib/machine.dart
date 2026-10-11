import 'package:flutter/foundation.dart';

/// Visual simulation only. A future BLE transport supplies measured state.
class Machine extends ChangeNotifier {
  double angleA = 0, angleB = 0, mixerPhase = 0;
  int _directionA = 0, _directionB = 0;
  bool mixing = false;
  static const degreesPerSecond = 30.0;

  void hold(String cup, int direction) {
    if (cup == 'A') {
      _directionA = direction;
    } else {
      _directionB = direction;
    }
  }

  void release(String cup) => hold(cup, 0);

  void toggleMixer() {
    mixing = !mixing;
    notifyListeners();
  }

  void stop() {
    _directionA = _directionB = 0;
    mixing = false;
    notifyListeners();
  }

  void advance(double seconds) {
    final a = (angleA + _directionA * degreesPerSecond * seconds).clamp(
      0.0,
      90.0,
    );
    final b = (angleB + _directionB * degreesPerSecond * seconds).clamp(
      0.0,
      90.0,
    );
    if (a == angleA && b == angleB && !mixing) return;
    angleA = a;
    angleB = b;
    if (mixing) mixerPhase = (mixerPhase + seconds * 2) % 1;
    notifyListeners();
  }
}
