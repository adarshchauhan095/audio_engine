import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';
import '../../session/profile_session_catalog.dart';
import '../../session/therapy_session_controller.dart';
import '../widgets/therapy_modules_meters_panel.dart';

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

  // Editable parameters (user-customizable).
  // Initialized from the selected preset, then updated by the UI controls.
  double _baseFreq = TherapyProfilePreset.presets.first.baseFreq ?? 1000.0;
  double _baseAmp = TherapyProfilePreset.presets.first.baseAmp ?? 0.2;

  bool _subthreshold = TherapyProfilePreset.presets.first.subthreshold;
  bool _rmp = TherapyProfilePreset.presets.first.rmp;
  bool _pip = TherapyProfilePreset.presets.first.pip;
  bool _sss = TherapyProfilePreset.presets.first.sidebands;
  bool _binaural = TherapyProfilePreset.presets.first.binaural;

  // Engine shaping parameters (kept preset-derived for now).
  double _rmpDepth = TherapyProfilePreset.presets.first.rmpDepth ?? 0.1;
  double _rmpRate = TherapyProfilePreset.presets.first.rmpRate ?? 5.0;
  double _pipInterval = TherapyProfilePreset.presets.first.pipInterval ?? 0.2;
  double _pipDuration = TherapyProfilePreset.presets.first.pipDuration ?? 0.02;
  double _sidebandOffset = TherapyProfilePreset.presets.first.sidebandOffset ?? 100.0;
  double _sidebandIntensity =
      TherapyProfilePreset.presets.first.sidebandIntensity ?? 0.33;
  double _binauralOffset =
      TherapyProfilePreset.presets.first.binauralOffset ?? 5.0;

  @override
  void initState() {
    super.initState();
    final p = _selectedPreset;
    if (p == null) return;
    _syncFromPreset(p);
  }

  void _syncFromPreset(TherapyProfilePreset p) {
    _baseFreq = p.baseFreq ?? widget.runtime.frequency.value;
    _baseAmp = p.baseAmp ?? widget.runtime.amplitude.value;

    _subthreshold = p.subthreshold;
    _rmp = p.rmp;
    _pip = p.pip;
    _sss = p.sidebands;
    _binaural = p.binaural;

    _rmpDepth = p.rmpDepth ?? _rmpDepth;
    _rmpRate = p.rmpRate ?? _rmpRate;
    _pipInterval = p.pipInterval ?? _pipInterval;
    _pipDuration = p.pipDuration ?? _pipDuration;
    _sidebandOffset = p.sidebandOffset ?? _sidebandOffset;
    _sidebandIntensity = p.sidebandIntensity ?? _sidebandIntensity;
    _binauralOffset = p.binauralOffset ?? _binauralOffset;
  }

  void _pushEditablePresetToEngine({
    required TherapySessionController session,
    required bool isRunning,
  }) {
    if (!isRunning) return;
    session.updatePreset(
      subthreshold: _subthreshold,
      rmp: _rmp,
      pip: _pip,
      sidebands: _sss,
      binaural: _binaural,
      baseFreq: _baseFreq,
      baseAmp: _baseAmp,
      targetRmpDepth: _rmpDepth,
      targetRmpRate: _rmpRate,
      targetPipInterval: _pipInterval,
      targetPipDuration: _pipDuration,
      targetSidebandOffset: _sidebandOffset,
      targetSidebandIntensity: _sidebandIntensity,
      targetBinauralOffset: _binauralOffset,
    );
  }

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

                    setState(() {
                      _selectedPreset = v;
                      _syncFromPreset(v);
                      // Keep the "Live Audio Settings" card consistent with the preset.
                      runtime.setFrequency(_baseFreq);
                      runtime.setAmplitude(_baseAmp);
                    });

                    _logPresetConfiguration(v);
                    _pushEditablePresetToEngine(
                      session: session,
                      isRunning: isRunning,
                    );
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preset Parameters',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Text('Base Freq: ${_baseFreq.toStringAsFixed(0)} Hz'),
                          Slider(
                            value: _baseFreq,
                            min: AudioRuntimeController.freqMin,
                            max: AudioRuntimeController.freqMax,
                            divisions: 199,
                            onChanged: (v) {
                              setState(() => _baseFreq = v);
                              runtime.setFrequency(v);
                              _pushEditablePresetToEngine(
                                session: session,
                                isRunning: isRunning,
                              );
                            },
                          ),
                          Text('Base Amp: ${_baseAmp.toStringAsFixed(3)}'),
                          Slider(
                            value: _baseAmp,
                            min: 0.0,
                            max: 1.0,
                            divisions: 100,
                            onChanged: (v) {
                              setState(() => _baseAmp = v);
                              runtime.setAmplitude(v);
                              _pushEditablePresetToEngine(
                                session: session,
                                isRunning: isRunning,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text('Modules:', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Subthreshold'),
                              const Spacer(),
                              Switch(
                                value: _subthreshold,
                                onChanged: (v) {
                                  setState(() => _subthreshold = v);
                                  _pushEditablePresetToEngine(
                                    session: session,
                                    isRunning: isRunning,
                                  );
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('RMP'),
                              const Spacer(),
                              Switch(
                                value: _rmp,
                                onChanged: (v) {
                                  setState(() => _rmp = v);
                                  _pushEditablePresetToEngine(
                                    session: session,
                                    isRunning: isRunning,
                                  );
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('PIP'),
                              const Spacer(),
                              Switch(
                                value: _pip,
                                onChanged: (v) {
                                  setState(() => _pip = v);
                                  _pushEditablePresetToEngine(
                                    session: session,
                                    isRunning: isRunning,
                                  );
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('SSS'),
                              const Spacer(),
                              Switch(
                                value: _sss,
                                onChanged: (v) {
                                  setState(() => _sss = v);
                                  _pushEditablePresetToEngine(
                                    session: session,
                                    isRunning: isRunning,
                                  );
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('Binaural'),
                              const Spacer(),
                              Switch(
                                value: _binaural,
                                onChanged: (v) {
                                  setState(() => _binaural = v);
                                  _pushEditablePresetToEngine(
                                    session: session,
                                    isRunning: isRunning,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_rmp)
                            Text(
                              'RMP enabled (rate=${_rmpRate.toStringAsFixed(2)}, depth=${_rmpDepth.toStringAsFixed(3)})',
                            ),
                          if (_pip) ...[
                            Text(
                              'PIP interval updated to ${(_pipInterval * 1000.0).toStringAsFixed(0)} ms',
                            ),
                            Text(
                              'PIP duration updated to ${(_pipDuration * 1000.0).toStringAsFixed(0)} ms',
                            ),
                          ],
                        ],
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
                const SizedBox(height: 16),
                TherapyModulesMetersPanel(
                  runtime: runtime,
                  isRunning: isRunning,
                  intensityProvider: () => session.intensity.value,
                  elapsedSecondsProvider: () => session.elapsedSeconds.value,
                  subthresholdEnabled: _subthreshold,
                  rmpEnabled: _rmp,
                  pipEnabled: _pip,
                  sssEnabled: _sss,
                  binauralEnabled: _binaural,
                  rmpDepth: _rmpDepth,
                  rmpRate: _rmpRate,
                  pipIntervalSeconds: _pipInterval,
                  pipDurationSeconds: _pipDuration,
                  sidebandOffset: _sidebandOffset,
                  sidebandIntensity: _sidebandIntensity,
                  binauralOffset: _binauralOffset,
                ),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () {
                    if (isRunning) {
                      session.stopSession();
                    } else {
                      if (_selectedPreset == null) return;
                      final p = _selectedPreset!;
                      // Ensure runtime "live settings" match the editable parameters.
                      runtime.setFrequency(_baseFreq);
                      runtime.setAmplitude(_baseAmp);

                      _logPresetConfiguration(p);
                      session.startSession(
                        subthreshold: _subthreshold,
                        rmp: _rmp,
                        pip: _pip,
                        sidebands: _sss,
                        binaural: _binaural,
                        baseFreq: _baseFreq,
                        baseAmp: _baseAmp,
                        maxIntensity: _intensity,
                        durationMinutes: _selectedDurationMinutes,
                        targetRmpDepth: _rmpDepth,
                        targetRmpRate: _rmpRate,
                        targetPipInterval: _pipInterval,
                        targetPipDuration: _pipDuration,
                        targetSidebandOffset: _sidebandOffset,
                        targetSidebandIntensity: _sidebandIntensity,
                        targetBinauralOffset: _binauralOffset,
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
