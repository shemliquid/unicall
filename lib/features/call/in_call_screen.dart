import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../services/app_controller.dart';
import '../../services/call_models.dart';

class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final phase = c.phase;

    if (phase == CallPhase.ended || phase == CallPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(UniCallRoutes.home, (r) => false);
      });
    }

    final captions = c.captions;
    final messages = c.messages;
    final captionScale = c.settings.captionScale;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          phase == CallPhase.connecting ? 'Connecting…' : c.remoteName,
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            c.endCall();
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(UniCallRoutes.home, (r) => false);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () =>
                Navigator.of(context).pushNamed(UniCallRoutes.settings),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SafeArea(
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              return Column(
                children: [
                  if (!c.sttReady)
                    MaterialBanner(
                      content: Text(
                        'Offline captions not configured. Add model files under assets/models/sherpa_streaming/.',
                      ),
                      actions: const [SizedBox.shrink()],
                    ),
                  Expanded(
                    child: isNarrow
                        ? Column(
                            children: [
                              Expanded(
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(1),
                                  child: _CaptionsPanel(
                                    captions: captions,
                                    enabled: c.settings.captionsEnabled,
                                    scale: captionScale,
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(2),
                                  child: _ChatPanel(
                                    messages: messages,
                                    controller: _chatController,
                                    onSend: (text) {
                                      c.sendChat(text);
                                      _chatController.clear();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(1),
                                  child: _CaptionsPanel(
                                    captions: captions,
                                    enabled: c.settings.captionsEnabled,
                                    scale: captionScale,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(2),
                                  child: _ChatPanel(
                                    messages: messages,
                                    controller: _chatController,
                                    onSend: (text) {
                                      c.sendChat(text);
                                      _chatController.clear();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const Divider(height: 1),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: _ActionBar(controller: c),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CaptionsPanel extends StatelessWidget {
  const _CaptionsPanel({
    required this.captions,
    required this.enabled,
    required this.scale,
  });

  final List<CaptionLine> captions;
  final bool enabled;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Live captions',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (!enabled)
                  Text(
                    'Paused',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: enabled
                ? ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: captions.length,
                    itemBuilder: (context, index) {
                      final line = captions[index];
                      final style = theme.textTheme.titleLarge?.copyWith(
                        fontSize:
                            (theme.textTheme.titleLarge?.fontSize ?? 20) *
                            scale,
                        color: line.isPartial
                            ? cs.onSurfaceVariant
                            : cs.onSurface,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(_formatCaption(line), style: style),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'Captions are paused.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatCaption(CaptionLine line) {
    final speaker = line.speakerLabel;
    if (speaker == null || speaker.trim().isEmpty) return line.text;
    return '$speaker: ${line.text}';
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.messages,
    required this.controller,
    required this.onSend,
  });

  final List<ChatMessage> messages;
  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Text', style: theme.textTheme.titleMedium),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final m = messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.from,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(m.text, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) => onSend(value),
                  decoration: const InputDecoration(
                    labelText: 'Type a message',
                    hintText:
                        'Will be spoken aloud when TTS is enabled (later)',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => onSend(controller.text),
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = controller.muted;
    final speaker = controller.speakerOn;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        spacing: 10,
        children: [
          Semantics(
            button: true,
            label: muted ? 'Unmute microphone' : 'Mute microphone',
            hint: 'Toggles whether your microphone is on',
            toggled: muted,
            child: FilledButton.tonalIcon(
              onPressed: controller.toggleMute,
              icon: Icon(muted ? Icons.mic_off : Icons.mic),
              label: Text(muted ? 'Unmute' : 'Mute'),
            ),
          ),
          Semantics(
            button: true,
            label: speaker ? 'Switch to earpiece' : 'Switch to speaker',
            hint: 'Toggles audio output',
            toggled: speaker,
            child: FilledButton.tonalIcon(
              onPressed: controller.toggleSpeaker,
              icon: Icon(speaker ? Icons.volume_up : Icons.hearing_disabled),
              label: Text(speaker ? 'Speaker' : 'Earpiece'),
            ),
          ),
          Semantics(
            button: true,
            label: controller.settings.captionsEnabled
                ? 'Turn captions off'
                : 'Turn captions on',
            hint: 'Shows or hides live captions',
            toggled: controller.settings.captionsEnabled,
            child: FilledButton.tonalIcon(
              onPressed: () => controller.settings.setCaptionsEnabled(
                !controller.settings.captionsEnabled,
              ),
              icon: Icon(
                controller.settings.captionsEnabled
                    ? Icons.closed_caption
                    : Icons.closed_caption_disabled,
              ),
              label: Text(
                controller.settings.captionsEnabled
                    ? 'Captions on'
                    : 'Captions off',
              ),
            ),
          ),
          Semantics(
            button: true,
            label: controller.settings.ttsEnabled
                ? 'Turn text to speech off'
                : 'Turn text to speech on',
            hint: 'Speaks typed messages and announcements',
            toggled: controller.settings.ttsEnabled,
            child: FilledButton.tonalIcon(
              onPressed: () => controller.settings.setTtsEnabled(
                !controller.settings.ttsEnabled,
              ),
              icon: Icon(
                controller.settings.ttsEnabled
                    ? Icons.record_voice_over
                    : Icons.voice_over_off,
              ),
              label: Text(
                controller.settings.ttsEnabled ? 'TTS on' : 'TTS off',
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Read last message',
            hint: 'Speaks the most recent typed message',
            child: FilledButton.tonalIcon(
              onPressed: controller.lastMessageText == null
                  ? null
                  : () {
                      controller.readLastMessage();
                    },
              icon: const Icon(Icons.speaker_notes),
              label: const Text('Read'),
            ),
          ),
          Semantics(
            button: true,
            label: 'End call',
            hint: 'Ends the current call',
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: () {
                controller.endCall();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(UniCallRoutes.home, (r) => false);
              },
              icon: const Icon(Icons.call_end),
              label: const Text('End'),
            ),
          ),
        ],
      ),
    );
  }
}
