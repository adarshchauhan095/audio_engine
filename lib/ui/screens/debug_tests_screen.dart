import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';

class DebugTestsScreen extends StatelessWidget {
  const DebugTestsScreen({super.key, required this.runtime});

  final AudioRuntimeController runtime;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<bool>(
        valueListenable: runtime.debugActionRunning,
        builder: (BuildContext context, bool isDebugRunning, Widget? child) {
          final bool disabled = !runtime.hasEngine || isDebugRunning;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Milestone 02 tests',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rapid params, start/stop x10, and extreme value stability tests.',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: disabled
                                  ? null
                                  : () => runtime.runExclusiveDebugAction(
                                      runtime.runRapidParams,
                                    ),
                              icon: const Icon(Icons.speed),
                              label: const Text('Rapid params'),
                            ),
                            FilledButton.icon(
                              onPressed: disabled
                                  ? null
                                  : () => runtime.runExclusiveDebugAction(
                                      runtime.runStartStop10,
                                    ),
                              icon: const Icon(Icons.replay_10),
                              label: const Text('Start/stop x10'),
                            ),
                            FilledButton.icon(
                              onPressed: disabled
                                  ? null
                                  : () => runtime.runExclusiveDebugAction(
                                      () async {
                                        runtime.runExtremeValues();
                                      },
                                    ),
                              icon: const Icon(Icons.warning_amber),
                              label: const Text('Extreme values'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Session debug',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Sequence, adaptive, and long-run checks.'),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: disabled
                                  ? null
                                  : () => runtime.runExclusiveDebugAction(
                                      runtime.runSequenceTest,
                                    ),
                              icon: const Icon(Icons.queue_music),
                              label: const Text('Sequence test'),
                            ),
                            FilledButton.icon(
                              onPressed: disabled
                                  ? null
                                  : () => runtime.runExclusiveDebugAction(
                                      runtime.runAdaptiveTest,
                                    ),
                              icon: const Icon(Icons.tune),
                              label: const Text('Adaptive test'),
                            ),
                            FilledButton.icon(
                              onPressed: disabled
                                  ? null
                                  : () => runtime.runExclusiveDebugAction(
                                      runtime.runLongRunStabilityTest,
                                    ),
                              icon: const Icon(Icons.hourglass_bottom),
                              label: const Text('Long run stability test'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isDebugRunning) const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 88),
              ],
            ),
          );
        },
      ),
    );
  }
}
