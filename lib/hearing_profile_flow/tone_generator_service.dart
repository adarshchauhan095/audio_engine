import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../session/audio_runtime_controller.dart';

/// Lightweight wrapper around the existing native oscillator.
///
/// Design contract:
/// - [reset]     → call when a tone screen becomes active (e.g.
///                 [Widget.initState] and [RouteAware.didPopNext] after back).
///                 Cancels any pending
///                 ramp, stops playback **immediately** (no fade), and applies
///                 the supplied frequency / level so the screen starts clean.
/// - [stopNow]   → synchronous immediate stop; used by dispose() and before
///                 navigating away so the next screen is never racing a fade.
/// - [stopFaded] → async fade-out (5–10 ms) for the Play/Stop button so the
///                 user hears a clean release instead of a click.
/// - [toggle]    → Play/Stop button action: fade-in on start, fade-out on stop.
class ToneGeneratorService {
  ToneGeneratorService(this._runtime);

  final AudioRuntimeController _runtime;

  double _frequencyHz = 440.0;
  double _level01 = 0.3;

  Timer? _rampTimer;
  bool _disposed = false;

  bool get canOutputAudio => _runtime.hasEngine && _runtime.error.value == null;
  bool get isPlaying => _runtime.playing.value;

  /// Exposes the underlying playing state as a [ValueListenable] so screens
  /// can use [ValueListenableBuilder] to keep the Play/Stop label always in
  /// sync with the actual audio state (including async fade changes).
  ValueListenable<bool> get playingNotifier => _runtime.playing;

  double get frequencyHz => _frequencyHz;
  double get level01 => _level01;

  void dispose() {
    _disposed = true;
    _rampTimer?.cancel();
    _rampTimer = null;
    stopNow();
  }

  // ---------------------------------------------------------------------------
  // Screen lifecycle helpers
  // ---------------------------------------------------------------------------

  /// Called from every screen's [initState].
  ///
  /// Immediately stops any running tone, cancels any ramp, applies the new
  /// [frequencyHz] / [level01] and resets the playing state — all synchronously
  /// so the screen always starts from a known-clean state regardless of what
  /// the previous screen was doing.
  void reset({required double frequencyHz, required double level01}) {
    _rampTimer?.cancel();
    _rampTimer = null;

    _frequencyHz = frequencyHz;
    _level01 = level01.clamp(0.0, 1.0);

    if (!_disposed && _runtime.hasEngine) {
      // Bypass the async fade: we need an immediate stop so the next screen
      // starts with silence, not a cross-fade from the previous frequency.
      if (_runtime.playing.value) {
        _runtime.engine!.stop();
        _runtime.playing.value = false;
      }
      _runtime.setFrequency(_frequencyHz);
      _runtime.setAmplitude(_level01);
    }
  }

  // ---------------------------------------------------------------------------
  // Playback control
  // ---------------------------------------------------------------------------

  /// Applies [frequencyHz] and [level01] to the engine without changing the
  /// playing state.  Any in-progress ramp is cancelled first so the values
  /// take effect immediately (prevents the 12 kHz "modulation" artefact caused
  /// by an old ramp overwriting a fresh configure call).
  void configure({required double frequencyHz, required double level01}) {
    _rampTimer?.cancel();
    _rampTimer = null;

    _frequencyHz = frequencyHz;
    _level01 = level01.clamp(0.0, 1.0);
    _runtime.setFrequency(_frequencyHz);
    _runtime.setAmplitude(_level01);
  }

  /// Starts the tone with a short fade-in.
  bool start() {
    if (_disposed) return false;
    if (!canOutputAudio) return false;
    _runtime.setFrequency(_frequencyHz);
    _runtime.setAmplitude(0.0);
    if (!_runtime.playing.value) {
      _runtime.engine!.start();
      _runtime.playing.value = true;
    }
    // Fade in to the desired level.
    _rampAmplitude(from: 0.0, to: _level01);
    return true;
  }

