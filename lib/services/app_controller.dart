import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'call_models.dart';
import 'haptics_service.dart';
import 'settings_controller.dart';
import 'tts_service.dart';

final class AppController extends ChangeNotifier {
  AppController() {
    settings.addListener(notifyListeners);
    _tts = TtsService(settings);
    _haptics = HapticsService();
  }

  final SettingsController settings = SettingsController();
  late final TtsService _tts;
  late final HapticsService _haptics;

  CallPhase _phase = CallPhase.idle;
  CallPhase get phase => _phase;

  bool _muted = false;
  bool get muted => _muted;

  bool _speakerOn = true;
  bool get speakerOn => _speakerOn;

  String _remoteName = 'Alex';
  String get remoteName => _remoteName;

  CallEndReason? _endReason;
  CallEndReason? get endReason => _endReason;

  final List<CaptionLine> _captions = <CaptionLine>[];
  List<CaptionLine> get captions => List.unmodifiable(_captions);

  final List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Timer? _ticker;
  final _rng = Random();

  Future<void> init() async {
    await _tts.init();
  }

  void startOutgoingCall({String remoteName = 'Alex'}) {
    _remoteName = remoteName;
    _endReason = null;
    _muted = false;
    _speakerOn = true;
    _captions.clear();
    _messages.clear();
    _setPhase(CallPhase.outgoingDialing);

    _ticker?.cancel();
    _ticker = Timer(const Duration(seconds: 2), () {
      _setPhase(CallPhase.connecting);
      _ticker = Timer(const Duration(seconds: 1), () {
        _setPhase(CallPhase.inCall);
        unawaited(_haptics.connected());
        unawaited(SystemSound.play(SystemSoundType.click));
        unawaited(_tts.speak('Call connected'));
        _startMockCaptionStream();
      });
    });
  }

  void simulateIncomingCall({String remoteName = 'Alex'}) {
    _remoteName = remoteName;
    _endReason = null;
    _muted = false;
    _speakerOn = true;
    _captions.clear();
    _messages.clear();
    _setPhase(CallPhase.incomingRinging);
    unawaited(_haptics.incomingCall());
    unawaited(SystemSound.play(SystemSoundType.alert));
    unawaited(_tts.speak('Incoming call from $_remoteName'));
  }

  void answerIncoming() {
    if (_phase != CallPhase.incomingRinging) return;
    _setPhase(CallPhase.connecting);
    _ticker?.cancel();
    _ticker = Timer(const Duration(milliseconds: 900), () {
      _setPhase(CallPhase.inCall);
      unawaited(_haptics.connected());
      unawaited(SystemSound.play(SystemSoundType.click));
      unawaited(_tts.speak('Call connected'));
      _startMockCaptionStream();
    });
  }

  void rejectIncoming() {
    if (_phase != CallPhase.incomingRinging) return;
    _endReason = CallEndReason.rejected;
    _setPhase(CallPhase.ended);
    _stopMockCaptionStream();
    unawaited(_haptics.ended());
    unawaited(SystemSound.play(SystemSoundType.alert));
    unawaited(_tts.speak('Call rejected'));
  }

  void endCall({CallEndReason reason = CallEndReason.localHangup}) {
    if (_phase == CallPhase.idle || _phase == CallPhase.ended) return;
    _endReason = reason;
    _setPhase(CallPhase.ended);
    _stopMockCaptionStream();
    unawaited(_haptics.ended());
    unawaited(SystemSound.play(SystemSoundType.alert));
    unawaited(_tts.speak('Call ended'));
  }

  void resetToIdle() {
    _endReason = null;
    _captions.clear();
    _messages.clear();
    _setPhase(CallPhase.idle);
  }

  void toggleMute() {
    _muted = !_muted;
    notifyListeners();
    unawaited(SystemSound.play(SystemSoundType.click));
    unawaited(_tts.speak(_muted ? 'Microphone muted' : 'Microphone unmuted'));
  }

  void toggleSpeaker() {
    _speakerOn = !_speakerOn;
    notifyListeners();
    unawaited(SystemSound.play(SystemSoundType.click));
    unawaited(_tts.speak(_speakerOn ? 'Speaker on' : 'Earpiece on'));
  }

  void sendChat(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      from: 'You',
      text: trimmed,
      timestamp: DateTime.now(),
      wasSpoken: false,
    );
    _messages.add(msg);
    notifyListeners();
    unawaited(_tts.speak(trimmed));
  }

  ChatMessage? get lastMessage =>
      _messages.isEmpty ? null : _messages.last;

  String? get lastMessageText => lastMessage?.text;

  Future<void> readLastMessage() async {
    final text = lastMessageText;
    if (text == null || text.trim().isEmpty) return;
    await _tts.speak('Last message: $text');
  }

  void _setPhase(CallPhase next) {
    if (next == _phase) return;
    _phase = next;
    notifyListeners();
  }

  void _startMockCaptionStream() {
    if (_captions.isNotEmpty) return;

    const seed = <String>[
      'Hey, can you hear me?',
      'I’ll read captions on my side.',
      'If you type, I can speak it out loud.',
      'Let’s keep this accessible for everyone.',
      'One second—checking something.',
      'Got it. Thanks.',
    ];
    final speakerChoices = <String?>['Alex', 'You', null];

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (_phase != CallPhase.inCall) return;
      if (!settings.captionsEnabled) return;

      final speaker = speakerChoices[_rng.nextInt(speakerChoices.length)];
      final line = seed[_rng.nextInt(seed.length)];

      // Simulate partial -> final updates by occasionally emitting a partial first.
      final emitPartial = _rng.nextBool();
      if (emitPartial) {
        _captions.add(
          CaptionLine(
            text: _partial(line),
            isPartial: true,
            timestamp: DateTime.now(),
            speakerLabel: speaker,
          ),
        );
      }
      _captions.add(
        CaptionLine(
          text: line,
          isPartial: false,
          timestamp: DateTime.now(),
          speakerLabel: speaker,
        ),
      );

      // Keep the buffer bounded for UI performance.
      if (_captions.length > 80) {
        _captions.removeRange(0, _captions.length - 80);
      }
      notifyListeners();
    });
  }

  void _stopMockCaptionStream() {
    _ticker?.cancel();
    _ticker = null;
  }

  String _partial(String full) {
    final cut = max(3, min(full.length - 1, 3 + _rng.nextInt(10)));
    return '${full.substring(0, cut)}…';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    settings.removeListener(notifyListeners);
    settings.dispose();
    unawaited(_tts.stop());
    super.dispose();
  }
}

