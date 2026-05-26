import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../session/audio_runtime_controller.dart';
import '../../session/phase3_module_type.dart';
import '../../session/therapy_session_controller.dart';
import '../../storage/detected_frequency_storage.dart';

/// Phase 3 — RMP, PIP, and Binaural on the Phase-1 amplitude envelope.
class Phase3ModulesScreen extends StatefulWidget {
  const Phase3ModulesScreen({super.key});

  @override
  State<Phase3ModulesScreen> createState() => _Phase3ModulesScreenState();
}

class _Phase3ModulesScreenState extends State<Phase3ModulesScreen> {
  late final AudioRuntimeController _runtime;

  double? _tinnitusFrequencyHz;
  bool _loadingFrequency = true;

  Phase3ModuleType _module = Phase3ModuleType.rmp;

  int _durationMinutes = 10;
  int _maxIntensityPercent = 20;

  // RMP
  int _rmpMinDepthPercent = 20;
  int _rmpMaxDepthPercent = 60;
  double _rmpChangeRateHz = 1.0;

  // PIP
  int _pipPulseMs = 500;
  int _pipPauseMs = 300;
  PipPulseShape _pipShape = PipPulseShape.sine;

  // Binaural
  int _binauralBeatOffsetHz = 10;
  int _binauralCarrierHz = 440;
  int _binauralStereoSpreadPercent = 100;

  double _sessionDisplayBaseAmp = 0.15;

  static final List<int> _percentStep5 =
      List<int>.generate(21, (int i) => i * 5);
  static final List<int> _pipMsSteps =
      List<int>.generate(40, (int i) => 50 + i * 50); // 50..2000
  static final List<int> _carrierSteps =
      List<int>.generate(191, (int i) => 100 + i * 10); // 100..2000
  static final List<int> _beatOffsetSteps =
      List<int>.generate(40, (int i) => i + 1); // 1..40
  static final List<int> _stereoSpreadSteps =
      List<int>.generate(11, (int i) => i * 10); // 0..100

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

  String _pipShapeLabel(PipPulseShape shape) {
    switch (shape) {
      case PipPulseShape.sine:
        return 'Sine';
      case PipPulseShape.square:
        return 'Square';
      case PipPulseShape.ramp:
        return 'Ramp';
    }
  }

  double _engineBaseFreq() {
    if (_module == Phase3ModuleType.binaural) {
      return _binauralCarrierHz.toDouble();
    }
    return _tinnitusFrequencyHz ?? _runtime.frequency.value;
  }

  /// Native RMP uses a single depth cap; we pass max depth (min shown in UI).
  double _engineRmpDepth() => (_rmpMaxDepthPercent / 100.0).clamp(0.0, 1.0);

  double _enginePipPulseSec() => _pipPulseMs / 1000.0;

  double _enginePipPauseSec() => _pipPauseMs / 1000.0;

  String _moduleParamsSummary(TherapySessionController session) {
    switch (_module) {
      case Phase3ModuleType.rmp:
        return 'min=$_rmpMinDepthPercent%, max=$_rmpMaxDepthPercent%, '
            'rate=${session.targetRmpRate.toStringAsFixed(1)} Hz';
      case Phase3ModuleType.pip:
        return 'pulse=${_pipPulseMs}ms, pause=${_pipPauseMs}ms, '
            'shape=${_pipShapeLabel(_pipShape)}';
      case Phase3ModuleType.binaural:
        return 'offset=${session.targetBinauralOffset.toStringAsFixed(0)} Hz, '
            'carrier=${_formatHz(session.baseFreq)} Hz, '
            'spread=$_binauralStereoSpreadPercent%';
    }
  }

