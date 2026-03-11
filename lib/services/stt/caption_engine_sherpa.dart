import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../call_models.dart';

typedef CaptionCallback = void Function(CaptionLine line);

final class CaptionEngineSherpa {
  CaptionEngineSherpa({
    required CaptionCallback onCaption,
    required String Function() speakerLabel,
  }) : _onCaption = onCaption,
       _speakerLabel = speakerLabel;

  final CaptionCallback _onCaption;
  final String Function() _speakerLabel;

  final AudioRecorder _recorder = AudioRecorder();

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;

  StreamSubscription<List<int>>? _micSub;
  bool _initialized = false;

  Future<void> dispose() async {
    await stop();
    _recorder.dispose();
    _stream?.free();
    _recognizer?.free();
  }

  /// Initializes sherpa bindings and recognizer.
  ///
  /// You must place a streaming model under `assets/models/` and provide its paths here.
  Future<void> init({required sherpa.OnlineModelConfig model}) async {
    if (_initialized) return;
    sherpa.initBindings();
    final config = sherpa.OnlineRecognizerConfig(model: model, ruleFsts: '');
    _recognizer = sherpa.OnlineRecognizer(config);
    _stream = _recognizer!.createStream();
    _initialized = true;
  }

  Future<void> start() async {
    if (!_initialized) {
      throw StateError('CaptionEngineSherpa not initialized');
    }
    if (_micSub != null) return;
    if (!await _recorder.hasPermission()) {
      throw StateError('Microphone permission not granted');
    }

    const cfg = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    final stream = await _recorder.startStream(cfg);
    _micSub = stream.listen(
      _onPcmBytes,
      onError: (e, st) {
        debugPrint('STT mic stream error: $e');
      },
    );
  }

  Future<void> stop() async {
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (_stream != null && _recognizer != null) {
      _stream!.free();
      _stream = _recognizer!.createStream();
    }
  }

  void _onPcmBytes(List<int> data) {
    final recognizer = _recognizer;
    final stream = _stream;
    if (recognizer == null || stream == null) return;

    final samples = _pcm16leToFloat32(Uint8List.fromList(data));
    stream.acceptWaveform(samples: samples, sampleRate: 16000);

    while (recognizer.isReady(stream)) {
      recognizer.decode(stream);
    }

    final text = recognizer.getResult(stream).text;
    if (text.trim().isNotEmpty) {
      _onCaption(
        CaptionLine(
          text: text,
          isPartial: true,
          timestamp: DateTime.now(),
          speakerLabel: _speakerLabel(),
        ),
      );
    }

    if (recognizer.isEndpoint(stream)) {
      final finalText = recognizer.getResult(stream).text.trim();
      if (finalText.isNotEmpty) {
        _onCaption(
          CaptionLine(
            text: finalText,
            isPartial: false,
            timestamp: DateTime.now(),
            speakerLabel: _speakerLabel(),
          ),
        );
      }
      recognizer.reset(stream);
    }
  }

  Float32List _pcm16leToFloat32(Uint8List bytes) {
    final samples = Int16List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 2,
    );
    final out = Float32List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      out[i] = samples[i] / 32768.0;
    }
    return out;
  }
}
