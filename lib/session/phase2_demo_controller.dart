import 'dart:async';

import 'audio_runtime_controller.dart';

/// Clickless control surface for the Phase 2 Modulation Lab.
///
/// Mirrors the safety patterns of [TherapyDemoController]:
/// - ramps intensity on start/stop
/// - slews parameters to reduce audible discontinuities
/// - never touches profiles, sessions, or adherence
class Phase2DemoController {
  Phase2DemoController(this._runtime);

  final AudioRuntimeController _runtime;

  bool _active = false;
  int _token = 0;

  static const Duration _toggleFade = Duration(milliseconds: 80);
  static const Duration _paramSlew = Duration(milliseconds: 35);

  bool get isActive => _active;

  Future<void> start({
    required int modulationType,
    required int filterType,
    required double intensity,
    required double baseFreq,
    required double baseAmp,
    required double depth,
    required double rateHz,
    required double bandwidthHz,
    required double filterFreqHz,
    required double q,
    required double transitionMs,
  }) async {
    if (!_runtime.hasEngine) return;
    if (_active) return;
    _active = true;

    if (!_runtime.playing.value) {
      _runtime.togglePlay();
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    _runtime.engine?.phase2Start(
      modulationType: modulationType,
      filterType: filterType,
      intensity: 0.0,
      baseFreq: baseFreq,
      baseAmp: baseAmp,
      depth: depth,
      rateHz: rateHz,
      bandwidthHz: bandwidthHz,
      filterFreqHz: filterFreqHz,
      q: q,
      transitionMs: transitionMs,
    );

    final int token = ++_token;
    await _rampUpdate(
      token: token,
      duration: _toggleFade,
      modulationType: modulationType,
      filterType: filterType,
      intensityFrom: 0.0,
      intensityTo: intensity,
      baseFreqFrom: baseFreq,
      baseFreqTo: baseFreq,
      baseAmpFrom: baseAmp,
      baseAmpTo: baseAmp,
      depthFrom: depth,
      depthTo: depth,
      rateHzFrom: rateHz,
      rateHzTo: rateHz,
      bandwidthHzFrom: bandwidthHz,
      bandwidthHzTo: bandwidthHz,
      filterFreqHzFrom: filterFreqHz,
      filterFreqHzTo: filterFreqHz,
      qFrom: q,
      qTo: q,
      transitionMsFrom: transitionMs,
      transitionMsTo: transitionMs,
    );
  }

  Future<void> stop({
    required int modulationType,
    required int filterType,
    required double intensity,
    required double baseFreq,
    required double baseAmp,
    required double depth,
    required double rateHz,
    required double bandwidthHz,
    required double filterFreqHz,
    required double q,
    required double transitionMs,
  }) async {
    if (!_active) return;
    final int token = ++_token;

    await _rampUpdate(
      token: token,
      duration: _toggleFade,
      modulationType: modulationType,
      filterType: filterType,
      intensityFrom: intensity,
      intensityTo: 0.0,
      baseFreqFrom: baseFreq,
      baseFreqTo: baseFreq,
      baseAmpFrom: baseAmp,
      baseAmpTo: baseAmp,
      depthFrom: depth,
      depthTo: depth,
      rateHzFrom: rateHz,
      rateHzTo: rateHz,
      bandwidthHzFrom: bandwidthHz,
      bandwidthHzTo: bandwidthHz,
      filterFreqHzFrom: filterFreqHz,
      filterFreqHzTo: filterFreqHz,
      qFrom: q,
      qTo: q,
      transitionMsFrom: transitionMs,
      transitionMsTo: transitionMs,
    );

    _runtime.engine?.phase2Stop();
    if (_runtime.playing.value) {
      _runtime.stopPlayback();
    }
    _active = false;
  }

  Future<void> update({
    required int oldModulationType,
    required int oldFilterType,
    required double oldIntensity,
    required double oldBaseFreq,
    required double oldBaseAmp,
    required double oldDepth,
    required double oldRateHz,
    required double oldBandwidthHz,
    required double oldFilterFreqHz,
    required double oldQ,
    required double oldTransitionMs,
    required int modulationType,
    required int filterType,
    required double intensity,
    required double baseFreq,
    required double baseAmp,
    required double depth,
    required double rateHz,
    required double bandwidthHz,
    required double filterFreqHz,
    required double q,
    required double transitionMs,
  }) async {
    if (!_active) return;
    if (!_runtime.hasEngine) return;

    final bool modesChanged =
        oldModulationType != modulationType || oldFilterType != filterType;

    final int token = ++_token;

    // If modes change, fade intensity to 0, swap modes, then fade back in.
    if (modesChanged) {
      await _rampUpdate(
        token: token,
        duration: _toggleFade,
        modulationType: oldModulationType,
        filterType: oldFilterType,
        intensityFrom: oldIntensity,
        intensityTo: 0.0,
        baseFreqFrom: oldBaseFreq,
        baseFreqTo: oldBaseFreq,
        baseAmpFrom: oldBaseAmp,
        baseAmpTo: oldBaseAmp,
        depthFrom: oldDepth,
        depthTo: oldDepth,
        rateHzFrom: oldRateHz,
        rateHzTo: oldRateHz,
        bandwidthHzFrom: oldBandwidthHz,
        bandwidthHzTo: oldBandwidthHz,
        filterFreqHzFrom: oldFilterFreqHz,
        filterFreqHzTo: oldFilterFreqHz,
        qFrom: oldQ,
        qTo: oldQ,
        transitionMsFrom: oldTransitionMs,
        transitionMsTo: oldTransitionMs,
      );
    }

    await _rampUpdate(
      token: token,
      duration: _paramSlew,
      modulationType: modulationType,
      filterType: filterType,
      intensityFrom: modesChanged ? 0.0 : oldIntensity,
      intensityTo: intensity,
      baseFreqFrom: oldBaseFreq,
      baseFreqTo: baseFreq,
      baseAmpFrom: oldBaseAmp,
      baseAmpTo: baseAmp,
      depthFrom: oldDepth,
      depthTo: depth,
      rateHzFrom: oldRateHz,
      rateHzTo: rateHz,
      bandwidthHzFrom: oldBandwidthHz,
      bandwidthHzTo: bandwidthHz,
      filterFreqHzFrom: oldFilterFreqHz,
      filterFreqHzTo: filterFreqHz,
      qFrom: oldQ,
      qTo: q,
      transitionMsFrom: oldTransitionMs,
      transitionMsTo: transitionMs,
    );
  }

  Future<void> _rampUpdate({
    required int token,
    required Duration duration,
    required int modulationType,
    required int filterType,
    required double intensityFrom,
    required double intensityTo,
    required double baseFreqFrom,
    required double baseFreqTo,
    required double baseAmpFrom,
    required double baseAmpTo,
    required double depthFrom,
    required double depthTo,
    required double rateHzFrom,
    required double rateHzTo,
    required double bandwidthHzFrom,
    required double bandwidthHzTo,
    required double filterFreqHzFrom,
    required double filterFreqHzTo,
    required double qFrom,
    required double qTo,
    required double transitionMsFrom,
    required double transitionMsTo,
  }) async {
    const int steps = 6;
    final int stepMs =
        (duration.inMilliseconds / steps).clamp(1, 1000).toInt();

    double lerp(double a, double b, double t) => a + (b - a) * t;

    for (int i = 0; i <= steps; i++) {
      if (!_active || token != _token) return;
      final double t = i / steps;
      _runtime.engine?.phase2Update(
        modulationType: modulationType,
        filterType: filterType,
        intensity: lerp(intensityFrom, intensityTo, t),
        baseFreq: lerp(baseFreqFrom, baseFreqTo, t),
        baseAmp: lerp(baseAmpFrom, baseAmpTo, t),
        depth: lerp(depthFrom, depthTo, t),
        rateHz: lerp(rateHzFrom, rateHzTo, t),
        bandwidthHz: lerp(bandwidthHzFrom, bandwidthHzTo, t),
        filterFreqHz: lerp(filterFreqHzFrom, filterFreqHzTo, t),
        q: lerp(qFrom, qTo, t),
        transitionMs: lerp(transitionMsFrom, transitionMsTo, t),
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

