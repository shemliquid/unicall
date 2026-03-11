import 'package:flutter/material.dart';

import '../../services/app_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.settings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Accessibility', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Semantics(
              label: 'High contrast',
              hint: 'Use a higher contrast theme for readability',
              toggled: s.highContrast,
              child: SwitchListTile(
                value: s.highContrast,
                onChanged: s.setHighContrast,
                title: const Text('High contrast'),
                subtitle: const Text('Use a higher-contrast theme for readability.'),
              ),
            ),
            const SizedBox(height: 8),
            _SliderTile(
              label: 'Caption size',
              value: s.captionScale,
              min: 0.9,
              max: 2.2,
              divisions: 13,
              onChanged: s.setCaptionScale,
              format: (v) => '${(v * 100).round()}%',
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Live captions',
              hint: 'Show live captions during calls',
              toggled: s.captionsEnabled,
              child: SwitchListTile(
                value: s.captionsEnabled,
                onChanged: s.setCaptionsEnabled,
                title: const Text('Live captions'),
                subtitle: const Text('Show live captions during calls.'),
              ),
            ),
            const Divider(height: 24),
            Text('Speech', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Semantics(
              label: 'Text to speech',
              hint: 'Speak typed messages and system announcements',
              toggled: s.ttsEnabled,
              child: SwitchListTile(
                value: s.ttsEnabled,
                onChanged: s.setTtsEnabled,
                title: const Text('Text-to-speech'),
                subtitle: const Text('Speak typed messages and system announcements.'),
              ),
            ),
            const SizedBox(height: 8),
            _SliderTile(
              label: 'Speech rate',
              value: s.speechRate,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: s.setSpeechRate,
              format: (v) => v.toStringAsFixed(1),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Note: This build is UI-only. Voice, captions, and call states are simulated so you can test TalkBack, large text, and interaction patterns.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.format,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: theme.textTheme.titleMedium),
                ),
                Text(format(value), style: theme.textTheme.labelLarge),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

