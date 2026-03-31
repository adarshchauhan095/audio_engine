import 'dart:async';
import 'package:flutter/foundation.dart';
import '../engine/audio_engine.dart';

enum TherapyPhase { idle, warmup, mainPhase, cooldown }

class TherapySessionController {
  TherapySessionController(this.engine);
  
  final AudioEngine engine;
  
  final ValueNotifier<bool> isRunning = ValueNotifier(false);
  final ValueNotifier<TherapyPhase> currentPhase = ValueNotifier(TherapyPhase.idle);
  final ValueNotifier<int> remainingSeconds = ValueNotifier(0);
  final ValueNotifier<double> intensity = ValueNotifier(0.0);
  final ValueNotifier<int> totalTherapySeconds = ValueNotifier(0);
  
  Timer? _timer;
  int _ticksCount = 0;
  DateTime? _endTime;
  bool _stopRequested = false;
  
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
      this.warmupDuration = (totalSecondsConfigured * 0.2).round();
      this.cooldownDuration = (totalSecondsConfigured * 0.2).round();
      this.mainDuration = totalSecondsConfigured - this.warmupDuration - this.cooldownDuration;
      
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
       stopSession();
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
     _stopRequested = true;
     _timer?.cancel();
     _timer = null;
     isRunning.value = false;
     currentPhase.value = TherapyPhase.idle;

     // Mute transport first to minimize discontinuities while disabling DSP.
     engine.stop();

     final int stopResult = engine.therapyStop();
     if (stopResult < 0) {
       debugPrint('SupportSession: engine stop returned error $stopResult');
     }
     debugPrint('SupportSession: session stopped');
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

    // Apply immediately so the audio output reflects the preset change.
    engine.therapyUpdate(
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
  }

  void dispose() {
     _timer?.cancel();
     isRunning.dispose();
     currentPhase.dispose();
     remainingSeconds.dispose();
     intensity.dispose();
  }
}
