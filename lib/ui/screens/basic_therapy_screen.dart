import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../session/audio_runtime_controller.dart';
import '../../session/therapy_session_controller.dart';
import '../../storage/detected_frequency_storage.dart';

class BasicTherapyScreen extends StatefulWidget {
  const BasicTherapyScreen({super.key});

  @override
  State<BasicTherapyScreen> createState() => _BasicTherapyScreenState();
}

class _BasicTherapyScreenState extends State<BasicTherapyScreen> {
  late final AudioRuntimeController _runtime;

  double? _tinnitusFrequencyHz;
  bool _loadingFrequency = true;

  int _durationMinutes = 10; // default per spec
  int _maxIntensityPercent = 20; // 0–50 step 5, default 20

  @override
  void initState() {
    super.initState();
    _runtime = AudioRuntimeController();
    _runtime.attachRouteRecoveryChannel(
      ServicesBinding.instance.defaultBinaryMessenger,
    );
    _runtime.prepareForAdaptiveTherapy();
    _loadTinnitusFrequency();
  }

  Future<void> _loadTinnitusFrequency() async {
    final v = await DetectedFrequencyStorage.loadDetectedFrequency();
    if (!mounted) return;
    setState(() {
      _tinnitusFrequencyHz = v;
      _loadingFrequency = false;
    });
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  double _maxIntensity01() => (_maxIntensityPercent / 100.0).clamp(0.0, 0.5);

  String _formatHz(double hz) {
    final int rounded = hz.round();
    return rounded.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _phaseLabel(TherapyPhase phase) {
    switch (phase) {
      case TherapyPhase.warmup:
        return 'RAMP-UP';
      case TherapyPhase.mainPhase:
        return 'ACTIVE';
      case TherapyPhase.cooldown:
        return 'RAMP-DOWN';
      case TherapyPhase.idle:
        return 'IDLE';
    }
  }

  void _startSession(TherapySessionController session) {
    final double baseFreq = _tinnitusFrequencyHz ?? _runtime.frequency.value;
    final double baseAmp = _runtime.amplitude.value;

    session.startSession(
      // Phase 1: core engine only — no Phase-2/extended modules.
      subthreshold: false,
      rmp: false,
      pip: false,
      sidebands: false,
      binaural: false,
      baseFreq: baseFreq,
      baseAmp: baseAmp,
      maxIntensity: _maxIntensity01(),
      durationMinutes: _durationMinutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _runtime.error,
      builder: (context, error, _) {
        if (error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Basic Therapy')),
            body: Center(
              child: Text(
                'Engine Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final session = _runtime.therapySession;
        if (session == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Basic Therapy')),
          body: ValueListenableBuilder<bool>(
            valueListenable: session.didComplete,
            builder: (context, didComplete, _) {
              if (didComplete) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Session Completed',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => session.resetCompletion(),
                          child: const Text('Back to Start'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ValueListenableBuilder<bool>(
                valueListenable: session.isRunning,
                builder: (context, isRunning, _) {
                  if (!isRunning) {
                    // IDLE / Before session
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Tinnitus Frequency',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (_loadingFrequency)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    Text(
                                      _tinnitusFrequencyHz == null
                                          ? 'Not set'
                                          : '${_formatHz(_tinnitusFrequencyHz!)} Hz',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Duration',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  DropdownButton<int>(
                                    value: _durationMinutes,
                                    items: const [5, 10, 20, 30]
                                        .map(
                                          (m) => DropdownMenuItem<int>(
                                            value: m,
                                            child: Text('$m min'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _durationMinutes = v);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Max Intensity',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text('$_maxIntensityPercent %'),
                                    ],
                                  ),
                                  Slider(
                                    value: _maxIntensityPercent.toDouble(),
                                    min: 0,
                                    max: 50,
                                    divisions: 10, // step 5
                                    label: '$_maxIntensityPercent%',
                                    onChanged: (v) => setState(
                                      () => _maxIntensityPercent = (v / 5).round() * 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _runtime.hasEngine ? () => _startSession(session) : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text('Start Session'),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  }

                  // Live session
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(child: Text('Frequency')),
                                    ValueListenableBuilder<double>(
                                      valueListenable: _runtime.frequency,
                                      builder: (context, freq, _) => Text('${_formatHz(freq)} Hz'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Expanded(child: Text('Base Amplitude')),
                                    ValueListenableBuilder<double>(
                                      valueListenable: _runtime.amplitude,
                                      builder: (context, amp, _) => Text(amp.toStringAsFixed(3)),
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
                              children: [
                                Row(
                                  children: [
                                    const Expanded(child: Text('Current Phase')),
                                    ValueListenableBuilder<TherapyPhase>(
                                      valueListenable: session.currentPhase,
                                      builder: (context, phase, _) =>
                                          Text(_phaseLabel(phase), style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Expanded(child: Text('Remaining Time')),
                                    ValueListenableBuilder<int>(
                                      valueListenable: session.remainingSeconds,
                                      builder: (context, seconds, _) {
                                        final mins = seconds ~/ 60;
                                        final secs = seconds % 60;
                                        return Text('$mins:${secs.toString().padLeft(2, '0')}');
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Expanded(child: Text('Current Intensity (%)')),
                                    ValueListenableBuilder<double>(
                                      valueListenable: session.intensity,
                                      builder: (context, intensity, _) =>
                                          Text('${(intensity * 100).toStringAsFixed(0)} %'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => session.stopSession(),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: Colors.red.shade200,
                          ),
                          child: const Text('Stop Session'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

