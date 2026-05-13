import 'dart:async';
import 'package:flutter/foundation.dart';
import '../engine/audio_engine.dart';

enum TherapyPhase { idle, warmup, mainPhase, cooldown }

enum TherapyStopReason { user, completed }

class TherapySessionController {
  TherapySessionController(this.engine);
  
  final AudioEngine engine;
  
  final ValueNotifier<bool> isRunning = ValueNotifier(false);
  final ValueNotifier<TherapyPhase> currentPhase = ValueNotifier(TherapyPhase.idle);
  final ValueNotifier<int> remainingSeconds = ValueNotifier(0);
  final ValueNotifier<double> intensity = ValueNotifier(0.0);
  final ValueNotifier<int> totalTherapySeconds = ValueNotifier(0);
  final ValueNotifier<bool> didComplete = ValueNotifier(false);
  
  Timer? _timer;
  int _ticksCount = 0;
  DateTime? _endTime;
  bool _stopRequested = false;
  int _smoothingToken = 0;
  static const Duration _toggleFadeDuration = Duration(milliseconds: 40);
  static const Duration _paramSlewDuration = Duration(milliseconds: 20);
  
  // configurable profile
  bool subthreshold = false;
  bool rmp = false;
  bool pip = false;
  bool sidebands = false;
  bool binaural = false;
  
  double maxIntensity = 0.5;
  double baseFreq = 6200.0;
  double baseAmp = 0.2;
  
  // Profile targets
  double targetRmpDepth = 0.1;
  double targetRmpRate = 5.0;
  double targetPipInterval = 0.2;
  double targetPipDuration = 0.02;
  double targetSidebandOffset = 100.0;
  double targetSidebandIntensity = 0.33;
  double targetBinauralOffset = 5.0;
  
  int warmupDuration = 0; // calculated based on total duration
  int mainDuration = 0;
  int cooldownDuration = 0;

