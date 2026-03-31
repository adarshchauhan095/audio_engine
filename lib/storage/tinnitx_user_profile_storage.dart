import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tinnitx_user_profile.dart';
import 'ams_matching_storage.dart';
import 'detected_frequency_storage.dart';

const String _kTinnitXUserProfileKey = 'tinnitx_user_profile_v1';
const String _kTinnitXUserProfileMigratedKey =
    'tinnitx_user_profile_v1_migrated';

/// Local persistence for a single active TinnitX user profile.
///
/// - Stores schema-aligned JSON (snake_case keys).
/// - Performs a one-time migration from legacy frequency stores where possible.
class TinnitXUserProfileStorage {
  TinnitXUserProfileStorage._();

  static SharedPreferences? _prefs;

  static Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> saveProfile(TinnitXUserProfile profile) async {
    await _ensureInit();
    final String encoded = jsonEncode(profile.toJson());
    return _prefs!.setString(_kTinnitXUserProfileKey, encoded);
  }

  static Future<TinnitXUserProfile?> loadProfile() async {
    await _ensureInit();
    final String? raw = _prefs!.getString(_kTinnitXUserProfileKey);
    if (raw == null || raw.isEmpty) return null;
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return TinnitXUserProfile.fromJson(decoded);
  }

  /// Creates a minimal schema-valid profile if none exists.
  ///
  /// This is intentionally conservative: it only fills required fields.
  static Future<TinnitXUserProfile> getOrCreateMinimal({
    required String userId,
    double defaultTinnitusFrequencyHz = 4000.0,
    double defaultTinnitusLoudness = 5.0,
    TinnitusCharacter defaultTinnitusCharacter = TinnitusCharacter.tonal,
    Laterality defaultLaterality = Laterality.unsure,
  }) async {
    final existing = await loadProfile();
    if (existing != null) return existing;
    final created = TinnitXUserProfile(
      userId: userId,
      tinnitusFrequency: defaultTinnitusFrequencyHz,
      tinnitusLoudness: defaultTinnitusLoudness,
      tinnitusCharacter: defaultTinnitusCharacter,
      laterality: defaultLaterality,
    );
    await saveProfile(created);
    return created;
  }

  /// One-time migration from legacy local stores:
  /// - prefers AMS final frequency, then detected frequency
  ///
  /// Does nothing if a profile already exists.
  static Future<void> migrateLegacyIfNeeded({
    required String userId,
    double defaultTinnitusLoudness = 5.0,
    TinnitusCharacter defaultTinnitusCharacter = TinnitusCharacter.tonal,
    Laterality defaultLaterality = Laterality.unsure,
  }) async {
    await _ensureInit();
    final bool migrated = _prefs!.getBool(_kTinnitXUserProfileMigratedKey) ??
        false;
    if (migrated) return;

    final existing = await loadProfile();
    if (existing != null) {
      await _prefs!.setBool(_kTinnitXUserProfileMigratedKey, true);
      return;
    }

    double? migratedHz;
    final storedAms = await AmsMatchingStorage.loadAll();
    if (storedAms?.finalHz != null) {
      migratedHz = storedAms!.finalHz;
    } else {
      migratedHz = await DetectedFrequencyStorage.loadDetectedFrequency();
    }

    final double hz = migratedHz ?? 4000.0;
    final profile = TinnitXUserProfile(
      userId: userId,
      tinnitusFrequency: hz,
      tinnitusLoudness: defaultTinnitusLoudness,
      tinnitusCharacter: defaultTinnitusCharacter,
      laterality: defaultLaterality,
    );
    await saveProfile(profile);
    await _prefs!.setBool(_kTinnitXUserProfileMigratedKey, true);
  }

  static Future<void> clear() async {
    await _ensureInit();
    await _prefs!.remove(_kTinnitXUserProfileKey);
    await _prefs!.remove(_kTinnitXUserProfileMigratedKey);
  }
}

