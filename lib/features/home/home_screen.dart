import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../services/app_controller.dart';
import '../../services/call_models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => Navigator.of(context).pushNamed(UniCallRoutes.settings),
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
              'Accessibility-first calling prototype',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This build simulates call states, live captions, chat, and announcements so you can test UI/UX.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _StatusCard(phase: phase, controller: controller),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: phase == CallPhase.idle
                  ? () {
                      controller.startOutgoingCall(remoteName: 'Alex');
                      Navigator.of(context).pushNamed(UniCallRoutes.inCall);
                    }
                  : null,
              icon: const Icon(Icons.call),
              label: const Text('Start simulated call'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: phase == CallPhase.idle
                  ? () {
                      controller.simulateIncomingCall(remoteName: 'Alex');
                      Navigator.of(context).pushNamed(UniCallRoutes.incoming);
                    }
                  : null,
              icon: const Icon(Icons.ring_volume),
              label: const Text('Simulate incoming call'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: phase != CallPhase.idle
                  ? () {
                      controller.endCall();
                      controller.resetToIdle();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reset to idle')),
                      );
                    }
                  : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
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
                  Text('Current state', style: Theme.of(context).textTheme.labelLarge),
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

