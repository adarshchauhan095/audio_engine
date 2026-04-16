import 'package:shared_preferences/shared_preferences.dart';

import '../models/edge_detection_result.dart';

const String _kEdgeDetectionResultKey = 'edge_detection_result_v1';

class EdgeDetectionStorage {
  EdgeDetectionStorage._();

  static SharedPreferences? _prefs;

  static Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> saveResult(EdgeDetectionResult result) async {
    await _ensureInit();
    return _prefs!.setString(_kEdgeDetectionResultKey, result.toJsonString());
  }

  static Future<EdgeDetectionResult?> loadResult() async {
    await _ensureInit();
    final String? raw = _prefs!.getString(_kEdgeDetectionResultKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return EdgeDetectionResult.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> clear() async {
    await _ensureInit();
    return _prefs!.remove(_kEdgeDetectionResultKey);
  }
}

