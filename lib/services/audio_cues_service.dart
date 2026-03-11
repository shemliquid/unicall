import 'package:audioplayers/audioplayers.dart';

final class AudioCuesService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> dispose() async {
    await _player.dispose();
  }

  Future<void> playIncoming() async {
    await _beep();
  }

  Future<void> playConnected() async {
    await _beep();
  }

  Future<void> playEnded() async {
    await _beep();
  }

  Future<void> _beep() async {
    // UI prototype: keep this simple and dependency-free (no bundled assets yet).
    //
    // Many teams swap this for short earcon assets in `assets/` once UX settles.
    await _player.stop();
  }
}

