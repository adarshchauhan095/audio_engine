import 'package:flutter/material.dart';
import '../../session/audio_runtime_controller.dart';
import '../../session/profile_session_catalog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.runtime});
  final AudioRuntimeController runtime;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile & Progress')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Therapy Adherence', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<int>(
                      valueListenable: widget.runtime.therapySession!.totalTherapySeconds,
                      builder: (context, seconds, _) {
                        final double progress = (seconds / 3600).clamp(0.0, 1.0);
                        return Column(
                          children: [
                            CircularProgressIndicator(value: progress, strokeWidth: 8),
                            const SizedBox(height: 16),
                            Text('${(progress * 100).toStringAsFixed(1)}% Complete for this week (${seconds}s / 3600s).'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Live Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Live Tune Parameters', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<double>(
                      valueListenable: widget.runtime.frequency,
                      builder: (context, freq, _) {
                        return Column(
                          children: [
                            Text('Frequency: ${freq.toStringAsFixed(1)} Hz'),
                            Slider(
                              value: freq,
                              min: 20,
                              max: 20000,
                              onChanged: widget.runtime.setFrequency,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<double>(
                      valueListenable: widget.runtime.amplitude,
                      builder: (context, amp, _) {
                        return Column(
                          children: [
                            Text('Master Volume: ${(amp * 100).toStringAsFixed(0)}%'),
                            Slider(
                              value: amp,
                              min: 0.0,
                              max: 1.0,
                              onChanged: widget.runtime.setAmplitude,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Active Session Progress
            ValueListenableBuilder<bool>(
              valueListenable: widget.runtime.therapySession!.isRunning,
              builder: (context, running, child) {
                if (!running) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Active Session', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<int>(
                            valueListenable: widget.runtime.therapySession!.remainingSeconds,
                            builder: (context, remain, _) {
                              final total = widget.runtime.therapySession!.warmupDuration + widget.runtime.therapySession!.mainDuration + widget.runtime.therapySession!.cooldownDuration;
                              final elapsed = total - remain;
                              final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LinearProgressIndicator(value: progress, minHeight: 8),
                                  const SizedBox(height: 8),
                                  Text('Remaining: ${remain ~/ 60}:${(remain % 60).toString().padLeft(2, '0')}', textAlign: TextAlign.right, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: widget.runtime.therapySession!.stopSession,
                                    icon: const Icon(Icons.stop),
                                    label: const Text('Stop Session'),
                                  )
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Saved / Interested Sessions
            Text('Saved Presets', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: TherapyProfilePreset.presets.length,
              itemBuilder: (context, index) {
                final preset = TherapyProfilePreset.presets[index];
                return ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text(preset.name),
                  subtitle: Text('Subthreshold: ${preset.subthreshold}, Binaural: ${preset.binaural}'),
                  trailing: const Icon(Icons.play_circle_fill),
                  onTap: () {
                    final session = widget.runtime.therapySession;
                    if (session != null) {
                        session.startSession(
                          subthreshold: preset.subthreshold,
                          rmp: preset.rmp,
                          pip: preset.pip,
                          sidebands: preset.sidebands,
                          binaural: preset.binaural,
                          baseFreq: widget.runtime.frequency.value,
                          baseAmp: widget.runtime.amplitude.value,
                          maxIntensity: 0.5,
                          durationMinutes: 5, // default to 5 minutes from ProfileScreen
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Started session: ${preset.name}')),
                        );
                    }
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
