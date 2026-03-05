import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_params.dart';

const String _kSessionParamsListKey = 'saved_session_params_list_v1';
const int _kMaxStoredSessionParams = 200;

/// Local persistence for reusable session parameters.
///
/// Stores a JSON list in SharedPreferences so multiple saved entries
/// are available later on a dedicated screen.
class SessionParamsStorage {
  SessionParamsStorage._();

  static SharedPreferences? _prefs;

  static Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<SessionParams>> loadAll() async {
    await _ensureInit();
    final String? raw = _prefs!.getString(_kSessionParamsListKey);
    if (raw == null || raw.isEmpty) return <SessionParams>[];

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SessionParams.fromJson)
          .toList();
    } catch (_) {
      return <SessionParams>[];
    }
  }

  static Future<bool> save(SessionParams sessionParams) async {
    await _ensureInit();
    final List<SessionParams> current = await loadAll();
    final SessionParams normalized = sessionParams.normalized();

    final List<SessionParams> withoutSameId = current
        .where((SessionParams item) => item.id != normalized.id)
        .toList();
    withoutSameId.insert(0, normalized);

    if (withoutSameId.length > _kMaxStoredSessionParams) {
      withoutSameId.removeRange(_kMaxStoredSessionParams, withoutSameId.length);
    }

    return _prefs!.setString(
      _kSessionParamsListKey,
      jsonEncode(
        withoutSameId.map((SessionParams item) => item.toJson()).toList(),
      ),
    );
  }

  static Future<bool> deleteById(String id) async {
    await _ensureInit();
    final List<SessionParams> current = await loadAll();
    final List<SessionParams> updated = current
        .where((SessionParams item) => item.id != id)
        .toList();

    return _prefs!.setString(
      _kSessionParamsListKey,
      jsonEncode(updated.map((SessionParams item) => item.toJson()).toList()),
    );
  }

  static Future<bool> clearAll() async {
    await _ensureInit();
    return _prefs!.remove(_kSessionParamsListKey);
  }
}
