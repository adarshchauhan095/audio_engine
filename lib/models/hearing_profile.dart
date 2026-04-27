class HearingProfile {
  const HearingProfile({
    required this.threshold250,
    required this.balancing1000,
    required this.thresholdAMS,
    required this.threshold12k,
    required this.maxHearableFrequency,
    required this.timestamp,
  });

  final double? threshold250;
  final double balancing1000;
  final double? thresholdAMS;
  final double? threshold12k;
  final double maxHearableFrequency;
  final String timestamp;

  static double computeMaxHearableFrequency({
    required double amsFrequencyHz,
    required double? thresholdAMS,
    required double? threshold12k,
  }) {
    if (threshold12k != null) return 12000;
    if (thresholdAMS != null) return amsFrequencyHz;
    return 1000;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'threshold250': threshold250,
      'balancing1000': balancing1000,
      'thresholdAMS': thresholdAMS,
      'threshold12k': threshold12k,
      'maxHearableFrequency': maxHearableFrequency,
      'timestamp': timestamp,
    };
  }

  static HearingProfile? fromJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) return null;

    double? toNullableDouble(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString();
      if (s.isEmpty || s == 'null') return null;
      return double.tryParse(s);
    }

    double toDouble(Object? v, {required double fallback}) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return HearingProfile(
      threshold250: toNullableDouble(raw['threshold250']),
      balancing1000: toDouble(raw['balancing1000'], fallback: 50.0),
      thresholdAMS: toNullableDouble(raw['thresholdAMS']),
      threshold12k: toNullableDouble(raw['threshold12k']),
      maxHearableFrequency:
          toDouble(raw['maxHearableFrequency'], fallback: 1000.0),
      timestamp: (raw['timestamp'] ?? '').toString(),
    );
  }
}

