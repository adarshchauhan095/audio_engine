import 'package:shared_preferences/shared_preferences.dart';

import 'detected_frequency_storage.dart';

const String _kAmsCoarseHzKey = 'ams_coarse_frequency_hz';
const String _kAmsFineHzKey = 'ams_fine_frequency_hz';
const String _kAmsFinalHzKey = 'ams_final_frequency_hz';

/// Persists the three AMS milestone frequencies (coarse, fine, final).
///
/// Values are clamped to [kMinFrequencyHz, kMaxFrequencyHz]. Used by the
/// Automated Matching System flow; clearing is used when starting a new session.
class AmsMatchingStorage {
  AmsMatchingStorage._();

  static SharedPreferences? _prefs;

  static Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static double _clamp(double v) {
    if (v < kMinFrequencyHz) return kMinFrequencyHz;
    if (v > kMaxFrequencyHz) return kMaxFrequencyHz;
    return v;
  }

  static Future<bool> saveCoarseFrequency(double hz) async {
    await _ensureInit();
    return _prefs!.setDouble(_kAmsCoarseHzKey, _clamp(hz));
  }

  static Future<bool> saveFineFrequency(double hz) async {
    await _ensureInit();
    return _prefs!.setDouble(_kAmsFineHzKey, _clamp(hz));
  }

  static Future<bool> saveFinalFrequency(double hz) async {
    await _ensureInit();
    return _prefs!.setDouble(_kAmsFinalHzKey, _clamp(hz));
  }

  static Future<AmsStoredFrequencies?> loadAll() async {
    await _ensureInit();
    final double? c = _prefs!.getDouble(_kAmsCoarseHzKey);
    final double? f = _prefs!.getDouble(_kAmsFineHzKey);
    final double? fin = _prefs!.getDouble(_kAmsFinalHzKey);
    if (c == null && f == null && fin == null) return null;
    return AmsStoredFrequencies(
      coarseHz: c != null ? _clamp(c) : null,
      fineHz: f != null ? _clamp(f) : null,
      finalHz: fin != null ? _clamp(fin) : null,
    );
  }

  /// Clears persisted AMS session values (new "Start Matching").
  static Future<void> clearSession() async {
    await _ensureInit();
    await _prefs!.remove(_kAmsCoarseHzKey);
    await _prefs!.remove(_kAmsFineHzKey);
    await _prefs!.remove(_kAmsFinalHzKey);
  }
}

class AmsStoredFrequencies {
  const AmsStoredFrequencies({
    this.coarseHz,
    this.fineHz,
    this.finalHz,
  });

  final double? coarseHz;
  final double? fineHz;
  final double? finalHz;
}
