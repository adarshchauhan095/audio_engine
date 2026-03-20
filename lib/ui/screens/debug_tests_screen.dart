import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';

class DebugTestsScreen extends StatefulWidget {
  const DebugTestsScreen({super.key, required this.runtime});

  final AudioRuntimeController runtime;

  @override
  State<DebugTestsScreen> createState() => _DebugTestsScreenState();
}

class _DebugTestsScreenState extends State<DebugTestsScreen> {
  int _longRunDurationSeconds = 30;

  static const List<int> _longRunDurations = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final runtime = widget.runtime;
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Tests')),
      body: ValueListenableBuilder<bool>(
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
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            const Text('Long-run duration: '),
                            DropdownButton<int>(
                              value: _longRunDurationSeconds,
                              items: _longRunDurations.map((int s) {
                                return DropdownMenuItem<int>(
                                  value: s,
                                  child: Text('$s s'),
                                );
                              }).toList(),
                              onChanged: disabled
                                  ? null
                                  : (int? v) {
                                      if (v != null) setState(() => _longRunDurationSeconds = v);
                                    },
                            ),
                          ],
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
                                      () => runtime.runLongRunStabilityTest(
                                        durationSeconds: _longRunDurationSeconds,
                                      ),
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
                if (isDebugRunning) 
                  ValueListenableBuilder<double>(
                    valueListenable: runtime.debugProgress,
                    builder: (context, progress, _) => LinearProgressIndicator(value: progress, minHeight: 6),
                  ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Audio Controls',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<double>(
                          valueListenable: widget.runtime.frequency,
                          builder: (context, freq, _) {
                            final double secureFreq = freq.clamp(AudioRuntimeController.freqMin, AudioRuntimeController.freqMax);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Frequency: ${secureFreq.toStringAsFixed(1)} Hz'),
                                Slider(
                                  value: secureFreq,
                                  min: AudioRuntimeController.freqMin,
                                  max: AudioRuntimeController.freqMax,
                                  onChanged: disabled ? null : (double value) => widget.runtime.setFrequency(value),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<double>(
                          valueListenable: widget.runtime.amplitude,
                          builder: (context, amp, _) {
                            final double secureAmp = amp.clamp(0.0, 1.0);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Amplitude: ${secureAmp.toStringAsFixed(3)}'),
                                Slider(
                                  value: secureAmp,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: disabled ? null : (double value) => widget.runtime.setAmplitude(value),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 88),
              ],
            ),
          );
        },
      ),
    );
  }
}
