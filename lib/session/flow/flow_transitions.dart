import '../phase3_module_params.dart';
import '../phase3_module_type.dart';
import '../therapy_session_controller.dart';
import 'flow_step.dart';

/// Click-free module transitions for the Flow Engine (Flutter-only).
class FlowTransitions {
  FlowTransitions._();

  static const Duration fadeDuration = Duration(milliseconds: 150);

  /// Fade out the active module, switch configuration at silence, fade in.
  static Future<bool> crossfadeToStep({
    required TherapySessionController session,
    required FlowStep step,
    required double tinnitusFrequencyHz,
    required double baseAmp,
  }) async {
    final Phase3ModuleParams params = step.resolvedParams();
    final double baseFreq = params.engineBaseFreq(tinnitusFrequencyHz);

    final bool rmp = step.module == Phase3ModuleType.rmp;
    final bool pip = step.module == Phase3ModuleType.pip;
    final bool binaural = step.module == Phase3ModuleType.binaural;

    return session.transitionModulesForFlow(
      fadeDuration: fadeDuration,
      subthreshold: false,
      rmp: rmp,
      pip: pip,
      sidebands: false,
      binaural: binaural,
      baseFreq: baseFreq,
      baseAmp: baseAmp,
      maxIntensity: step.maxIntensity01(),
      targetRmpDepth: params.engineRmpDepth(),
      targetRmpRate: params.rmpChangeRateHz,
      targetPipInterval: params.enginePipPauseSec(),
      targetPipDuration: params.enginePipPulseSec(),
      targetSidebandOffset: 100.0,
      targetSidebandIntensity: 0.0,
      targetBinauralOffset: params.engineBinauralOffset(),
    );
  }
}
