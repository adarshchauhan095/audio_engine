/// TinnitX stimulus configuration aligned to the official JSON schema.
///
/// JSON keys are **snake_case** exactly as specified.
class TinnitXStimulusConfig {
  const TinnitXStimulusConfig({
    required this.stimulusType,
    required this.centerFrequencyHz,
    required this.bandwidth,
    required this.modulation,
    required this.intensityDbOffset,
    required this.lateralityMix,
    this.adaptiveAdjustment,
  });

  final StimulusType stimulusType;
  final double centerFrequencyHz;
  final double bandwidth;
  final Modulation modulation;
  final double intensityDbOffset;
  final LateralityMix lateralityMix;

  /// Optional: details on how parameters were changed based on feedback.
  final Map<String, dynamic>? adaptiveAdjustment;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stimulus_type': stimulusType.value,
      'center_frequency_hz': centerFrequencyHz,
      'bandwidth': bandwidth,
      'modulation': modulation.value,
      'intensity_db_offset': intensityDbOffset,
      'laterality_mix': lateralityMix.value,
      'adaptive_adjustment': adaptiveAdjustment,
    };
  }

  static TinnitXStimulusConfig fromJson(Map<String, dynamic> json) {
    return TinnitXStimulusConfig(
      stimulusType:
          StimulusTypeX.parse((json['stimulus_type'] ?? '').toString()),
      centerFrequencyHz: _toDouble(json['center_frequency_hz']),
      bandwidth: _toDouble(json['bandwidth']),
      modulation: ModulationX.parse((json['modulation'] ?? '').toString()),
      intensityDbOffset: _toDouble(json['intensity_db_offset']),
      lateralityMix:
          LateralityMixX.parse((json['laterality_mix'] ?? '').toString()),
      adaptiveAdjustment: json['adaptive_adjustment'] is Map<String, dynamic>
          ? (json['adaptive_adjustment'] as Map<String, dynamic>)
          : null,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('Expected number, got: $value');
    }
    return parsed;
  }
}

enum StimulusType {
  narrowbandNoise('narrowband_noise'),
  broadbandNoise('broadband_noise'),
  tone('tone');

  const StimulusType(this.value);
  final String value;
}

extension StimulusTypeX on StimulusType {
  static StimulusType parse(String raw) {
    return StimulusType.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => throw FormatException('Invalid stimulus_type: $raw'),
    );
  }
}

enum Modulation {
  none('none'),
  amSlow('am_slow'),
  amFast('am_fast'),
  fm('fm');

  const Modulation(this.value);
  final String value;
}

extension ModulationX on Modulation {
  static Modulation parse(String raw) {
    return Modulation.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => throw FormatException('Invalid modulation: $raw'),
    );
  }
}

enum LateralityMix {
  leftOnly('left_only'),
  rightOnly('right_only'),
  balanced('balanced'),
  weightedLeft('weighted_left'),
  weightedRight('weighted_right');

  const LateralityMix(this.value);
  final String value;
}

extension LateralityMixX on LateralityMix {
  static LateralityMix parse(String raw) {
    return LateralityMix.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => throw FormatException('Invalid laterality_mix: $raw'),
    );
  }
}
