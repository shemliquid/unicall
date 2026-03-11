import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/router.dart';
import '../../services/app_controller.dart';
import '../../services/call_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _joinController = TextEditingController();

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final phase = controller.phase;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniCall'),
        actions: [
          Semantics(
            button: true,
            label: 'Open settings',
            hint: 'Adjust contrast, caption size, and speech settings',
            child: IconButton(
              tooltip: 'Settings',
              onPressed: () =>
                  Navigator.of(context).pushNamed(UniCallRoutes.settings),
              icon: const Icon(Icons.settings),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Realtime accessible calling (MVP)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a call code on Device A, then join it on Device B.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _StatusCard(phase: phase, controller: controller),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: phase == CallPhase.idle
                  ? () => _createCall(context)
                  : null,
              icon: const Icon(Icons.add_call),
              label: const Text('Create call'),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join call',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _joinController,
                      decoration: const InputDecoration(
                        labelText: 'Call code',
                        hintText: 'Paste callId from the other device',
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _joinCall(context),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: phase == CallPhase.idle
                          ? () => _joinCall(context)
                          : null,
                      icon: const Icon(Icons.call),
                      label: const Text('Join'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!controller.sttReady)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Offline captions not ready yet. Add a sherpa streaming model under assets/models/sherpa_streaming/.\n\nError: ${controller.sttError ?? 'Unknown'}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCall(BuildContext context) async {
    final callId = DateTime.now().millisecondsSinceEpoch.toString();
    await Clipboard.setData(ClipboardData(text: callId));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Call code created'),
          content: SelectableText(
            callId,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: callId));
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await widget.controller.startOutgoingCallRealtime(
                    callId: callId,
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamed(UniCallRoutes.inCall);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to start call: $e')),
                  );
                }
              },
              child: const Text('Start call'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinCall(BuildContext context) async {
    final callId = _joinController.text.trim();
    if (callId.isEmpty) return;
    try {
      await widget.controller.joinCallRealtime(callId: callId);
      if (!context.mounted) return;
      Navigator.of(context).pushNamed(UniCallRoutes.inCall);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to join call: $e')));
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.phase, required this.controller});

  final CallPhase phase;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = switch (phase) {
      CallPhase.idle => 'Idle',
      CallPhase.outgoingDialing => 'Dialing…',
      CallPhase.incomingRinging => 'Incoming call',
      CallPhase.connecting => 'Connecting…',
      CallPhase.inCall => 'In call',
      CallPhase.ended => 'Call ended',
      CallPhase.failed => 'Call failed',
    };

    return Card(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current state',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  if (phase != CallPhase.idle) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Remote: ${controller.remoteName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