  void _startSession(TherapySessionController session) {
    final double baseFreq = _engineBaseFreq();
    final double baseAmp = _runtime.amplitude.value;
    setState(() => _sessionDisplayBaseAmp = baseAmp);

    final bool enableRmp = _module == Phase3ModuleType.rmp;
    final bool enablePip = _module == Phase3ModuleType.pip;
    final bool enableBinaural = _module == Phase3ModuleType.binaural;

    session.startSession(
      subthreshold: false,
      rmp: enableRmp,
      pip: enablePip,
      sidebands: false,
      binaural: enableBinaural,
      baseFreq: baseFreq,
      baseAmp: baseAmp,
      maxIntensity: _maxIntensity01(),
      durationMinutes: _durationMinutes,
      targetRmpDepth: _engineRmpDepth(),
      targetRmpRate: _rmpChangeRateHz,
      targetPipInterval: _enginePipPauseSec(),
      targetPipDuration: _enginePipPulseSec(),
      targetBinauralOffset: _binauralBeatOffsetHz.toDouble(),
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
            appBar: AppBar(title: const Text('Phase 3 Modules')),
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
          appBar: AppBar(title: const Text('Phase 3 Modules')),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Module',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<Phase3ModuleType>(
            segments: const <ButtonSegment<Phase3ModuleType>>[
              ButtonSegment<Phase3ModuleType>(
                value: Phase3ModuleType.rmp,
                label: Text('RMP'),
              ),
              ButtonSegment<Phase3ModuleType>(
                value: Phase3ModuleType.pip,
                label: Text('PIP'),
              ),
              ButtonSegment<Phase3ModuleType>(
                value: Phase3ModuleType.binaural,
                label: Text('Binaural'),
              ),
            ],
            selected: <Phase3ModuleType>{_module},
            onSelectionChanged: (Set<Phase3ModuleType> next) {
              setState(() => _module = next.first);
            },
          ),
          const SizedBox(height: 16),
          if (_module == Phase3ModuleType.rmp) ..._buildRmpParams(context),
          if (_module == Phase3ModuleType.pip) ..._buildPipParams(context),
          if (_module == Phase3ModuleType.binaural) ..._buildBinauralParams(context),
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
          const SizedBox(height: 24),
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

  List<Widget> _buildRmpParams(BuildContext context) {
    return <Widget>[
      _paramDropdown<int>(
        label: 'Min Depth (%)',
        value: _rmpMinDepthPercent,
        items: _percentStep5,
        format: (int v) => '$v %',
        onChanged: (int? v) {
          if (v == null) return;
          setState(() {
            _rmpMinDepthPercent = v;
            if (_rmpMaxDepthPercent < _rmpMinDepthPercent) {
              _rmpMaxDepthPercent = _rmpMinDepthPercent;
            }
          });
        },
      ),
      const SizedBox(height: 12),
      _paramDropdown<int>(
        label: 'Max Depth (%)',
        value: _rmpMaxDepthPercent,
        items: _percentStep5.where((int p) => p >= _rmpMinDepthPercent).toList(),
        format: (int v) => '$v %',
        onChanged: (int? v) {
          if (v == null) return;
          setState(() => _rmpMaxDepthPercent = v);
        },
      ),
      const SizedBox(height: 12),
      _paramDropdown<double>(
        label: 'Change Rate (Hz)',
        value: _rmpChangeRateHz,
        items: List<double>.generate(50, (int i) => 0.1 + i * 0.1),
        format: (double v) => v.toStringAsFixed(1),
        onChanged: (double? v) {
          if (v == null) return;
          setState(() => _rmpChangeRateHz = v);
        },
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildPipParams(BuildContext context) {
    return <Widget>[
      _paramDropdown<int>(
        label: 'Pulse Duration (ms)',
        value: _pipPulseMs,
        items: _pipMsSteps,
        format: (int v) => '$v',
        onChanged: (int? v) {
          if (v == null) return;
          setState(() => _pipPulseMs = v);
        },
      ),
      const SizedBox(height: 12),
      _paramDropdown<int>(
        label: 'Pause Duration (ms)',
        value: _pipPauseMs,
        items: _pipMsSteps,
        format: (int v) => '$v',
        onChanged: (int? v) {
          if (v == null) return;
          setState(() => _pipPauseMs = v);
        },
      ),
      const SizedBox(height: 12),
      _paramDropdown<PipPulseShape>(
        label: 'Pulse Shape',
        value: _pipShape,
        items: PipPulseShape.values,
        format: _pipShapeLabel,
        onChanged: (PipPulseShape? v) {
          if (v == null) return;
          setState(() => _pipShape = v);
        },
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildBinauralParams(BuildContext context) {
    return <Widget>[
      _paramDropdown<int>(
        label: 'Beat Offset (Hz)',
        value: _binauralBeatOffsetHz,
        items: _beatOffsetSteps,
        format: (int v) => '$v',
        onChanged: (int? v) {
          if (v == null) return;
          setState(() => _binauralBeatOffsetHz = v);
        },
      ),
      const SizedBox(height: 12),
      _paramDropdown<int>(
        label: 'Carrier Frequency (Hz)',
        value: _binauralCarrierHz,
        items: _carrierSteps,
        format: (int v) => '$v',
        onChanged: (int? v) {
          if (v == null) return;
          setState(() => _binauralCarrierHz = v);
        },
      ),
      const SizedBox(height: 12),
      _paramDropdown<int>(
        label: 'Stereo Spread (%)',
        value: _binauralStereoSpreadPercent,
        items: _stereoSpreadSteps,
        format: (int v) => '$v %',
        onChanged: (int? v) {
          if (v == null) return;
          setState(() => _binauralStereoSpreadPercent = v);
        },
      ),
      const SizedBox(height: 12),
    ];
  }

  Widget _paramDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) format,
    required ValueChanged<T?> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DropdownButton<T>(
              value: value,
              items: items
                  .map(
                    (T item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(format(item)),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSession(BuildContext context, TherapySessionController session) {
    final double displayFreq =
        _module == Phase3ModuleType.binaural ? session.baseFreq : (_tinnitusFrequencyHz ?? session.baseFreq);

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
                      Text('${_formatHz(displayFreq)} Hz'),
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
                      const Expanded(child: Text('Module Params')),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _moduleParamsSummary(session),
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
