import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../session/audio_runtime_controller.dart';
import '../../session/therapy_modulation_mode.dart';
import '../../session/therapy_session_controller.dart';
import '../../storage/detected_frequency_storage.dart';

/// Phase 2 — modulation layer (AM / FM / NBN) with the same core envelope as Phase 1.
class ModulationTherapyScreen extends StatefulWidget {
  const ModulationTherapyScreen({super.key});

  @override
  State<ModulationTherapyScreen> createState() => _ModulationTherapyScreenState();
}

class _ModulationTherapyScreenState extends State<ModulationTherapyScreen> {
  late final AudioRuntimeController _runtime;

  double? _tinnitusFrequencyHz;
  bool _loadingFrequency = true;

  TherapyModulationMode _modulationMode = TherapyModulationMode.am;

  int _durationMinutes = 10;
  int _maxIntensityPercent = 20;

  int _amDepthPercent = 50;
  double _amRateHz = 10;

  int _fmDeviationHz = 100;
  double _fmRateHz = 8;

  int _nbnBandwidthHz = 200;
  int _nbnDepthPercent = 30;

  /// Snapshot for read-only “Base Amplitude” during a session.
  double _sessionDisplayBaseAmp = 0.15;

  static final List<int> _percentStep5Full =
      List<int>.generate(21, (int i) => i * 5); // 0..100 depth
  static final List<double> _rateHalfSteps =
      List<double>.generate(40, (int i) => 0.5 + i * 0.5); // 0.5..20
  static final List<int> _fmDeviationSteps =
      List<int>.generate(50, (int i) => 10 + i * 10); // 10..500
  static final List<int> _nbnBandwidthSteps =
      List<int>.generate(20, (int i) => 50 + i * 50); // 50..1000

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
    final double? v = await DetectedFrequencyStorage.loadDetectedFrequency();
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
      (Match m) => '${m[1]},',
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

  String _modulationSummary(TherapySessionController session) {
    switch (session.modulationMode) {
      case TherapyModulationMode.none:
        return '—';
      case TherapyModulationMode.am:
        return 'depth=${session.liveAmDepthPercent.toStringAsFixed(0)}%, '
            'rate=${session.liveAmRateHz.toStringAsFixed(1)} Hz';
      case TherapyModulationMode.fm:
        return 'deviation=${session.liveFmDeviationHz.toStringAsFixed(0)} Hz, '
            'rate=${session.liveFmRateHz.toStringAsFixed(1)} Hz';
      case TherapyModulationMode.nbn:
        return 'bandwidth=${session.liveNbnBandwidthHz.toStringAsFixed(0)} Hz, '
            'depth=${session.liveNbnDepthPercent.toStringAsFixed(0)}%';
    }
  }

  void _startSession(TherapySessionController session) {
    final double baseFreq = _tinnitusFrequencyHz ?? _runtime.frequency.value;
    final double baseAmp = _runtime.amplitude.value;
    setState(() => _sessionDisplayBaseAmp = baseAmp);

    session.startSession(
      subthreshold: false,
      rmp: false,
      pip: false,
      sidebands: false,
      binaural: false,
      baseFreq: baseFreq,
      baseAmp: baseAmp,
      maxIntensity: _maxIntensity01(),
      durationMinutes: _durationMinutes,
      modulationMode: _modulationMode,
      amDepthPercent: _amDepthPercent.toDouble(),
      amRateHz: _amRateHz,
      fmDeviationHz: _fmDeviationHz.toDouble(),
      fmRateHz: _fmRateHz,
      nbnBandwidthHz: _nbnBandwidthHz.toDouble(),
      nbnDepthPercent: _nbnDepthPercent.toDouble(),
    );
  }

