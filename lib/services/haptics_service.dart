import 'package:vibration/vibration.dart';

final class HapticsService {
  Future<void> incomingCall() async {
    final has = await Vibration.hasVibrator();
    if (has != true) return;
    await Vibration.vibrate(pattern: [0, 250, 120, 250, 120, 250]);
  }

  Future<void> connected() async {
    final has = await Vibration.hasVibrator();
    if (has != true) return;
    await Vibration.vibrate(duration: 80);
  }

  Future<void> ended() async {
    final has = await Vibration.hasVibrator();
    if (has != true) return;
    await Vibration.vibrate(pattern: [0, 120, 80, 120]);
  }
}
