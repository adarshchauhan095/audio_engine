import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';
import '../../session/profile_session_catalog.dart';
import '../../session/therapy_session_controller.dart';

class TherapySessionScreen extends StatefulWidget {
  const TherapySessionScreen({super.key, required this.runtime});
  final AudioRuntimeController runtime;

  @override
  State<TherapySessionScreen> createState() => _TherapySessionScreenState();
}

class _TherapySessionScreenState extends State<TherapySessionScreen> {
  TherapyProfilePreset? _selectedPreset = TherapyProfilePreset.presets.first;
  int _selectedDurationMinutes = 5;
  double _intensity = 0.5;

  @override
  Widget build(BuildContext context) {
    final runtime = widget.runtime;
    final session = runtime.therapySession;

    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: session.isRunning,
        builder: (context, isRunning, child) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButton<TherapyProfilePreset>(
                  value: _selectedPreset,
                  isExpanded: true,
                  items: TherapyProfilePreset.presets.map((preset) {
                    return DropdownMenuItem(
                      value: preset,
                      child: Text(preset.name),
                    );
                  }).toList(),
                  onChanged: isRunning ? null : (v) {
                    if (v != null) {
                      setState(() => _selectedPreset = v);
                      debugPrint('TherapySessionScreen: preset selected "${v.name}" (baseFreq=${v.baseFreq}, baseAmp=${v.baseAmp}, pip=${v.pip})');
                    }
                  },
                ),
                if (_selectedPreset != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Text(
                      _selectedPreset!.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Duration (minutes):'),
                    DropdownButton<int>(
                      value: _selectedDurationMinutes,
                      items: [1, 5, 10, 20].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: isRunning ? null : (v) => setState(() => _selectedDurationMinutes = v ?? 5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Max Intensity: ${(_intensity * 100).toStringAsFixed(0)}%'),
                Slider(
                  value: _intensity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: isRunning ? null : (v) => setState(() => _intensity = v),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live Audio Settings', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<double>(
                          valueListenable: runtime.frequency,
                          builder: (context, freq, _) => Text('Frequency: ${freq.toStringAsFixed(1)} Hz'),
                        ),
                        const SizedBox(height: 4),
                        ValueListenableBuilder<double>(
                          valueListenable: runtime.amplitude,
                          builder: (context, amp, _) => Text('Base Amplitude: ${amp.toStringAsFixed(3)}'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ValueListenableBuilder<TherapyPhase>(
                  valueListenable: session.currentPhase,
                  builder: (context, phase, _) {
                    return Text('Phase: ${phase.name.toUpperCase()}', style: Theme.of(context).textTheme.headlineSmall);
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: session.remainingSeconds,
                  builder: (context, seconds, _) {
                    final mins = seconds ~/ 60;
                    final secs = seconds % 60;
                    return Text('Remaining: $mins:${secs.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.headlineMedium);
                  },
                ),
                const SizedBox(height: 32),
                ValueListenableBuilder<double>(
                  valueListenable: session.intensity,
                  builder: (context, currentIntensity, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Intensity: ${(currentIntensity * 100).toStringAsFixed(1)}%'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: currentIntensity),
                      ],
                    );
                  },
                ),
                const Spacer(),
                FilledButton(
                    onPressed: () {
                    if (isRunning) {
                      session.stopSession();
                    } else {
                      if (_selectedPreset == null) return;
                      final p = _selectedPreset!;
                      final baseFreq = p.baseFreq ?? runtime.frequency.value;
                      final baseAmp = p.baseAmp ?? runtime.amplitude.value;
                      if (p.baseFreq != null) runtime.setFrequency(p.baseFreq!);
                      if (p.baseAmp != null) runtime.setAmplitude(p.baseAmp!);
                      session.startSession(
                        subthreshold: p.subthreshold,
                        rmp: p.rmp,
                        pip: p.pip,
                        sidebands: p.sidebands,
                        binaural: p.binaural,
                        baseFreq: baseFreq,
                        baseAmp: baseAmp,
                        maxIntensity: _intensity,
                        durationMinutes: _selectedDurationMinutes,
                        targetRmpDepth: p.rmpDepth ?? 0.1,
                        targetRmpRate: p.rmpRate ?? 5.0,
                        targetPipInterval: p.pipInterval ?? 0.2,
                        targetPipDuration: p.pipDuration ?? 0.02,
                        targetSidebandOffset: p.sidebandOffset ?? 100.0,
                        targetSidebandIntensity: p.sidebandIntensity ?? 0.33,
                        targetBinauralOffset: p.binauralOffset ?? 5.0,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                  ),
                  child: Text(isRunning ? 'Stop Session' : 'Start Session'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
