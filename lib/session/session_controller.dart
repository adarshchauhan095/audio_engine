import 'dart:async';
import 'dart:math' as math;

import '../engine/audio_control.dart';

/// Optional orchestrator for session-style debug scenarios.
///
/// Existing app behavior is unchanged unless one of these methods is called.
class SessionController {
  SessionController({
    required AudioControl engine,
    required void Function(double frequencyHz) onFrequencyChanged,
    required void Function(double amplitude) onAmplitudeChanged,
    required void Function(bool playing) onPlayingChanged,
    void Function(double progress)? onProgress,
    List<double> sequenceHz = _defaultSequenceHz,
    Duration sequenceStepDelay = const Duration(milliseconds: 300),
    int adaptiveSteps = 60,
    Duration adaptiveStepDelay = const Duration(milliseconds: 80),
    int longRunSteps = 120,
    Duration longRunStepDelay = const Duration(milliseconds: 250),
  }) : _engine = engine,
       _onFrequencyChanged = onFrequencyChanged,
       _onAmplitudeChanged = onAmplitudeChanged,
       _onPlayingChanged = onPlayingChanged,
       _onProgress = onProgress,
       _sequenceHz = List<double>.from(sequenceHz),
       _sequenceStepDelay = sequenceStepDelay,
       _adaptiveSteps = adaptiveSteps,
       _adaptiveStepDelay = adaptiveStepDelay,
       _longRunSteps = longRunSteps,
       _longRunStepDelay = longRunStepDelay {
    assert(_adaptiveSteps > 0);
    assert(_longRunSteps > 0);
  }

  static const List<double> _defaultSequenceHz = <double>[
    415.3,
    415.3,
    466.2,
    466.2,
    415.3,
    415.3,
    466.2,
    466.2,
    369.9,
    415.3,
    415.3,
    415.3,
    415.3,
    415.3,
    415.3,
  ];

  final AudioControl _engine;
  final void Function(double frequencyHz) _onFrequencyChanged;
  final void Function(double amplitude) _onAmplitudeChanged;
  final void Function(bool playing) _onPlayingChanged;
  final void Function(double progress)? _onProgress;

  final List<double> _sequenceHz;
  final Duration _sequenceStepDelay;
  final int _adaptiveSteps;
  final Duration _adaptiveStepDelay;
  final int _longRunSteps;
  final Duration _longRunStepDelay;

  bool _disposed = false;
  bool _testInProgress = false;

  bool get testInProgress => _testInProgress;

  Future<void> runSequenceTest() async {
    if (_testInProgress || _disposed) return;
    _testInProgress = true;
    try {
      _ensurePlaying();
      for (int i = 0; i < _sequenceHz.length; i++) {
        final hz = _sequenceHz[i];
        if (_disposed) break;
        _onProgress?.call(i / _sequenceHz.length);
        _engine.setFrequency(hz);
        _onFrequencyChanged(hz);
        await Future<void>.delayed(_sequenceStepDelay);
      }
      _onProgress?.call(1.0);
    } finally {
      _testInProgress = false;
      _engine.stop();
      _onPlayingChanged(false);
    }
  }

  Future<void> runAdaptiveTest() async {
    if (_testInProgress || _disposed) return;
    _testInProgress = true;
    try {
      _ensurePlaying();
      for (int i = 0; i < _adaptiveSteps; i++) {
        if (_disposed) break;
        final t = i / (_adaptiveSteps - 1);
        _onProgress?.call(t);
        final hz = 220.0 + 440.0 * (0.5 + 0.5 * math.sin(t * math.pi * 4.0));
        final amp = 0.2 + 0.5 * (0.5 + 0.5 * math.cos(t * math.pi * 2.0));
        _engine.setFrequency(hz);
        _engine.setAmplitude(amp);
        _onFrequencyChanged(hz);
        _onAmplitudeChanged(amp);
        await Future<void>.delayed(_adaptiveStepDelay);
      }
      _onProgress?.call(1.0);
    } finally {
      _testInProgress = false;
      _engine.stop();
      _onPlayingChanged(false);
    }
  }

  /// [durationSeconds] if provided overrides the default run length (default ~30s).
  Future<void> runLongRunStabilityTest({int? durationSeconds}) async {
    if (_testInProgress || _disposed) return;
    _testInProgress = true;
    final int steps = durationSeconds != null
        ? (durationSeconds * 1000 / _longRunStepDelay.inMilliseconds).round().clamp(1, 600)
        : _longRunSteps;
    try {
      _ensurePlaying();
      for (int i = 0; i < steps; i++) {
        if (_disposed) break;
        final t = steps > 1 ? i / (steps - 1) : 1.0;
        _onProgress?.call(t);
        final hz = 180.0 + 600.0 * t;
        final amp = 0.25 + 0.25 * (0.5 + 0.5 * math.sin(t * math.pi * 8.0));
        _engine.setFrequency(hz);
        _engine.setAmplitude(amp);
        _onFrequencyChanged(hz);
        _onAmplitudeChanged(amp);
        await Future<void>.delayed(_longRunStepDelay);
      }
      _onProgress?.call(1.0);
    } finally {
      _testInProgress = false;
      _engine.stop();
      _onPlayingChanged(false);
    }
  }

  void dispose() {
    _disposed = true;
  }

  void _ensurePlaying() {
    if (_engine.isRunning) return;
    _engine.start();
    _onPlayingChanged(true);
  }
}
