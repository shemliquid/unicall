import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call_models.dart';
import 'haptics_service.dart';
import 'signaling/firebase_signaling.dart';
import 'stt/caption_engine_sherpa.dart';
import 'stt/sherpa_model_loader.dart';
import 'settings_controller.dart';
import 'tts_service.dart';
import 'webrtc/call_engine_webrtc.dart';

final class AppController extends ChangeNotifier {
  AppController() {
    _lastCaptionsEnabled = settings.captionsEnabled;
    _lastTtsEnabled = settings.ttsEnabled;
    settings.addListener(_onSettingsChanged);
    _tts = TtsService(settings);
    _haptics = HapticsService();
    _signaling = FirebaseSignaling();
    _webrtc = WebRtcCallEngine(signaling: _signaling, selfId: _selfId);
  }

  final SettingsController settings = SettingsController();
  late final TtsService _tts;
  late final HapticsService _haptics;
  late final FirebaseSignaling _signaling;
  late final WebRtcCallEngine _webrtc;
  final String _selfId = DateTime.now().microsecondsSinceEpoch.toString();
  CaptionEngineSherpa? _stt;
  final SherpaModelLoader _sherpaLoader = SherpaModelLoader();
  bool _sttReady = false;
  String? _sttError;
  bool get sttReady => _sttReady;
  String? get sttError => _sttError;
  late bool _lastCaptionsEnabled;
  late bool _lastTtsEnabled;

  CallPhase _phase = CallPhase.idle;
  CallPhase get phase => _phase;

  bool _muted = false;
  bool get muted => _muted;

  bool _speakerOn = true;
  bool get speakerOn => _speakerOn;

  String _remoteName = 'Alex';
  String get remoteName => _remoteName;

  String? _activeCallId;
  String? get activeCallId => _activeCallId;

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
    await _initStt();
  }

  Future<void> _initStt() async {
    try {
      final engine = CaptionEngineSherpa(
        onCaption: (line) {
          _captions.add(line);
          if (_captions.length > 120) {
            _captions.removeRange(0, _captions.length - 120);
          }
          notifyListeners();
        },
        speakerLabel: () => 'You',
      );

      final model = await _sherpaLoader.loadStreamingZipformer();
      await engine.init(model: model);
      _stt = engine;
      _sttReady = true;
      _sttError = null;
      notifyListeners();
    } catch (e) {
      _sttReady = false;
      _sttError = e.toString();
      notifyListeners();
    }
  }

  Future<void> startOutgoingCallRealtime({
    required String callId,
    String remoteName = 'Alex',
  }) async {
    await _ensureMicrophonePermission();
    _remoteName = remoteName;
    _activeCallId = callId;
    _endReason = null;
    _muted = false;
    _speakerOn = true;
    _captions.clear();
    _messages.clear();
    _setPhase(CallPhase.connecting);
    await _webrtc.startCall(callId: callId);
    _setPhase(CallPhase.inCall);
    unawaited(_haptics.connected());
    unawaited(SystemSound.play(SystemSoundType.click));
    unawaited(_tts.speak('Call connected'));
    unawaited(_startCaptions());
  }

  Future<void> joinCallRealtime({
    required String callId,
    String remoteName = 'Alex',
  }) async {
    await _ensureMicrophonePermission();
    _remoteName = remoteName;
    _activeCallId = callId;
    _endReason = null;
    _muted = false;
    _speakerOn = true;
    _captions.clear();
    _messages.clear();
    _setPhase(CallPhase.connecting);
    await _webrtc.joinCall(callId: callId);
    _setPhase(CallPhase.inCall);
    unawaited(_haptics.connected());
    unawaited(SystemSound.play(SystemSoundType.click));
    unawaited(_tts.speak('Call connected'));
    unawaited(_startCaptions());
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
    unawaited(_stopCaptions());
    unawaited(_webrtc.hangup());
    unawaited(_haptics.ended());
    unawaited(SystemSound.play(SystemSoundType.alert));
    unawaited(_tts.speak('Call ended'));
  }

  void resetToIdle() {
    _endReason = null;
    _activeCallId = null;
    _captions.clear();
    _messages.clear();
    _setPhase(CallPhase.idle);
  }

  void toggleMute() {
    _muted = !_muted;
    notifyListeners();
    unawaited(SystemSound.play(SystemSoundType.click));
    unawaited(_tts.speak(_muted ? 'Microphone muted' : 'Microphone unmuted'));
    unawaited(_webrtc.setMuted(_muted));
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

  ChatMessage? get lastMessage => _messages.isEmpty ? null : _messages.last;

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

  Future<void> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw StateError('Microphone permission is required for calling');
    }
  }

  Future<void> _startCaptions() async {
    if (!settings.captionsEnabled) return;
    if (_phase != CallPhase.inCall) return;
    // Prefer real STT; fall back to mock if not configured.
    if (_sttReady && _stt != null) {
      await _stt!.start();
      return;
    }
    _startMockCaptionStream();
  }

  Future<void> _stopCaptions() async {
    _stopMockCaptionStream();
    if (_stt != null) {
      await _stt!.stop();
    }
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

  void _onSettingsChanged() {
    final captionsEnabled = settings.captionsEnabled;
    if (captionsEnabled != _lastCaptionsEnabled) {
      _lastCaptionsEnabled = captionsEnabled;
      if (captionsEnabled) {
        unawaited(_startCaptions());
      } else {
        unawaited(_stopCaptions());
      }
    }

    final ttsEnabled = settings.ttsEnabled;
    if (ttsEnabled != _lastTtsEnabled) {
      _lastTtsEnabled = ttsEnabled;
      if (!ttsEnabled) {
        unawaited(_tts.stop());
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    settings.removeListener(_onSettingsChanged);
    settings.dispose();
    unawaited(_tts.stop());
    unawaited(_webrtc.dispose());
    unawaited(_stt?.dispose());
    super.dispose();
  }
}
