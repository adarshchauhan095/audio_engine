import 'dart:async';

import '../session/audio_runtime_controller.dart';

/// Clickless control surface for the Therapy Engine Demo.
///
/// This is intentionally separate from [TherapySessionController]:
/// - no timers/phases
/// - no adherence tracking
/// - focuses only on smoothing transitions to prevent artifacts
class TherapyDemoController {
  TherapyDemoController(this._runtime);

  final AudioRuntimeController _runtime;

  bool _active = false;
  int _token = 0;

  static const Duration _toggleFade = Duration(milliseconds: 50);
  static const Duration _paramSlew = Duration(milliseconds: 25);

  bool get isActive => _active;

  Future<void> start({
    required bool subthreshold,
    required bool rmp,
    required bool pip,
    required bool sidebands,
    required bool binaural,
    required double intensity,
    required double baseFreq,
    required double baseAmp,
    required double rmpDepth,
    required double rmpRate,
    required double pipInterval,
    required double pipDuration,
    required double sidebandOffset,
    required double sidebandIntensity,
    required double binauralOffset,
  }) async {
    if (!_runtime.hasEngine) return;
    if (_active) return;
    _active = true;

    // Ensure transport is running (native has its own transport ramp).
    if (!_runtime.playing.value) {
      _runtime.togglePlay();
      // Give start a tiny moment to settle before enabling therapy DSP.
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    // Start therapy at silence, then ramp intensity to target.
    _runtime.engine?.therapyStart(
      subthreshold: subthreshold,
      rmp: rmp,
      pip: pip,
      sidebands: sidebands,
      binaural: binaural,
      intensity: 0.0,
      baseFreq: baseFreq,
      baseAmp: baseAmp,
      rmpDepth: rmpDepth,
      rmpRate: rmpRate,
      pipInterval: pipInterval,
      pipDuration: pipDuration,
      sidebandOffset: sidebandOffset,
      sidebandIntensity: sidebandIntensity,
      binauralOffset: binauralOffset,
    );

    final int token = ++_token;
    await _rampUpdate(
      token: token,
      duration: _toggleFade,
      subthreshold: subthreshold,
      rmp: rmp,
      pip: pip,
      sidebands: sidebands,
      binaural: binaural,
      intensityFrom: 0.0,
      intensityTo: intensity,
      baseFreqFrom: baseFreq,
      baseFreqTo: baseFreq,
      baseAmpFrom: baseAmp,
      baseAmpTo: baseAmp,
      rmpDepthFrom: rmpDepth,
      rmpDepthTo: rmpDepth,
      rmpRateFrom: rmpRate,
      rmpRateTo: rmpRate,
      pipIntervalFrom: pipInterval,
      pipIntervalTo: pipInterval,
      pipDurationFrom: pipDuration,
      pipDurationTo: pipDuration,
      sidebandOffsetFrom: sidebandOffset,
      sidebandOffsetTo: sidebandOffset,
      sidebandIntensityFrom: sidebandIntensity,
      sidebandIntensityTo: sidebandIntensity,
      binauralOffsetFrom: binauralOffset,
      binauralOffsetTo: binauralOffset,
    );
  }

  Future<void> stop({
    required bool subthreshold,
    required bool rmp,
    required bool pip,
    required bool sidebands,
    required bool binaural,
    required double intensity,
    required double baseFreq,
    required double baseAmp,
    required double rmpDepth,
    required double rmpRate,
    required double pipInterval,
    required double pipDuration,
    required double sidebandOffset,
    required double sidebandIntensity,
    required double binauralOffset,
  }) async {
    if (!_active) return;
    final int token = ++_token;
    await _rampUpdate(
      token: token,
      duration: _toggleFade,
      subthreshold: subthreshold,
      rmp: rmp,
      pip: pip,
      sidebands: sidebands,
      binaural: binaural,
      intensityFrom: intensity,
      intensityTo: 0.0,
      baseFreqFrom: baseFreq,
      baseFreqTo: baseFreq,
      baseAmpFrom: baseAmp,
      baseAmpTo: baseAmp,
      rmpDepthFrom: rmpDepth,
      rmpDepthTo: rmpDepth,
      rmpRateFrom: rmpRate,
      rmpRateTo: rmpRate,
      pipIntervalFrom: pipInterval,
      pipIntervalTo: pipInterval,
      pipDurationFrom: pipDuration,
      pipDurationTo: pipDuration,
      sidebandOffsetFrom: sidebandOffset,
      sidebandOffsetTo: sidebandOffset,
      sidebandIntensityFrom: sidebandIntensity,
      sidebandIntensityTo: sidebandIntensity,
      binauralOffsetFrom: binauralOffset,
      binauralOffsetTo: binauralOffset,
    );

    _runtime.engine?.therapyStop();
    if (_runtime.playing.value) {
      _runtime.stopPlayback();
    }
    _active = false;
  }

  Future<void> update({
    required bool oldSubthreshold,
    required bool oldRmp,
    required bool oldPip,
    required bool oldSidebands,
    required bool oldBinaural,
    required double oldIntensity,
    required double oldBaseFreq,
    required double oldBaseAmp,
    required double oldRmpDepth,
    required double oldRmpRate,
    required double oldPipInterval,
    required double oldPipDuration,
    required double oldSidebandOffset,
    required double oldSidebandIntensity,
    required double oldBinauralOffset,
    required bool subthreshold,
    required bool rmp,
    required bool pip,
    required bool sidebands,
    required bool binaural,
    required double intensity,
    required double baseFreq,
    required double baseAmp,
    required double rmpDepth,
    required double rmpRate,
    required double pipInterval,
    required double pipDuration,
    required double sidebandOffset,
    required double sidebandIntensity,
    required double binauralOffset,
  }) async {
    if (!_active) return;
    final bool togglesChanged = oldSubthreshold != subthreshold ||
        oldRmp != rmp ||
        oldPip != pip ||
        oldSidebands != sidebands ||
        oldBinaural != binaural;

    final int token = ++_token;

    if (togglesChanged) {
      await _rampUpdate(
        token: token,
        duration: _toggleFade,
        subthreshold: oldSubthreshold,
        rmp: oldRmp,
        pip: oldPip,
        sidebands: oldSidebands,
        binaural: oldBinaural,
        intensityFrom: oldIntensity,
        intensityTo: 0.0,
        baseFreqFrom: oldBaseFreq,
        baseFreqTo: oldBaseFreq,
        baseAmpFrom: oldBaseAmp,
        baseAmpTo: oldBaseAmp,
        rmpDepthFrom: oldRmpDepth,
        rmpDepthTo: oldRmpDepth,
        rmpRateFrom: oldRmpRate,
        rmpRateTo: oldRmpRate,
        pipIntervalFrom: oldPipInterval,
        pipIntervalTo: oldPipInterval,
        pipDurationFrom: oldPipDuration,
        pipDurationTo: oldPipDuration,
        sidebandOffsetFrom: oldSidebandOffset,
        sidebandOffsetTo: oldSidebandOffset,
        sidebandIntensityFrom: oldSidebandIntensity,
        sidebandIntensityTo: oldSidebandIntensity,
        binauralOffsetFrom: oldBinauralOffset,
        binauralOffsetTo: oldBinauralOffset,
      );
    }

    await _rampUpdate(
      token: token,
      duration: _paramSlew,
      subthreshold: subthreshold,
      rmp: rmp,
      pip: pip,
      sidebands: sidebands,
      binaural: binaural,
      intensityFrom: togglesChanged ? 0.0 : oldIntensity,
      intensityTo: intensity,
      baseFreqFrom: oldBaseFreq,
      baseFreqTo: baseFreq,
      baseAmpFrom: oldBaseAmp,
      baseAmpTo: baseAmp,
      rmpDepthFrom: oldRmpDepth,
      rmpDepthTo: rmpDepth,
      rmpRateFrom: oldRmpRate,
      rmpRateTo: rmpRate,
      pipIntervalFrom: oldPipInterval,
      pipIntervalTo: pipInterval,
      pipDurationFrom: oldPipDuration,
      pipDurationTo: pipDuration,
      sidebandOffsetFrom: oldSidebandOffset,
      sidebandOffsetTo: sidebandOffset,
      sidebandIntensityFrom: oldSidebandIntensity,
      sidebandIntensityTo: sidebandIntensity,
      binauralOffsetFrom: oldBinauralOffset,
      binauralOffsetTo: binauralOffset,
    );
  }

  Future<void> _rampUpdate({
    required int token,
    required Duration duration,
    required bool subthreshold,
    required bool rmp,
    required bool pip,
    required bool sidebands,
    required bool binaural,
    required double intensityFrom,
    required double intensityTo,
    required double baseFreqFrom,
    required double baseFreqTo,
    required double baseAmpFrom,
    required double baseAmpTo,
    required double rmpDepthFrom,
    required double rmpDepthTo,
    required double rmpRateFrom,
    required double rmpRateTo,
    required double pipIntervalFrom,
    required double pipIntervalTo,
    required double pipDurationFrom,
    required double pipDurationTo,
    required double sidebandOffsetFrom,
    required double sidebandOffsetTo,
    required double sidebandIntensityFrom,
    required double sidebandIntensityTo,
    required double binauralOffsetFrom,
    required double binauralOffsetTo,
  }) async {
    const int steps = 6;
    final int stepMs =
        (duration.inMilliseconds / steps).clamp(1, 1000).toInt();

    double lerp(double a, double b, double t) => a + (b - a) * t;

    for (int i = 0; i <= steps; i++) {
      if (!_active || token != _token) return;
      final double t = i / steps;
      _runtime.engine?.therapyUpdate(
        subthreshold: subthreshold,
        rmp: rmp,
        pip: pip,
        sidebands: sidebands,
        binaural: binaural,
        intensity: lerp(intensityFrom, intensityTo, t),
        baseFreq: lerp(baseFreqFrom, baseFreqTo, t),
        baseAmp: lerp(baseAmpFrom, baseAmpTo, t),
        rmpDepth: lerp(rmpDepthFrom, rmpDepthTo, t),
        rmpRate: lerp(rmpRateFrom, rmpRateTo, t),
        pipInterval: lerp(pipIntervalFrom, pipIntervalTo, t),
        pipDuration: lerp(pipDurationFrom, pipDurationTo, t),
        sidebandOffset: lerp(sidebandOffsetFrom, sidebandOffsetTo, t),
        sidebandIntensity: lerp(sidebandIntensityFrom, sidebandIntensityTo, t),
        binauralOffset: lerp(binauralOffsetFrom, binauralOffsetTo, t),
      );
      if (i < steps) {
        await Future<void>.delayed(Duration(milliseconds: stepMs));
      }
    }
  }

  void dispose() {
    _active = false;
    _token++;
  }
}

