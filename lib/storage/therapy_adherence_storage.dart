import 'package:shared_preferences/shared_preferences.dart';

const String _kTherapyAdherenceTotalSecondsKey =
    'therapy_adherence_total_seconds';

/// Persistent storage for therapy adherence (total therapy seconds).
///
/// The UI currently labels this as "Complete for this week", but the runtime
/// counter is a simple accumulated seconds value; we persist that value so it
/// doesn't reset on app restart.
class TherapyAdherenceStorage {
  TherapyAdherenceStorage._();

  static SharedPreferences? _prefs;

  static Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> saveTotalTherapySeconds(int seconds) async {
    await _ensureInit();
    final int clamped = seconds < 0 ? 0 : seconds;
    return _prefs!.setInt(_kTherapyAdherenceTotalSecondsKey, clamped);
  }

  static Future<int> loadTotalTherapySeconds() async {
    await _ensureInit();
    return _prefs!.getInt(_kTherapyAdherenceTotalSecondsKey) ?? 0;
  }
}

