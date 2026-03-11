import 'package:flutter/material.dart';

import '../services/settings_controller.dart';

final class UniCallTheme {
  static ThemeData light(SettingsController settings) {
    return _base(
      brightness: Brightness.light,
      highContrast: settings.highContrast,
      captionScale: settings.captionScale,
    );
  }

  static ThemeData dark(SettingsController settings) {
    return _base(
      brightness: Brightness.dark,
      highContrast: true,
      captionScale: settings.captionScale,
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required bool highContrast,
    required double captionScale,
  }) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: highContrast ? Colors.black : const Color(0xFF0B57D0),
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme;

    // Caption text needs to remain readable even with large scaling.
    final captionStyle = (textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      height: 1.25,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(titleLarge: captionStyle),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
    );
  }
}
