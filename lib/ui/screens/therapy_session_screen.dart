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

  void _logPresetConfiguration(TherapyProfilePreset p) {
    debugPrint('Preset loaded: ${p.name}');

    final double rmpDepth = p.rmpDepth ?? 0.1;
    final double rmpRate = p.rmpRate ?? 5.0;
    final double pipIntervalMs = (p.pipInterval ?? 0.2) * 1000.0;
    final double pipDurationMs = (p.pipDuration ?? 0.02) * 1000.0;
    final double sidebandOffset = p.sidebandOffset ?? 100.0;
    final double sidebandIntensity = p.sidebandIntensity ?? 0.33;
    final double binauralOffset = p.binauralOffset ?? 5.0;

    if (p.rmp) {
      debugPrint(
        'RMP enabled (rate=${rmpRate.toStringAsFixed(2)}, depth=${rmpDepth.toStringAsFixed(3)})',
      );
    }
    if (p.pip) {
      debugPrint('PIP interval updated to ${pipIntervalMs.toStringAsFixed(0)} ms');
      debugPrint('PIP duration updated to ${pipDurationMs.toStringAsFixed(0)} ms');
    }
    if (p.sidebands) {
      debugPrint(
        'SSS enabled (offset=${sidebandOffset.toStringAsFixed(1)}, intensity=${sidebandIntensity.toStringAsFixed(2)})',
      );
    }
    if (p.binaural) {
      debugPrint('Binaural enabled (offset=${binauralOffset.toStringAsFixed(1)} Hz)');
    }
  }

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
            child: SingleChildScrollView(
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
                  onChanged: (v) {
                    if (v == null) return;

                    setState(() => _selectedPreset = v);

                    final double baseFreq = v.baseFreq ?? runtime.frequency.value;
                    final double baseAmp = v.baseAmp ?? runtime.amplitude.value;

                    // Keep the "Live Audio Settings" card consistent with the preset.
                    if (v.baseFreq != null) runtime.setFrequency(v.baseFreq!);
                    if (v.baseAmp != null) runtime.setAmplitude(v.baseAmp!);

                    _logPresetConfiguration(v);

                    if (isRunning) {
                      session.updatePreset(
                        subthreshold: v.subthreshold,
                        rmp: v.rmp,
                        pip: v.pip,
                        sidebands: v.sidebands,
                        binaural: v.binaural,
                        baseFreq: baseFreq,
                        baseAmp: baseAmp,
                        targetRmpDepth: v.rmpDepth ?? 0.1,
                        targetRmpRate: v.rmpRate ?? 5.0,
                        targetPipInterval: v.pipInterval ?? 0.2,
                        targetPipDuration: v.pipDuration ?? 0.02,
                        targetSidebandOffset: v.sidebandOffset ?? 100.0,
                        targetSidebandIntensity: v.sidebandIntensity ?? 0.33,
                        targetBinauralOffset: v.binauralOffset ?? 5.0,
                      );
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
                if (_selectedPreset != null) const SizedBox(height: 8),
                if (_selectedPreset != null)
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Builder(builder: (context) {
                        final p = _selectedPreset!;
                        final double baseFreq =
                            p.baseFreq ?? runtime.frequency.value;
                        final double baseAmp =
                            p.baseAmp ?? runtime.amplitude.value;
                        final double rmpDepth = p.rmpDepth ?? 0.1;
                        final double rmpRate = p.rmpRate ?? 5.0;
                        final double pipIntervalMs =
                            (p.pipInterval ?? 0.2) * 1000.0;
                        final double pipDurationMs =
                            (p.pipDuration ?? 0.02) * 1000.0;
                        final double sidebandOffset = p.sidebandOffset ?? 100.0;
                        final double sidebandIntensity =
                            p.sidebandIntensity ?? 0.33;
                        final double binauralOffset =
                            p.binauralOffset ?? 5.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Preset Parameters',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text('Base Freq: ${baseFreq.toStringAsFixed(0)} Hz'),
                            Text('Base Amp: ${baseAmp.toStringAsFixed(3)}'),
                            const SizedBox(height: 8),
                            Text('Modules:'),
                            Text('Subthreshold: ${p.subthreshold ? 'On' : 'Off'}'),
                            Text('RMP: ${p.rmp ? 'On' : 'Off'}'
                                '${p.rmp ? ' (rate=${rmpRate.toStringAsFixed(2)}, depth=${rmpDepth.toStringAsFixed(3)})' : ''}'),
                            Text('PIP: ${p.pip ? 'On' : 'Off'}'
                                '${p.pip ? ' (interval=${pipIntervalMs.toStringAsFixed(0)}ms, duration=${pipDurationMs.toStringAsFixed(0)}ms)' : ''}'),
                            Text('SSS: ${p.sidebands ? 'On' : 'Off'}'
                                '${p.sidebands ? ' (offset=${sidebandOffset.toStringAsFixed(1)}, intensity=${sidebandIntensity.toStringAsFixed(2)})' : ''}'),
                            Text('Binaural: ${p.binaural ? 'On' : 'Off'}'
                                '${p.binaural ? ' (offset=${binauralOffset.toStringAsFixed(1)} Hz)' : ''}'),
                          ],
                        );
                      }),
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
                const SizedBox(height: 16),
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

                      _logPresetConfiguration(p);
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
            ),
          );
        },
      ),
    );
  }
}
