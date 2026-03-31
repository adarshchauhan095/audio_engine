import '../../models/tinnitx_stimulus_config.dart';
import '../../models/tinnitx_user_profile.dart';

/// Adaptive Modulation System (AMS) engine.
///
/// Phase 1 scope: stable stimulus generation without feedback-driven adaptivity.
class AmsEngine {
  const AmsEngine();

  /// Main entry point for stimulus generation.
  ///
  /// Required by the TinnitX API naming guidelines.
  TinnitXStimulusConfig generateStimulus(TinnitXUserProfile userProfile) {
    return applyTherapyRules(userProfile);
  }

  /// Internal rules mapping profile → stimulus configuration.
  ///
  /// Note: This is a parameter-mapping layer. UI/strings must remain neutral and
  /// avoid medical claims.
  TinnitXStimulusConfig applyTherapyRules(TinnitXUserProfile userProfile) {
    final double f = userProfile.tinnitusFrequency;

    // Phase 1 conservative defaults:
    // - narrowband noise for tonal/noise-like
    // - pure tone only when explicitly tonal (kept available for debugging)
    final StimulusType stimulusType = switch (userProfile.tinnitusCharacter) {
      TinnitusCharacter.tonal => StimulusType.narrowbandNoise,
      TinnitusCharacter.noiseLike => StimulusType.broadbandNoise,
      TinnitusCharacter.pulsatile => StimulusType.broadbandNoise,
      TinnitusCharacter.other => StimulusType.broadbandNoise,
    };

    // Bandwidth in Hz (simple placeholder; Phase 2 can refine).
    final double bandwidth = switch (stimulusType) {
      StimulusType.narrowbandNoise => 400.0,
      StimulusType.broadbandNoise => 6000.0,
      StimulusType.tone => 0.0,
    };

    // Modulation: keep none by default in Phase 1 for determinism.
    const Modulation modulation = Modulation.none;

    // Intensity offset placeholder: 0 means "reference / neutral".
    // When tinnitus_loudness is 0–10, we can map it later to offsets safely.
    const double intensityDbOffset = 0.0;

    // Phase 1 laterality mix derived from laterality.
    final LateralityMix lateralityMix = switch (userProfile.laterality) {
      Laterality.left => LateralityMix.leftOnly,
      Laterality.right => LateralityMix.rightOnly,
      Laterality.bilateral => LateralityMix.balanced,
      Laterality.inHead => LateralityMix.balanced,
      Laterality.unsure => LateralityMix.balanced,
    };

    return TinnitXStimulusConfig(
      stimulusType: stimulusType,
      centerFrequencyHz: f,
      bandwidth: bandwidth,
      modulation: modulation,
      intensityDbOffset: intensityDbOffset,
      lateralityMix: lateralityMix,
      adaptiveAdjustment: null,
    );
  }
}

