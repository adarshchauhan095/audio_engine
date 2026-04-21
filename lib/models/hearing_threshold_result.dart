import 'dart:convert';

class HearingThresholdPoint {
  const HearingThresholdPoint({
    required this.frequencyHz,
    required this.thresholdGain01,
  });

  final double frequencyHz;
  final double? thresholdGain01;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'frequency_hz': frequencyHz,
        'threshold_gain_01': thresholdGain01,
      };

  static HearingThresholdPoint fromJson(Map<String, dynamic> json) {
    final Object? raw = json['threshold_gain_01'];
    double? v;
    if (raw is num) v = raw.toDouble();
    return HearingThresholdPoint(
      frequencyHz: (json['frequency_hz'] as num).toDouble(),
      thresholdGain01: v,
    );
  }
}

class HearingThresholdResult {
  const HearingThresholdResult({
    required this.amsFrequencyHz,
    required this.points,
    required this.createdAtIso,
  });

  final double amsFrequencyHz;
  final List<HearingThresholdPoint> points;
  final String createdAtIso;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ams_frequency_hz': amsFrequencyHz,
        'points': points.map((p) => p.toJson()).toList(growable: false),
        'created_at_iso': createdAtIso,
      };

  String toJsonString() => jsonEncode(toJson());

  static HearingThresholdResult fromJson(Map<String, dynamic> json) {
    return HearingThresholdResult(
      amsFrequencyHz: (json['ams_frequency_hz'] as num).toDouble(),
      points: (json['points'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(HearingThresholdPoint.fromJson)
          .toList(),
      createdAtIso: (json['created_at_iso'] as String?) ?? '',
    );
  }

  static HearingThresholdResult fromJsonString(String raw) {
    return fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

