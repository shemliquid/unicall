import 'package:flutter_tts/flutter_tts.dart';

import 'settings_controller.dart';

final class TtsService {
  TtsService(this._settings);

  final SettingsController _settings;
  final FlutterTts _tts = FlutterTts();

  Future<void> init() async {
    await _tts.setSpeechRate(_settings.speechRate);
    await _tts.setQueueMode(1);
  }

  Future<void> applySettings() async {
    await _tts.setSpeechRate(_settings.speechRate);
  }

  Future<void> speak(String text) async {
    if (!_settings.ttsEnabled) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await applySettings();
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
