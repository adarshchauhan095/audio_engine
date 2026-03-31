import '../../models/tinnitx_stimulus_config.dart';
import '../../models/tinnitx_user_profile.dart';

/// Adaptive Neuro‑Acoustic Profiling System (ANAPS) engine.
///
/// Phase 3 scope: feedback-driven adaptive adjustments over time.
class AnapsEngine {
  const AnapsEngine();

  /// Updates a stored user profile using session feedback.
  ///
  /// Required by the TinnitX API naming guidelines.
  TinnitXUserProfile updateProfileWithFeedback(
    TinnitXUserProfile profile,
    SessionFeedback feedback, {
    double? residualInhibitionSec,
  }) {
    return profile.copyWith(
      sessionFeedback: feedback,
      residualInhibitionSec: residualInhibitionSec,
    );
  }

  /// Returns the current parameters for a user.
  ///
  /// Phase 3 will likely load from storage + apply ANAPS state.
  Future<TinnitXStimulusConfig> getCurrentParameters(String userId) async {
    throw UnimplementedError(
      'ANAPS Phase 3: implement getCurrentParameters(userId)',
    );
  }
}

