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
  
  // configurable profile
  bool subthreshold = false;
  bool rmp = false;
  bool pip = false;
  bool sidebands = false;
  bool binaural = false;
  
  double maxIntensity = 0.5;
  double baseFreq = 6200.0;
  double baseAmp = 0.2;
  
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
  }) {
      this.subthreshold = subthreshold;
      this.rmp = rmp;
      this.pip = pip;
      this.sidebands = sidebands;
      this.binaural = binaural;
      this.baseFreq = baseFreq;
      this.baseAmp = baseAmp;
      this.maxIntensity = maxIntensity;
      
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
      
      engine.therapyStart(
        subthreshold: subthreshold,
        rmp: rmp,
        pip: pip,
        sidebands: sidebands,
        binaural: binaural,
        intensity: 0.0,
        baseFreq: baseFreq,
        baseAmp: baseAmp,
      );
      
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 200), _onTick);
  }
  
  void _onTick(Timer timer) {
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
     
     if (elapsed < warmupDuration) {
       currentPhase.value = TherapyPhase.warmup;
       currentIntensity = (elapsed / warmupDuration) * maxIntensity;
     } else if (elapsed - warmupDuration < mainDuration) {
       currentPhase.value = TherapyPhase.mainPhase;
       currentIntensity = maxIntensity;
     } else {
       currentPhase.value = TherapyPhase.cooldown;
       int cooldownElapsed = elapsed - warmupDuration - mainDuration;
       currentIntensity = maxIntensity * (1.0 - (cooldownElapsed / cooldownDuration));
     }
     
     intensity.value = currentIntensity;
     
     engine.therapyUpdate(
        subthreshold: subthreshold,
        rmp: rmp,
        pip: pip,
        sidebands: sidebands,
        binaural: binaural,
        intensity: currentIntensity,
        baseFreq: baseFreq,
        baseAmp: baseAmp,
      );
  }
  
  void stopSession() {
     _timer?.cancel();
     _timer = null;
     isRunning.value = false;
     currentPhase.value = TherapyPhase.idle;
     engine.therapyStop();
     // Opt to stop engine as well if Therapy takes full control
     if (engine.isRunning) {
       engine.stop();
     }
  }
  
  void dispose() {
     _timer?.cancel();
     isRunning.dispose();
     currentPhase.dispose();
     remainingSeconds.dispose();
     intensity.dispose();
  }
}
