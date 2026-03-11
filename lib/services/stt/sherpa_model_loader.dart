import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

final class SherpaModelLoader {
  /// Minimal streaming model layout expected under `assets/models/sherpa_streaming/`.
  ///
  /// Place these files (example names) in your project and update as needed:
  /// - `assets/models/sherpa_streaming/encoder.onnx`
  /// - `assets/models/sherpa_streaming/decoder.onnx`
  /// - `assets/models/sherpa_streaming/joiner.onnx`
  /// - `assets/models/sherpa_streaming/tokens.txt`
  static const encoderAsset = 'assets/models/sherpa_streaming/encoder.onnx';
  static const decoderAsset = 'assets/models/sherpa_streaming/decoder.onnx';
  static const joinerAsset = 'assets/models/sherpa_streaming/joiner.onnx';
  static const tokensAsset = 'assets/models/sherpa_streaming/tokens.txt';

  Future<sherpa.OnlineModelConfig> loadStreamingZipformer() async {
    final dir = await getApplicationSupportDirectory();
    final outDir = Directory(p.join(dir.path, 'sherpa_streaming'));
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final encoderPath = await _copyAssetTo(encoderAsset, outDir.path);
    final decoderPath = await _copyAssetTo(decoderAsset, outDir.path);
    final joinerPath = await _copyAssetTo(joinerAsset, outDir.path);
    final tokensPath = await _copyAssetTo(tokensAsset, outDir.path);

    return sherpa.OnlineModelConfig(
      // Zipformer streaming model.
      // The exact knobs depend on model family; this config works for standard zipformer builds.
      transducer: sherpa.OnlineTransducerModelConfig(
        encoder: encoderPath,
        decoder: decoderPath,
        joiner: joinerPath,
      ),
      tokens: tokensPath,
      numThreads: 2,
      debug: false,
      provider: 'cpu',
    );
  }

  Future<String> _copyAssetTo(String assetPath, String outDir) async {
    final data = await rootBundle.load(assetPath);
    final fileName = p.basename(assetPath);
    final outPath = p.join(outDir, fileName);
    final file = File(outPath);
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return outPath;
  }
}