  /// Stops the tone immediately (no fade). Used during navigation/dispose so
  /// there is no race between the old screen's fade and the new screen's init.
  void stopNow() {
    if (_disposed) return;
    _rampTimer?.cancel();
    _rampTimer = null;
    if (_runtime.hasEngine && _runtime.playing.value) {
      _runtime.engine!.stop();
      _runtime.playing.value = false;
    }
    // Restore the user's amplitude so the next start() fades in correctly.
    if (_runtime.hasEngine) {
      _runtime.setAmplitude(_level01);
    }
  }

  /// Stops the tone with a short fade-out (5–10 ms). Used by the Play/Stop
  /// button so the release is audibly clean.
  Future<void> stopFaded() async {
    if (_disposed) return;
    _rampTimer?.cancel();
    _rampTimer = null;
    if (!_runtime.playing.value) return;

    await _rampAmplitudeFuture(
      from: _level01,
      to: 0.0,
      duration: const Duration(milliseconds: 8),
    );

    if (_disposed) return;
    if (_runtime.hasEngine && _runtime.playing.value) {
      _runtime.engine!.stop();
      _runtime.playing.value = false;
    }
    // Restore the user's amplitude so the next start() fades in correctly.
    if (_runtime.hasEngine) {
      _runtime.setAmplitude(_level01);
    }
  }

  /// Play/Stop toggle wired to the button.
  /// - If playing  → [stopFaded] (audibly clean release).
  /// - If stopped  → [start]    (fade-in).
  Future<void> toggle() async {
    if (_disposed) return;
    if (_runtime.playing.value) {
      await stopFaded();
    } else {
      start();
    }
  }

  // ---------------------------------------------------------------------------
  // Level helpers
  // ---------------------------------------------------------------------------

  void setLevelSmooth(
    double next01, {
    Duration duration = const Duration(milliseconds: 10),
  }) {
    if (_disposed) return;
    final double from = _level01.clamp(0.0, 1.0);
    final double to = next01.clamp(0.0, 1.0);
    _level01 = to;

    if (!canOutputAudio) return;
    _rampAmplitude(from: from, to: to, duration: duration);
  }

  /// Apply a logarithmic step in dB and ramp to the new level.
  double stepDb(double dbDelta) {
    final double factor = math.pow(10.0, dbDelta / 20.0).toDouble();
    final double next = (_level01 * factor).clamp(0.0, 1.0);
    setLevelSmooth(next);
    return next;
  }

  // ---------------------------------------------------------------------------
  // Internal ramp helpers
  // ---------------------------------------------------------------------------

  static const Duration _defaultRampDuration = Duration(milliseconds: 8);

  /// Fire-and-forget timer-based ramp (non-blocking).
  void _rampAmplitude({
    required double from,
    required double to,
    Duration duration = _defaultRampDuration,
  }) {
    _rampTimer?.cancel();
    _rampTimer = null;
    if (!canOutputAudio) return;

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
      _runtime.setAmplitude(v.clamp(0.0, 1.0));
      i++;
      if (i > steps) {
        t.cancel();
        _rampTimer = null;
        // Ensure we land exactly on the target.
        _runtime.setAmplitude(to.clamp(0.0, 1.0));
      }
    });
  }

  /// Awaitable version for [stopFaded] (needs to complete before stopping the
  /// engine).
  Future<void> _rampAmplitudeFuture({
    required double from,
    required double to,
    Duration duration = _defaultRampDuration,
  }) async {
    if (!canOutputAudio) return;
    const int steps = 6;
    final int stepMs = (duration.inMilliseconds / steps).clamp(1, 50).toInt();
    for (int i = 0; i <= steps; i++) {
      if (_disposed) return;
      final double t = i / steps;
      final double v = from + (to - from) * t;
      _runtime.setAmplitude(v.clamp(0.0, 1.0));
      if (i < steps) {
        await Future<void>.delayed(Duration(milliseconds: stepMs));
      }
    }
  }
}
