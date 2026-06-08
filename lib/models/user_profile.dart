import 'dart:convert';

class UserProfile {
  String tinnitusDuration;
  String tinnitusOnsetType;
  String toneType;
  String toneStability;
  String location;
  double selfReportedFrequencyHz;
  double selfReportedLoudness;
  double dominance;
  double awareness;
  String reactivityToNoise;
  String reactivityToSilence;
  double reactivityToStress;
  double reactivityToFatigue;
  double reactivityToMovement;
  bool reactivityToJawNeck;
  double morningIntensity;
  double eveningIntensity;
  double sleepImpact;
  String environmentType;
  String preferredSessionTime;

  UserProfile({
    this.tinnitusDuration = "3-12 months",
    this.tinnitusOnsetType = "unknown",
    this.toneType = "pureTone",
    this.toneStability = "stable",
    this.location = "insideHead",
    this.selfReportedFrequencyHz = 8000.0,
    this.selfReportedLoudness = 3.0,
    this.dominance = 3.0,
    this.awareness = 50.0,
    this.reactivityToNoise = "unchanged",
    this.reactivityToSilence = "unchanged",
    this.reactivityToStress = 5.0,
    this.reactivityToFatigue = 5.0,
    this.reactivityToMovement = 0.0,
    this.reactivityToJawNeck = false,
    this.morningIntensity = 5.0,
    this.eveningIntensity = 5.0,
    this.sleepImpact = 5.0,
    this.environmentType = "mixed",
    this.preferredSessionTime = "flexible",
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      tinnitusDuration: json['tinnitusDuration'] ?? "3-12 months",
      tinnitusOnsetType: json['tinnitusOnsetType'] ?? "unknown",
      toneType: json['toneType'] ?? "pureTone",
      toneStability: json['toneStability'] ?? "stable",
      location: json['location'] ?? "insideHead",
      selfReportedFrequencyHz: (json['selfReportedFrequencyHz'] ?? 8000.0).toDouble(),
      selfReportedLoudness: (json['selfReportedLoudness'] ?? 3.0).toDouble(),
      dominance: (json['dominance'] ?? 3.0).toDouble(),
      awareness: (json['awareness'] ?? 50.0).toDouble(),
      reactivityToNoise: json['reactivityToNoise'] ?? "unchanged",
      reactivityToSilence: json['reactivityToSilence'] ?? "unchanged",
      reactivityToStress: (json['reactivityToStress'] ?? 5.0).toDouble(),
      reactivityToFatigue: (json['reactivityToFatigue'] ?? 5.0).toDouble(),
      reactivityToMovement: (json['reactivityToMovement'] ?? 0.0).toDouble(),
      reactivityToJawNeck: json['reactivityToJawNeck'] ?? false,
      morningIntensity: (json['morningIntensity'] ?? 5.0).toDouble(),
      eveningIntensity: (json['eveningIntensity'] ?? 5.0).toDouble(),
      sleepImpact: (json['sleepImpact'] ?? 5.0).toDouble(),
      environmentType: json['environmentType'] ?? "mixed",
      preferredSessionTime: json['preferredSessionTime'] ?? "flexible",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tinnitusDuration': tinnitusDuration,
      'tinnitusOnsetType': tinnitusOnsetType,
      'toneType': toneType,
      'toneStability': toneStability,
      'location': location,
      'selfReportedFrequencyHz': selfReportedFrequencyHz,
      'selfReportedLoudness': selfReportedLoudness,
      'dominance': dominance,
      'awareness': awareness,
      'reactivityToNoise': reactivityToNoise,
      'reactivityToSilence': reactivityToSilence,
      'reactivityToStress': reactivityToStress,
      'reactivityToFatigue': reactivityToFatigue,
      'reactivityToMovement': reactivityToMovement,
      'reactivityToJawNeck': reactivityToJawNeck,
      'morningIntensity': morningIntensity,
      'eveningIntensity': eveningIntensity,
      'sleepImpact': sleepImpact,
      'environmentType': environmentType,
      'preferredSessionTime': preferredSessionTime,
    };
  }

  UserProfile copyWith({
    String? tinnitusDuration,
    String? tinnitusOnsetType,
    String? toneType,
    String? toneStability,
    String? location,
    double? selfReportedFrequencyHz,
    double? selfReportedLoudness,
    double? dominance,
    double? awareness,
    String? reactivityToNoise,
    String? reactivityToSilence,
    double? reactivityToStress,
    double? reactivityToFatigue,
    double? reactivityToMovement,
    bool? reactivityToJawNeck,
    double? morningIntensity,
    double? eveningIntensity,
    double? sleepImpact,
    String? environmentType,
    String? preferredSessionTime,
  }) {
    return UserProfile(
      tinnitusDuration: tinnitusDuration ?? this.tinnitusDuration,
      tinnitusOnsetType: tinnitusOnsetType ?? this.tinnitusOnsetType,
      toneType: toneType ?? this.toneType,
      toneStability: toneStability ?? this.toneStability,
      location: location ?? this.location,
      selfReportedFrequencyHz: selfReportedFrequencyHz ?? this.selfReportedFrequencyHz,
      selfReportedLoudness: selfReportedLoudness ?? this.selfReportedLoudness,
      dominance: dominance ?? this.dominance,
      awareness: awareness ?? this.awareness,
      reactivityToNoise: reactivityToNoise ?? this.reactivityToNoise,
      reactivityToSilence: reactivityToSilence ?? this.reactivityToSilence,
      reactivityToStress: reactivityToStress ?? this.reactivityToStress,
      reactivityToFatigue: reactivityToFatigue ?? this.reactivityToFatigue,
      reactivityToMovement: reactivityToMovement ?? this.reactivityToMovement,
      reactivityToJawNeck: reactivityToJawNeck ?? this.reactivityToJawNeck,
      morningIntensity: morningIntensity ?? this.morningIntensity,
      eveningIntensity: eveningIntensity ?? this.eveningIntensity,
      sleepImpact: sleepImpact ?? this.sleepImpact,
      environmentType: environmentType ?? this.environmentType,
      preferredSessionTime: preferredSessionTime ?? this.preferredSessionTime,
    );
  }
}

class UserSessionRecord {
  String sessionId;
  String timestamp;
  String moduleUsed;
  Map<String, dynamic> parametersUsed;
  int sessionDuration;
  int userDominanceRating;
  int userStabilityRating;
  String userPerceptionChange;
  String notes;

  UserSessionRecord({
    required this.sessionId,
    required this.timestamp,
    required this.moduleUsed,
    required this.parametersUsed,
    required this.sessionDuration,
    required this.userDominanceRating,
    required this.userStabilityRating,
    required this.userPerceptionChange,
    required this.notes,
  });

  factory UserSessionRecord.fromJson(Map<String, dynamic> json) {
    return UserSessionRecord(
      sessionId: json['sessionId'] ?? '',
      timestamp: json['timestamp'] ?? '',
      moduleUsed: json['moduleUsed'] ?? '',
      parametersUsed: json['parametersUsed'] ?? {},
      sessionDuration: json['sessionDuration'] ?? 0,
      userDominanceRating: json['userDominanceRating'] ?? 0,
      userStabilityRating: json['userStabilityRating'] ?? 0,
      userPerceptionChange: json['userPerceptionChange'] ?? 'same',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'timestamp': timestamp,
      'moduleUsed': moduleUsed,
      'parametersUsed': parametersUsed,
      'sessionDuration': sessionDuration,
      'userDominanceRating': userDominanceRating,
      'userStabilityRating': userStabilityRating,
      'userPerceptionChange': userPerceptionChange,
      'notes': notes,
    };
  }
}
