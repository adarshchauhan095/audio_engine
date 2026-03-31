/// TinnitX user profile aligned to the official JSON schema.
///
/// - JSON keys are **snake_case** exactly as specified.
/// - Dart fields use idiomatic camelCase, mapped in [toJson]/[fromJson].
class TinnitXUserProfile {
  const TinnitXUserProfile({
    required this.userId,
    required this.tinnitusFrequency,
    required this.tinnitusLoudness,
    required this.tinnitusCharacter,
    required this.laterality,
    this.age,
    this.subjectiveHearingProfile,
    this.soundSensitivity,
    this.stressLevel,
    this.sessionFeedback,
    this.residualInhibitionSec,
  });

  final String userId;

  /// Subjective tinnitus pitch (Hz).
  final double tinnitusFrequency;

  /// Subjective tinnitus loudness (e.g. 0–10 or dB offset).
  final double tinnitusLoudness;

  final TinnitusCharacter tinnitusCharacter;
  final Laterality laterality;

  final double? age;
  final SubjectiveHearingProfile? subjectiveHearingProfile;
  final SoundSensitivity? soundSensitivity;

  /// Optional numeric scale, e.g. 0–10.
  final double? stressLevel;

  final SessionFeedback? sessionFeedback;

  /// Optional: seconds of perceived relief after a session.
  final double? residualInhibitionSec;

  TinnitXUserProfile copyWith({
    String? userId,
    double? tinnitusFrequency,
    double? tinnitusLoudness,
    TinnitusCharacter? tinnitusCharacter,
    Laterality? laterality,
    double? age,
    SubjectiveHearingProfile? subjectiveHearingProfile,
    SoundSensitivity? soundSensitivity,
    double? stressLevel,
    SessionFeedback? sessionFeedback,
    double? residualInhibitionSec,
    bool clearAge = false,
    bool clearSubjectiveHearingProfile = false,
    bool clearSoundSensitivity = false,
    bool clearStressLevel = false,
    bool clearSessionFeedback = false,
    bool clearResidualInhibitionSec = false,
  }) {
    return TinnitXUserProfile(
      userId: userId ?? this.userId,
      tinnitusFrequency: tinnitusFrequency ?? this.tinnitusFrequency,
      tinnitusLoudness: tinnitusLoudness ?? this.tinnitusLoudness,
      tinnitusCharacter: tinnitusCharacter ?? this.tinnitusCharacter,
      laterality: laterality ?? this.laterality,
      age: clearAge ? null : (age ?? this.age),
      subjectiveHearingProfile: clearSubjectiveHearingProfile
          ? null
          : (subjectiveHearingProfile ?? this.subjectiveHearingProfile),
      soundSensitivity: clearSoundSensitivity
          ? null
          : (soundSensitivity ?? this.soundSensitivity),
      stressLevel:
          clearStressLevel ? null : (stressLevel ?? this.stressLevel),
      sessionFeedback: clearSessionFeedback
          ? null
          : (sessionFeedback ?? this.sessionFeedback),
      residualInhibitionSec: clearResidualInhibitionSec
          ? null
          : (residualInhibitionSec ?? this.residualInhibitionSec),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'tinnitus_frequency': tinnitusFrequency,
      'tinnitus_loudness': tinnitusLoudness,
      'tinnitus_character': tinnitusCharacter.value,
      'laterality': laterality.value,
      'age': age,
      'subjective_hearing_profile': subjectiveHearingProfile?.value,
      'sound_sensitivity': soundSensitivity?.value,
      'stress_level': stressLevel,
      'session_feedback': sessionFeedback?.value,
      'residual_inhibition_sec': residualInhibitionSec,
    };
  }

  static TinnitXUserProfile fromJson(Map<String, dynamic> json) {
    return TinnitXUserProfile(
      userId: (json['user_id'] ?? '').toString(),
      tinnitusFrequency: _toDouble(json['tinnitus_frequency']),
      tinnitusLoudness: _toDouble(json['tinnitus_loudness']),
      tinnitusCharacter:
          TinnitusCharacterX.parse((json['tinnitus_character'] ?? '').toString()),
      laterality: LateralityX.parse((json['laterality'] ?? '').toString()),
      age: _toNullableDouble(json['age']),
      subjectiveHearingProfile: SubjectiveHearingProfileX.tryParse(
        json['subjective_hearing_profile'],
      ),
      soundSensitivity: SoundSensitivityX.tryParse(json['sound_sensitivity']),
      stressLevel: _toNullableDouble(json['stress_level']),
      sessionFeedback: SessionFeedbackX.tryParse(json['session_feedback']),
      residualInhibitionSec: _toNullableDouble(json['residual_inhibition_sec']),
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

  static double? _toNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final s = value.toString();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }
}

enum TinnitusCharacter {
  tonal('tonal'),
  noiseLike('noise_like'),
  pulsatile('pulsatile'),
  other('other');

  const TinnitusCharacter(this.value);
  final String value;
}

extension TinnitusCharacterX on TinnitusCharacter {
  static TinnitusCharacter parse(String raw) {
    return TinnitusCharacter.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => throw FormatException(
        'Invalid tinnitus_character: $raw',
      ),
    );
  }
}

enum Laterality {
  left('left'),
  right('right'),
  bilateral('bilateral'),
  inHead('in_head'),
  unsure('unsure');

  const Laterality(this.value);
  final String value;
}

extension LateralityX on Laterality {
  static Laterality parse(String raw) {
    return Laterality.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => throw FormatException('Invalid laterality: $raw'),
    );
  }
}

enum SubjectiveHearingProfile {
  normal('normal'),
  highFrequencyLoss('high_frequency_loss'),
  lowFrequencyLoss('low_frequency_loss'),
  mixed('mixed'),
  unsure('unsure');

  const SubjectiveHearingProfile(this.value);
  final String value;
}

extension SubjectiveHearingProfileX on SubjectiveHearingProfile {
  static SubjectiveHearingProfile? tryParse(Object? raw) {
    if (raw == null) return null;
    final String s = raw.toString();
    if (s.isEmpty || s == 'null') return null;
    for (final v in SubjectiveHearingProfile.values) {
      if (v.value == s) return v;
    }
    throw FormatException('Invalid subjective_hearing_profile: $s');
  }
}

enum SoundSensitivity {
  low('low'),
  medium('medium'),
  high('high');

  const SoundSensitivity(this.value);
  final String value;
}

extension SoundSensitivityX on SoundSensitivity {
  static SoundSensitivity? tryParse(Object? raw) {
    if (raw == null) return null;
    final String s = raw.toString();
    if (s.isEmpty || s == 'null') return null;
    for (final v in SoundSensitivity.values) {
      if (v.value == s) return v;
    }
    throw FormatException('Invalid sound_sensitivity: $s');
  }
}

enum SessionFeedback {
  relieving('relieving'),
  neutral('neutral'),
  uncomfortable('uncomfortable');

  const SessionFeedback(this.value);
  final String value;
}

extension SessionFeedbackX on SessionFeedback {
  static SessionFeedback? tryParse(Object? raw) {
    if (raw == null) return null;
    final String s = raw.toString();
    if (s.isEmpty || s == 'null') return null;
    for (final v in SessionFeedback.values) {
      if (v.value == s) return v;
    }
    throw FormatException('Invalid session_feedback: $s');
  }
}
