import 'package:flutter/foundation.dart';

final class SettingsController extends ChangeNotifier {
  bool _highContrast = false;
  double _captionScale = 1.15;
  double _speechRate = 0.5;
  bool _ttsEnabled = true;
  bool _captionsEnabled = true;

  bool get highContrast => _highContrast;
  double get captionScale => _captionScale;
  double get speechRate => _speechRate;
  bool get ttsEnabled => _ttsEnabled;
  bool get captionsEnabled => _captionsEnabled;

  void setHighContrast(bool value) {
    if (value == _highContrast) return;
    _highContrast = value;
    notifyListeners();
  }

  void setCaptionScale(double value) {
    final next = value.clamp(0.9, 2.2);
    if (next == _captionScale) return;
    _captionScale = next;
    notifyListeners();
  }

  void setSpeechRate(double value) {
    final next = value.clamp(0.1, 1.0);
    if (next == _speechRate) return;
    _speechRate = next;
    notifyListeners();
  }

  void setTtsEnabled(bool value) {
    if (value == _ttsEnabled) return;
    _ttsEnabled = value;
    notifyListeners();
  }

  void setCaptionsEnabled(bool value) {
    if (value == _captionsEnabled) return;
    _captionsEnabled = value;
    notifyListeners();
  }
}
