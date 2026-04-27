import 'dart:async';
import 'dart:math' as math;

import '../session/audio_runtime_controller.dart';

/// Lightweight wrapper around the existing native oscillator.
///
/// - Uses engine smoothing + a short ramp for level changes.
/// - Stops cleanly when leaving screens.
class ToneGeneratorService {
  ToneGeneratorService(this._runtime);

  final AudioRuntimeController _runtime;

  double _frequencyHz = 440.0;
  double _level01 = 0.3;

  Timer? _rampTimer;
  bool _disposed = false;

  bool get canOutputAudio => _runtime.hasEngine && _runtime.error.value == null;
  bool get isPlaying => _runtime.playing.value;

  double get frequencyHz => _frequencyHz;
  double get level01 => _level01;

  void dispose() {
    _disposed = true;
    _rampTimer?.cancel();
    _rampTimer = null;
    stop();
  }

  void configure({required double frequencyHz, required double level01}) {
    _frequencyHz = frequencyHz;
    _level01 = level01.clamp(0.0, 1.0);
    _runtime.setFrequency(_frequencyHz);
    _runtime.setAmplitude(_level01);
  }

  bool start() {
    if (_disposed) return false;
    if (!canOutputAudio) return false;
    _runtime.setFrequency(_frequencyHz);
    _runtime.setAmplitude(_level01);
    if (!_runtime.playing.value) {
      _runtime.togglePlay();
    }
    return true;
  }

  void stop() {
    if (_disposed) return;
    _rampTimer?.cancel();
    _rampTimer = null;
    _runtime.stopPlayback();
  }

  void toggle() {
    if (_disposed) return;
    if (_runtime.playing.value) {
      stop();
    } else {
      start();
    }
  }

  void setLevelSmooth(double next01, {Duration duration = const Duration(milliseconds: 10)}) {
    if (_disposed) return;
    final double from = _level01.clamp(0.0, 1.0);
    final double to = next01.clamp(0.0, 1.0);
    _level01 = to;

    if (!canOutputAudio) return;

    _rampTimer?.cancel();
    _rampTimer = null;

    // Small timer ramp to avoid abrupt jumps on rapid button taps.
    const int steps = 6;
    final int stepMs = (duration.inMilliseconds / steps).clamp(1, 50).toInt();
    int i = 0;
    _rampTimer = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      if (_disposed) {
        t.cancel();
        return;
      }
      final double tt = i / steps;
      final double v = from + (to - from) * tt;
      _runtime.setAmplitude(v);
      i++;
      if (i > steps) {
        t.cancel();
      }
    });
  }

  /// Apply a logarithmic step in dB (preferred).
  double stepDb(double dbDelta) {
    final double factor = math.pow(10.0, dbDelta / 20.0).toDouble();
    final double next = (_level01 * factor).clamp(0.0, 1.0);
    setLevelSmooth(next);
    return next;
  }
}

