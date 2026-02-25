import 'dart:async';
import 'dart:math' as math;

import '../engine/audio_engine.dart';

/// Optional orchestrator for session-style debug scenarios.
///
/// Existing app behavior is unchanged unless one of these methods is called.
class SessionController {
  SessionController({
    required AudioEngine engine,
    required void Function(double frequencyHz) onFrequencyChanged,
    required void Function(double amplitude) onAmplitudeChanged,
    required void Function(bool playing) onPlayingChanged,
  }) : _engine = engine,
       _onFrequencyChanged = onFrequencyChanged,
       _onAmplitudeChanged = onAmplitudeChanged,
       _onPlayingChanged = onPlayingChanged;

  final AudioEngine _engine;
  final void Function(double frequencyHz) _onFrequencyChanged;
  final void Function(double amplitude) _onAmplitudeChanged;
  final void Function(bool playing) _onPlayingChanged;

  bool _disposed = false;
  bool _testInProgress = false;

  bool get testInProgress => _testInProgress;

  Future<void> runSequenceTest() async {
    if (_testInProgress || _disposed) return;
    _testInProgress = true;
    _ensurePlaying();
    // const sequence = <double>[261.6, 261.6, 293.7, 261.6, 349.2, 329.6, 261.6, 261.6, 293.7, 261.6, 392.0, 349.2, 261.6, 261.6, 523.3, 440.0, 349.2, 329.6, 293.7, 466.2, 466.2, 440.0, 349.2, 392.0, 349.2, 261.6, 261.6, 293.7, 261.6, 349.2, 329.6, 261.6, 261.6, 293.7, 261.6, 392.0, 349.2, 261.6, 261.6, 523.3, 440.0, 349.2, 329.6, 293.7, 466.2, 466.2, 440.0, 349.2, 392.0, 349.2, 261.6, 261.6, 293.7, 261.6, 349.2, 329.6, 261.6, 261.6, 293.7, 261.6, 392.0, 349.2, 261.6, 261.6, 523.3, 440.0, 349.2, 329.6, 293.7, 466.2, 466.2, 440.0, 349.2, 392.0, 349.2, 261.6, 261.6, 293.7, 261.6, 349.2, 329.6, 261.6, 261.6, 293.7, 261.6, 392.0, 349.2, 261.6, 261.6, 523.3, 440.0, 349.2, 329.6, 293.7, 466.2, 466.2, 440.0, 349.2, 392.0, 349.2, 261.6, 261.6, 293.7, 261.6, 349.2, 329.6, 261.6, 261.6, 293.7, 261.6, 392.0, 349.2, 261.6, 261.6, 523.3, 440.0, 349.2, 329.6, 293.7, 466.2, 466.2, 440.0, 349.2, 392.0, 349.2, 261.6, 261.6, 293.7, 261.6, 349.2, 329.6, 261.6, 261.6, 293.7, 261.6, 392.0, 349.2, 261.6, 261.6, 523.3, 440.0, 349.2, 329.6, 293.7, 466.2, 466.2, 440.0, 349.2, 392.0, 349.2, 261.6, 261.6, 293.7, 261.6, 349.2, 329.6, 261.6, 261.6, 293.7, 261.6, 392.0, 349.2, 261.6, 261.6, 523.3, 440.0, 349.2, 329.6, 293.7, 466.2, 466.2, 440.0, 349.2, 392.0, 349.2, 261.6, 261.6, 293.7, 261.6, 349.2, 329.6, 261.6, 261.6, 293.7, 261.6, 392.0, 349.2, 261.6, 261.6, 523.3, 440.0, 349.2, 329.6, 293.7, 466.2, 466.2, 440.0, 349.2, 392.0, 349.2, 261.6, 261.6, 293.7, 261.6, 349.2, 329.6, 261.6, 261.6, 293.7, 261.6, 392.0, 349.2, 261.6, 261.6, 523.3, 440.0, 349.2, 329.6, 293.7, 466.2, 466.2, 440.0, 349.2, 392.0, 349.2];
    const sequence = <double>[415.3, 415.3, 466.2, 466.2, 415.3, 415.3, 466.2, 466.2, 369.9, 415.3, 415.3, 415.3, 415.3, 415.3, 415.3];
    for (final hz in sequence) {
      if (_disposed) break;
      _engine.setFrequency(hz);
      _onFrequencyChanged(hz);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    _testInProgress = false;
  }

  Future<void> runAdaptiveTest() async {
    if (_testInProgress || _disposed) return;
    _testInProgress = true;
    _ensurePlaying();

    const int steps = 60;
    for (int i = 0; i < steps; i++) {
      if (_disposed) break;
      final t = i / (steps - 1);
      final hz = 220.0 + 440.0 * (0.5 + 0.5 * math.sin(t * math.pi * 4.0));
      final amp = 0.2 + 0.5 * (0.5 + 0.5 * math.cos(t * math.pi * 2.0));
      _engine.setFrequency(hz);
      _engine.setAmplitude(amp);
      _onFrequencyChanged(hz);
      _onAmplitudeChanged(amp);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    _testInProgress = false;
  }

  Future<void> runLongRunStabilityTest() async {
    if (_testInProgress || _disposed) return;
    _testInProgress = true;
    _ensurePlaying();

    const int steps = 120;
    for (int i = 0; i < steps; i++) {
      if (_disposed) break;
      final t = i / (steps - 1);
      final hz = 180.0 + 600.0 * t;
      final amp = 0.25 + 0.25 * (0.5 + 0.5 * math.sin(t * math.pi * 8.0));
      _engine.setFrequency(hz);
      _engine.setAmplitude(amp);
      _onFrequencyChanged(hz);
      _onAmplitudeChanged(amp);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    _testInProgress = false;
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