  void _onBackToStart(TherapySessionController session) {
    session.resetCompletion();
    _runtime.prepareForAdaptiveTherapy();
    unawaited(_loadTinnitusFrequency());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _runtime.error,
      builder: (BuildContext context, String? error, _) {
        if (error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Modulation Therapy')),
            body: Center(
              child: Text(
                'Engine Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final TherapySessionController? session = _runtime.therapySession;
        if (session == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Modulation Therapy')),
          body: ValueListenableBuilder<bool>(
            valueListenable: session.didComplete,
            builder: (BuildContext context, bool didComplete, _) {
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
                          onPressed: () => _onBackToStart(session),
                          child: const Text('Back to Start'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ValueListenableBuilder<bool>(
                valueListenable: session.isRunning,
                builder: (BuildContext context, bool isRunning, _) {
                  if (!isRunning) {
                    return _buildIdle(context, session);
                  }
                  return _buildLiveSession(context, session);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildIdle(BuildContext context, TherapySessionController session) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Modulation type',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<TherapyModulationMode>(
            segments: const <ButtonSegment<TherapyModulationMode>>[
              ButtonSegment<TherapyModulationMode>(
                value: TherapyModulationMode.am,
                label: Text('AM'),
              ),
              ButtonSegment<TherapyModulationMode>(
                value: TherapyModulationMode.fm,
                label: Text('FM'),
              ),
              ButtonSegment<TherapyModulationMode>(
                value: TherapyModulationMode.nbn,
                label: Text('NBN'),
              ),
            ],
            selected: <TherapyModulationMode>{_modulationMode},
            onSelectionChanged: (Set<TherapyModulationMode> next) {
              setState(() => _modulationMode = next.first);
            },
          ),
          const SizedBox(height: 16),
          if (_modulationMode == TherapyModulationMode.am) ..._buildAmParams(context),
          if (_modulationMode == TherapyModulationMode.fm) ..._buildFmParams(context),
          if (_modulationMode == TherapyModulationMode.nbn) ..._buildNbnParams(context),
          const SizedBox(height: 8),
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
                    items: const <int>[5, 10, 20, 30]
                        .map(
                          (int m) => DropdownMenuItem<int>(
                            value: m,
                            child: Text('$m min'),
                          ),
                        )
                        .toList(),
                    onChanged: (int? v) {
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
                    divisions: 10,
                    label: '$_maxIntensityPercent%',
                    onChanged: (double v) => setState(
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

  List<Widget> _buildAmParams(BuildContext context) {
    return <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Depth (%)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<int>(
                value: _amDepthPercent,
                items: _percentStep5Full
                    .map(
                      (int p) => DropdownMenuItem<int>(
                        value: p,
                        child: Text('$p %'),
                      ),
                    )
                    .toList(),
                onChanged: (int? v) {
                  if (v == null) return;
                  setState(() => _amDepthPercent = v);
                },
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
                  'Rate (Hz)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<double>(
                value: _amRateHz,
                items: _rateHalfSteps
                    .map(
                      (double r) => DropdownMenuItem<double>(
                        value: r,
                        child: Text(r.toStringAsFixed(1)),
                      ),
                    )
                    .toList(),
                onChanged: (double? v) {
                  if (v == null) return;
                  setState(() => _amRateHz = v);
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildFmParams(BuildContext context) {
    return <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Deviation (Hz)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<int>(
                value: _fmDeviationHz,
                items: _fmDeviationSteps
                    .map(
                      (int d) => DropdownMenuItem<int>(
                        value: d,
                        child: Text('$d'),
                      ),
                    )
                    .toList(),
                onChanged: (int? v) {
                  if (v == null) return;
                  setState(() => _fmDeviationHz = v);
                },
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
                  'Rate (Hz)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<double>(
                value: _fmRateHz,
                items: _rateHalfSteps
                    .map(
                      (double r) => DropdownMenuItem<double>(
                        value: r,
                        child: Text(r.toStringAsFixed(1)),
                      ),
                    )
                    .toList(),
                onChanged: (double? v) {
                  if (v == null) return;
                  setState(() => _fmRateHz = v);
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildNbnParams(BuildContext context) {
    return <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Bandwidth (Hz)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<int>(
                value: _nbnBandwidthHz,
                items: _nbnBandwidthSteps
                    .map(
                      (int b) => DropdownMenuItem<int>(
                        value: b,
                        child: Text('$b'),
                      ),
                    )
                    .toList(),
                onChanged: (int? v) {
                  if (v == null) return;
                  setState(() => _nbnBandwidthHz = v);
                },
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
                  'Modulation Depth (%)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<int>(
                value: _nbnDepthPercent,
                items: _percentStep5Full
                    .map(
                      (int p) => DropdownMenuItem<int>(
                        value: p,
                        child: Text('$p %'),
                      ),
                    )
                    .toList(),
                onChanged: (int? v) {
                  if (v == null) return;
                  setState(() => _nbnDepthPercent = v);
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  Widget _buildLiveSession(BuildContext context, TherapySessionController session) {
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
                        builder: (BuildContext context, double freq, _) =>
                            Text('${_formatHz(freq)} Hz'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Text('Base Amplitude')),
                      Text(_sessionDisplayBaseAmp.toStringAsFixed(3)),
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
                        builder: (BuildContext context, TherapyPhase phase, _) =>
                            Text(
                          _phaseLabel(phase),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Text('Remaining Time')),
                      ValueListenableBuilder<int>(
                        valueListenable: session.remainingSeconds,
                        builder: (BuildContext context, int seconds, _) {
                          final int mins = seconds ~/ 60;
                          final int secs = seconds % 60;
                          return Text(
                            '$mins:${secs.toString().padLeft(2, '0')}',
                          );
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
                        builder: (BuildContext context, double intensity, _) =>
                            Text('${(intensity * 100).toStringAsFixed(0)} %'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: Text('Modulation Params')),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _modulationSummary(session),
                          textAlign: TextAlign.end,
                        ),
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
            child: const Text('Stop'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
