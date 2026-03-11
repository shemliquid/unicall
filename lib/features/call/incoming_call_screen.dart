import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../services/app_controller.dart';
import '../../services/call_models.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final phase = controller.phase;
    if (phase != CallPhase.incomingRinging) {
      // If we navigated here at the wrong time, send users to the right place.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(UniCallRoutes.home, (r) => false);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.call,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Incoming call',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.remoteName,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        button: true,
                        label: 'Reject call',
                        hint: 'Sends the call to declined',
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            controller.rejectIncoming();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              UniCallRoutes.home,
                              (r) => false,
                            );
                          },
                          icon: const Icon(Icons.call_end),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Semantics(
                        button: true,
                        label: 'Answer call',
                        hint: 'Connects the call',
                        child: FilledButton.icon(
                          onPressed: () {
                            controller.answerIncoming();
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(UniCallRoutes.inCall);
                          },
                          icon: const Icon(Icons.call),
                          label: const Text('Answer'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tip: enable TalkBack and test focus order and labels.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
