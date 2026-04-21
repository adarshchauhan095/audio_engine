import 'package:shared_preferences/shared_preferences.dart';

import '../models/hearing_threshold_result.dart';

const String _kHearingThresholdResultKey = 'hearing_threshold_result_v1';

class HearingThresholdStorage {
  HearingThresholdStorage._();

  static SharedPreferences? _prefs;

  static Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> saveResult(HearingThresholdResult result) async {
    await _ensureInit();
    return _prefs!.setString(_kHearingThresholdResultKey, result.toJsonString());
  }

  static Future<HearingThresholdResult?> loadResult() async {
    await _ensureInit();
    final String? raw = _prefs!.getString(_kHearingThresholdResultKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return HearingThresholdResult.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> clear() async {
    await _ensureInit();
    return _prefs!.remove(_kHearingThresholdResultKey);
  }
}