  Future<void> _rampTherapyUpdate({
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
    const int steps = 6; // small + fast to keep UI responsive
    final int stepMs = (duration.inMilliseconds / steps).clamp(1, 1000).toInt();
    for (int i = 0; i <= steps; i++) {
      if (!isRunning.value || token != _smoothingToken) return;
      final double t = i / steps;
       double lerp(double a, double b) => a + (b - a) * t;
      engine.therapyUpdate(
        subthreshold: subthreshold,
        rmp: rmp,
        pip: pip,
        sidebands: sidebands,
        binaural: binaural,
        intensity: lerp(intensityFrom, intensityTo),
        baseFreq: lerp(baseFreqFrom, baseFreqTo),
        baseAmp: lerp(baseAmpFrom, baseAmpTo),
        rmpDepth: lerp(rmpDepthFrom, rmpDepthTo),
        rmpRate: lerp(rmpRateFrom, rmpRateTo),
        pipInterval: lerp(pipIntervalFrom, pipIntervalTo),
        pipDuration: lerp(pipDurationFrom, pipDurationTo),
        sidebandOffset: lerp(sidebandOffsetFrom, sidebandOffsetTo),
        sidebandIntensity: lerp(sidebandIntensityFrom, sidebandIntensityTo),
        binauralOffset: lerp(binauralOffsetFrom, binauralOffsetTo),
      );
      if (i < steps) {
        await Future<void>.delayed(Duration(milliseconds: stepMs));
      }
    }
  }
  
  void startSession({
    required bool subthreshold,
    required bool rmp,
    required bool pip,
    required bool sidebands,
    required bool binaural,
    required double baseFreq,
    required double baseAmp,
    required double maxIntensity,
    required int durationMinutes,
    double targetRmpDepth = 0.1,
    double targetRmpRate = 5.0,
    double targetPipInterval = 0.2,
    double targetPipDuration = 0.02,
    double targetSidebandOffset = 100.0,
    double targetSidebandIntensity = 0.33,
    double targetBinauralOffset = 5.0,
  }) {
      _stopRequested = false;
      didComplete.value = false;
      this.subthreshold = subthreshold;
      this.rmp = rmp;
      this.pip = pip;
      this.sidebands = sidebands;
      this.binaural = binaural;
      this.baseFreq = baseFreq;
      this.baseAmp = baseAmp;
      this.maxIntensity = maxIntensity;
      
      this.targetRmpDepth = targetRmpDepth;
      this.targetRmpRate = targetRmpRate;
      this.targetPipInterval = targetPipInterval;
      this.targetPipDuration = targetPipDuration;
      this.targetSidebandOffset = targetSidebandOffset;
      this.targetSidebandIntensity = targetSidebandIntensity;
      this.targetBinauralOffset = targetBinauralOffset;
      
      // Calculate phase durations based on total minutes
      // e.g., 20% warmup, 60% main, 20% cooldown
      int totalSecondsConfigured = durationMinutes * 60;
      warmupDuration = (totalSecondsConfigured * 0.2).round();
      cooldownDuration = (totalSecondsConfigured * 0.2).round();
      mainDuration = totalSecondsConfigured - warmupDuration - cooldownDuration;
      
      intensity.value = 0.0;
      currentPhase.value = TherapyPhase.warmup;
      isRunning.value = true;
      
      remainingSeconds.value = totalSecondsConfigured;
      _endTime = DateTime.now().add(Duration(seconds: totalSecondsConfigured));
      
      // Ensure engine is running
      if (!engine.isRunning) {
        engine.start();
      }
      
      int startResult = engine.therapyStart(
        subthreshold: subthreshold,
        rmp: rmp,
        pip: pip,
        sidebands: sidebands,
        binaural: binaural,
        intensity: 0.0,
        baseFreq: baseFreq,
        baseAmp: baseAmp,
        rmpDepth: 0.0, // starts at 0, ramps up
        rmpRate: targetRmpRate,
        pipInterval: targetPipInterval,
        pipDuration: targetPipDuration,
        sidebandOffset: targetSidebandOffset,
        sidebandIntensity: 0.0, // starts at 0
        binauralOffset: targetBinauralOffset,
      );
      
      if (startResult < 0) {
        debugPrint('SupportSession: engine start returned error $startResult');
      } else {
        debugPrint(
          'SupportSession: session started (${durationMinutes}min) '
          'sub=$subthreshold rmp=$rmp pip=$pip sidebands=$sidebands binaural=$binaural '
          'baseFreq=$baseFreq baseAmp=$baseAmp',
        );
      }

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 200), _onTick);
  }
  
  void _onTick(Timer timer) {
     if (_stopRequested) return;
     _ticksCount++;
     if (_ticksCount >= 5) {
       totalTherapySeconds.value++;
       _ticksCount = 0;
     }

     if (_endTime == null) return;
     
     final now = DateTime.now();
     int remain = _endTime!.difference(now).inSeconds;
     
     if (remain <= 0) {
       _stopSession(reason: TherapyStopReason.completed);
       return;
     } // keep going until 0
     
     remainingSeconds.value = remain;
     int elapsed = (warmupDuration + mainDuration + cooldownDuration) - remain;
     double currentIntensity = 0.0;
     
     double phaseRatio = 0.0;
     if (elapsed < warmupDuration) {
       currentPhase.value = TherapyPhase.warmup;
       phaseRatio = elapsed / warmupDuration;
       currentIntensity = phaseRatio * maxIntensity;
     } else if (elapsed - warmupDuration < mainDuration) {
       currentPhase.value = TherapyPhase.mainPhase;
       phaseRatio = 1.0;
       currentIntensity = maxIntensity;
     } else {
       currentPhase.value = TherapyPhase.cooldown;
       int cooldownElapsed = elapsed - warmupDuration - mainDuration;
       phaseRatio = 1.0 - (cooldownElapsed / cooldownDuration);
       currentIntensity = maxIntensity * phaseRatio;
     }
     
     intensity.value = currentIntensity;
     _applyTherapyAudioUpdate();
  }

  /// After the native output stream was torn down and reopened (e.g. Bluetooth
  /// disconnect), re-apply the current therapy DSP state without stopping the
  /// session timer or phases.
  void applyEngineOutputRecovery() {
    if (_stopRequested || !isRunning.value) return;
    if (!engine.isRunning) {
      engine.start();
    }
    _applyTherapyAudioUpdate();
  }

  void _applyTherapyAudioUpdate() {
    if (_smoothingToken != 0) return;
    if (_endTime == null) return;

    final DateTime now = DateTime.now();
    int remain = _endTime!.difference(now).inSeconds;
    if (remain <= 0) return;

    final int elapsed =
        (warmupDuration + mainDuration + cooldownDuration) - remain;
    double phaseRatio = 0.0;
    if (elapsed < warmupDuration) {
      phaseRatio = warmupDuration > 0 ? elapsed / warmupDuration : 0.0;
    } else if (elapsed - warmupDuration < mainDuration) {
      phaseRatio = 1.0;
    } else {
      final int cooldownElapsed = elapsed - warmupDuration - mainDuration;
      phaseRatio = cooldownDuration > 0
          ? 1.0 - (cooldownElapsed / cooldownDuration)
          : 0.0;
    }

    final double currentRmpDepth = targetRmpDepth * phaseRatio;
    final double currentSidebandIntensity =
        targetSidebandIntensity * phaseRatio;

    final int updateResult = engine.therapyUpdate(
      subthreshold: subthreshold,
      rmp: rmp,
      pip: pip,
      sidebands: sidebands,
      binaural: binaural,
      intensity: intensity.value,
      baseFreq: baseFreq,
      baseAmp: baseAmp,
      rmpDepth: currentRmpDepth,
      rmpRate: targetRmpRate,
      pipInterval: targetPipInterval,
      pipDuration: targetPipDuration,
      sidebandOffset: targetSidebandOffset,
      sidebandIntensity: currentSidebandIntensity,
      binauralOffset: targetBinauralOffset,
    );

    if (updateResult < 0) {
      debugPrint(
        'SupportSession: engine update (recovery) returned $updateResult',
      );
    }
  }
  
  void stopSession() {
    _stopSession(reason: TherapyStopReason.user);
  }

  void _stopSession({required TherapyStopReason reason}) {
     _stopRequested = true;
     _timer?.cancel();
     _timer = null;

     // Smoothly fade down therapy intensity before disabling DSP + transport.
     final int token = ++_smoothingToken;
     final double currentIntensity = intensity.value;
     // Keep last-known params; intensity is forced to 0 for stop.
     () async {
       await _rampTherapyUpdate(
         token: token,
         duration: _toggleFadeDuration,
         subthreshold: subthreshold,
         rmp: rmp,
         pip: pip,
         sidebands: sidebands,
         binaural: binaural,
         intensityFrom: currentIntensity,
         intensityTo: 0.0,
         baseFreqFrom: baseFreq,
         baseFreqTo: baseFreq,
         baseAmpFrom: baseAmp,
         baseAmpTo: baseAmp,
         rmpDepthFrom: targetRmpDepth,
         rmpDepthTo: targetRmpDepth,
         rmpRateFrom: targetRmpRate,
         rmpRateTo: targetRmpRate,
         pipIntervalFrom: targetPipInterval,
         pipIntervalTo: targetPipInterval,
         pipDurationFrom: targetPipDuration,
         pipDurationTo: targetPipDuration,
         sidebandOffsetFrom: targetSidebandOffset,
         sidebandOffsetTo: targetSidebandOffset,
         sidebandIntensityFrom: targetSidebandIntensity,
         sidebandIntensityTo: targetSidebandIntensity,
         binauralOffsetFrom: targetBinauralOffset,
         binauralOffsetTo: targetBinauralOffset,
       );

       // Disable DSP, then stop transport.
       final int stopResult = engine.therapyStop();
       if (stopResult < 0) {
         debugPrint('SupportSession: engine stop returned error $stopResult');
       }
       engine.stop();
       isRunning.value = false;
       currentPhase.value = TherapyPhase.idle;
       didComplete.value = reason == TherapyStopReason.completed;
       debugPrint('SupportSession: session stopped');
       if (token == _smoothingToken) _smoothingToken = 0;
     }();
  }

  void resetCompletion() {
    didComplete.value = false;
  }
  
  /// Live-updates the current therapy configuration while a session
  /// is running. The phase/timer continues uninterrupted.
  void updatePreset({
    required bool subthreshold,
    required bool rmp,
    required bool pip,
    required bool sidebands,
    required bool binaural,
    required double baseFreq,
    required double baseAmp,
    required double targetRmpDepth,
    required double targetRmpRate,
    required double targetPipInterval,
    required double targetPipDuration,
    required double targetSidebandOffset,
    required double targetSidebandIntensity,
    required double targetBinauralOffset,
  }) {
    if (_stopRequested) return;

    final bool wasRunning = isRunning.value;
    final bool oldSub = this.subthreshold;
    final bool oldRmp = this.rmp;
    final bool oldPip = this.pip;
    final bool oldSss = this.sidebands;
    final bool oldBin = this.binaural;
    final double oldBaseFreq = this.baseFreq;
    final double oldBaseAmp = this.baseAmp;
    final double oldRmpDepth = this.targetRmpDepth;
    final double oldRmpRate = this.targetRmpRate;
    final double oldPipInterval = this.targetPipInterval;
    final double oldPipDuration = this.targetPipDuration;
    final double oldSidebandOffset = this.targetSidebandOffset;
    final double oldSidebandIntensity = this.targetSidebandIntensity;
    final double oldBinauralOffset = this.targetBinauralOffset;
    final double currentIntensity = intensity.value;

    // Update stored fields used by the periodic therapyUpdate tick.
    this.subthreshold = subthreshold;
    this.rmp = rmp;
    this.pip = pip;
    this.sidebands = sidebands;
    this.binaural = binaural;

    this.baseFreq = baseFreq;
    this.baseAmp = baseAmp;

    this.targetRmpDepth = targetRmpDepth;
    this.targetRmpRate = targetRmpRate;
    this.targetPipInterval = targetPipInterval;
    this.targetPipDuration = targetPipDuration;
    this.targetSidebandOffset = targetSidebandOffset;
    this.targetSidebandIntensity = targetSidebandIntensity;
    this.targetBinauralOffset = targetBinauralOffset;

    if (!wasRunning) return;

    final bool moduleTogglesChanged = oldSub != subthreshold ||
        oldRmp != rmp ||
        oldPip != pip ||
        oldSss != sidebands ||
        oldBin != binaural;

    // Mirror TherapySessionController's _onTick curve:
    // - warmup: intensity = phaseRatio * maxIntensity
    // - main: intensity = maxIntensity (phaseRatio=1)
    // - cooldown: intensity = maxIntensity * (1 - t/cooldown)
    final double maxI = maxIntensity;
    final double phaseRatio =
        maxI <= 0.0 ? 0.0 : (intensity.value / maxI).clamp(0.0, 1.0);
    final double currentRmpDepth = targetRmpDepth * phaseRatio;
    final double currentSidebandIntensity =
        targetSidebandIntensity * phaseRatio;

    final int token = ++_smoothingToken;
    () async {
      if (moduleTogglesChanged) {
        // Fade out old config → switch toggles at silence → fade in new config.
        await _rampTherapyUpdate(
          token: token,
          duration: _toggleFadeDuration,
          subthreshold: oldSub,
          rmp: oldRmp,
          pip: oldPip,
          sidebands: oldSss,
          binaural: oldBin,
          intensityFrom: currentIntensity,
          intensityTo: 0.0,
          baseFreqFrom: oldBaseFreq,
          baseFreqTo: oldBaseFreq,
          baseAmpFrom: oldBaseAmp,
          baseAmpTo: oldBaseAmp,
          rmpDepthFrom: oldRmpDepth * phaseRatio,
          rmpDepthTo: oldRmpDepth * phaseRatio,
          rmpRateFrom: oldRmpRate,
          rmpRateTo: oldRmpRate,
          pipIntervalFrom: oldPipInterval,
          pipIntervalTo: oldPipInterval,
          pipDurationFrom: oldPipDuration,
          pipDurationTo: oldPipDuration,
          sidebandOffsetFrom: oldSidebandOffset,
          sidebandOffsetTo: oldSidebandOffset,
          sidebandIntensityFrom: oldSidebandIntensity * phaseRatio,
          sidebandIntensityTo: oldSidebandIntensity * phaseRatio,
          binauralOffsetFrom: oldBinauralOffset,
          binauralOffsetTo: oldBinauralOffset,
        );
      }

      // Slew parameters (including PIP) to avoid slider clicks.
      await _rampTherapyUpdate(
        token: token,
        duration: _paramSlewDuration,
        subthreshold: subthreshold,
        rmp: rmp,
        pip: pip,
        sidebands: sidebands,
        binaural: binaural,
        intensityFrom: moduleTogglesChanged ? 0.0 : currentIntensity,
        intensityTo: currentIntensity,
        baseFreqFrom: oldBaseFreq,
        baseFreqTo: baseFreq,
        baseAmpFrom: oldBaseAmp,
        baseAmpTo: baseAmp,
        rmpDepthFrom: oldRmpDepth * phaseRatio,
        rmpDepthTo: currentRmpDepth,
        rmpRateFrom: oldRmpRate,
        rmpRateTo: targetRmpRate,
        pipIntervalFrom: oldPipInterval,
        pipIntervalTo: targetPipInterval,
        pipDurationFrom: oldPipDuration,
        pipDurationTo: targetPipDuration,
        sidebandOffsetFrom: oldSidebandOffset,
        sidebandOffsetTo: targetSidebandOffset,
        sidebandIntensityFrom: oldSidebandIntensity * phaseRatio,
        sidebandIntensityTo: currentSidebandIntensity,
        binauralOffsetFrom: oldBinauralOffset,
        binauralOffsetTo: targetBinauralOffset,
      );

      if (token == _smoothingToken) _smoothingToken = 0;
    }();
  }

  void dispose() {
     _timer?.cancel();
     isRunning.dispose();
     currentPhase.dispose();
     remainingSeconds.dispose();
     intensity.dispose();
     didComplete.dispose();
  }
}
