import 'package:shared_preferences/shared_preferences.dart';

/// Valid frequency range for tinnitus detection (Hz). Used for validation before save.
const double kMinFrequencyHz = 20.0;
const double kMaxFrequencyHz = 14000.0;

const String _kDetectedTinnitusFrequencyKey = 'detected_tinnitus_frequency';

/// Persistent local storage for the user-detected tinnitus frequency.
///
/// Saves and loads a single frequency value. Value is clamped to
/// [kMinFrequencyHz, kMaxFrequencyHz] before save. Used by the
/// Milestone 03 frequency detection module.
class DetectedFrequencyStorage {
  DetectedFrequencyStorage._();
  static SharedPreferences? _prefs;

  static Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Saves the detected frequency in Hz. Clamps to [kMinFrequencyHz, kMaxFrequencyHz].
  /// Returns true if save succeeded.
  static Future<bool> saveDetectedFrequency(double hz) async {
    await _ensureInit();
    final clamped = _clamp(hz);
    return _prefs!.setDouble(_kDetectedTinnitusFrequencyKey, clamped);
  }

  /// Loads the previously saved detected frequency, or null if never saved.
  static Future<double?> loadDetectedFrequency() async {
    await _ensureInit();
    final value = _prefs!.getDouble(_kDetectedTinnitusFrequencyKey);
    if (value == null) return null;
    return _clamp(value);
  }

  static double _clamp(double v) {
    if (v < kMinFrequencyHz) return kMinFrequencyHz;
    if (v > kMaxFrequencyHz) return kMaxFrequencyHz;
    return v;
  }
}
