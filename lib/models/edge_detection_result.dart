import 'dart:convert';

class EdgeZone {
  const EdgeZone({required this.lowHz, required this.highHz});

  final double lowHz;
  final double highHz;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'low_hz': lowHz,
        'high_hz': highHz,
      };

  static EdgeZone fromJson(Map<String, dynamic> json) {
    return EdgeZone(
      lowHz: (json['low_hz'] as num).toDouble(),
      highHz: (json['high_hz'] as num).toDouble(),
    );
  }
}

class EdgeDetectionResult {
  const EdgeDetectionResult({
    required this.amsFrequencyHz,
    required this.rawGainValues,
    required this.gainProfile,
    required this.edgeZoneInitial,
    required this.edgeZoneFinal,
  });

  final double amsFrequencyHz;
  /// Slider values (0..1) in the same order as test frequencies.
  final List<double> rawGainValues;
  /// Median-normalized values (raw - median(raw)).
  final List<double> gainProfile;
  final EdgeZone edgeZoneInitial;
  final EdgeZone edgeZoneFinal;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ams_frequency_hz': amsFrequencyHz,
        'raw_gain_values': rawGainValues,
        'gain_profile': gainProfile,
        'edge_zone_initial': edgeZoneInitial.toJson(),
        'edge_zone_final': edgeZoneFinal.toJson(),
      };

  String toJsonString() => jsonEncode(toJson());

  static EdgeDetectionResult fromJson(Map<String, dynamic> json) {
    return EdgeDetectionResult(
      amsFrequencyHz: (json['ams_frequency_hz'] as num).toDouble(),
      rawGainValues: (json['raw_gain_values'] as List<dynamic>)
          .whereType<num>()
          .map((num v) => v.toDouble())
          .toList(),
      gainProfile: (json['gain_profile'] as List<dynamic>)
          .whereType<num>()
          .map((num v) => v.toDouble())
          .toList(),
      edgeZoneInitial: EdgeZone.fromJson(
        json['edge_zone_initial'] as Map<String, dynamic>,
      ),
      edgeZoneFinal: EdgeZone.fromJson(
        json['edge_zone_final'] as Map<String, dynamic>,
      ),
    );
  }

  static EdgeDetectionResult fromJsonString(String raw) {
    return fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

