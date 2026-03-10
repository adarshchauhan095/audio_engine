import '../storage/detected_frequency_storage.dart';

/// API-ready profile session configuration model.
///
/// Can be serialized directly for local persistence or future backend APIs.
class SessionParams {
  const SessionParams({
    required this.id,
    required this.profileId,
    required this.profileName,
    required this.title,
    required this.frequencyHz,
    required this.amplitude,
    required this.durationSeconds,
    required this.createdAtIso,
    this.category = 'custom',
    this.notes = '',
  });

  final String id;
  final String profileId;
  final String profileName;
  final String title;
  final double frequencyHz;
  final double amplitude;
  final int durationSeconds;
  final String createdAtIso;
  final String category;
  final String notes;

  SessionParams copyWith({
    String? id,
    String? profileId,
    String? profileName,
    String? title,
    double? frequencyHz,
    double? amplitude,
    int? durationSeconds,
    String? createdAtIso,
    String? category,
    String? notes,
  }) {
    return SessionParams(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      profileName: profileName ?? this.profileName,
      title: title ?? this.title,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      amplitude: amplitude ?? this.amplitude,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  SessionParams normalized() {
    return copyWith(
      frequencyHz: _clampFrequency(frequencyHz),
      amplitude: _clampAmplitude(amplitude),
      durationSeconds: durationSeconds < 1 ? 1 : durationSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'profileId': profileId,
      'profileName': profileName,
      'title': title,
      'frequencyHz': _clampFrequency(frequencyHz),
      'amplitude': _clampAmplitude(amplitude),
      'durationSeconds': durationSeconds < 1 ? 1 : durationSeconds,
      'createdAtIso': createdAtIso,
      'category': category,
      'notes': notes,
    };
  }

  static SessionParams fromJson(Map<String, dynamic> json) {
    return SessionParams(
      id: (json['id'] ?? '').toString(),
      profileId: (json['profileId'] ?? '').toString(),
      profileName: (json['profileName'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      frequencyHz: _toDouble(json['frequencyHz'], 440.0),
      amplitude: _toDouble(json['amplitude'], 0.3),
      durationSeconds: _toInt(json['durationSeconds'], 30),
      createdAtIso: (json['createdAtIso'] ?? DateTime.now().toIso8601String())
          .toString(),
      category: (json['category'] ?? 'custom').toString(),
      notes: (json['notes'] ?? '').toString(),
    ).normalized();
  }

  static double _toDouble(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _toInt(Object? value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _clampFrequency(double v) {
    if (v < kMinFrequencyHz) return kMinFrequencyHz;
    if (v > kMaxFrequencyHz) return kMaxFrequencyHz;
    return v;
  }

  static double _clampAmplitude(double v) {
    if (v < 0.0) return 0.0;
    if (v > 1.0) return 1.0;
    return v;
  }
}
