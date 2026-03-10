import '../models/session_params.dart';

class TherapyProfile {
  const TherapyProfile({
    required this.id,
    required this.name,
    required this.conditionSummary,
  });

  final String id;
  final String name;
  final String conditionSummary;
}

class TherapyProfilePreset {
  const TherapyProfilePreset({
    required this.name,
    required this.description,
    this.subthreshold = false,
    this.rmp = false,
    this.pip = false,
    this.sidebands = false,
    this.binaural = false,
  });

  final String name;
  final String description;
  final bool subthreshold;
  final bool rmp;
  final bool pip;
  final bool sidebands;
  final bool binaural;
  
  static const List<TherapyProfilePreset> presets = [
    TherapyProfilePreset(
      name: 'Basic', 
      description: 'Uses only basic sub-threshold noise to gently stimulate the auditory system.',
      subthreshold: true
    ),
    TherapyProfilePreset(
      name: 'Standard', 
      description: 'Includes sub-threshold noise along with Random Modulation Piping (RMP) and Periodic Integration Pulses (PIP) for engaged therapy.',
      subthreshold: true, 
      rmp: true, 
      pip: true
    ),
    TherapyProfilePreset(
      name: 'Premium', 
      description: 'Full featured. Adds sideband harmonics and binaural beats for deep habituation therapy.',
      subthreshold: true, 
      rmp: true, 
      pip: true, 
      sidebands: true, 
      binaural: true
    ),
  ];
}

class SessionTemplate {
  const SessionTemplate({
    required this.title,
    required this.frequencyHz,
    required this.amplitude,
    required this.durationSeconds,
    this.notes = '',
  });

  final String title;
  final double frequencyHz;
  final double amplitude;
  final int durationSeconds;
  final String notes;
}

/// Provides reusable profile examples and template sessions.
///
/// - 6 profile examples
/// - 10 session templates (minimum requested)
class ProfileSessionCatalog {
  static const List<TherapyProfile> profileExamples = <TherapyProfile>[
    TherapyProfile(
      id: 'pt-001',
      name: 'Profile Alpha',
      conditionSummary: 'Left-side tonal tinnitus',
    ),
    TherapyProfile(
      id: 'pt-002',
      name: 'Profile Bravo',
      conditionSummary: 'Broadband high-frequency tinnitus',
    ),
    TherapyProfile(
      id: 'pt-003',
      name: 'Profile Charlie',
      conditionSummary: 'Intermittent medium-frequency tinnitus',
    ),
    TherapyProfile(
      id: 'pt-004',
      name: 'Profile Delta',
      conditionSummary: 'Bilateral ringing with stress trigger',
    ),
    TherapyProfile(
      id: 'pt-005',
      name: 'Profile Echo',
      conditionSummary: 'Stable narrow-band tinnitus',
    ),
    TherapyProfile(
      id: 'pt-006',
      name: 'Profile Foxtrot',
      conditionSummary: 'Night-time intensity spike profile',
    ),
  ];

  static const List<SessionTemplate> templates = <SessionTemplate>[
    SessionTemplate(
      title: 'Session 01 - Baseline',
      frequencyHz: 220.0,
      amplitude: 0.20,
      durationSeconds: 15,
      notes: 'Warm-up baseline exposure',
    ),
    SessionTemplate(
      title: 'Session 02 - Gentle Rise',
      frequencyHz: 280.0,
      amplitude: 0.24,
      durationSeconds: 15,
      notes: 'Low-frequency transition',
    ),
    SessionTemplate(
      title: 'Session 03 - Early Mid',
      frequencyHz: 340.0,
      amplitude: 0.28,
      durationSeconds: 15,
      notes: 'Adaptive midpoint exploration',
    ),
    SessionTemplate(
      title: 'Session 04 - Mid Stabilize',
      frequencyHz: 400.0,
      amplitude: 0.30,
      durationSeconds: 15,
      notes: 'Stability check around lower-mid',
    ),
    SessionTemplate(
      title: 'Session 05 - Mid Plus',
      frequencyHz: 470.0,
      amplitude: 0.32,
      durationSeconds: 15,
      notes: 'Sustained response at moderate gain',
    ),
    SessionTemplate(
      title: 'Session 06 - Upper Mid',
      frequencyHz: 540.0,
      amplitude: 0.34,
      durationSeconds: 15,
      notes: 'Upper-mid tolerance check',
    ),
    SessionTemplate(
      title: 'Session 07 - Presence Band',
      frequencyHz: 620.0,
      amplitude: 0.35,
      durationSeconds: 15,
      notes: 'Sharper response region',
    ),
    SessionTemplate(
      title: 'Session 08 - Pre-High',
      frequencyHz: 700.0,
      amplitude: 0.36,
      durationSeconds: 15,
      notes: 'Transition to high range',
    ),
    SessionTemplate(
      title: 'Session 09 - High Focus',
      frequencyHz: 780.0,
      amplitude: 0.38,
      durationSeconds: 15,
      notes: 'High-frequency directed test',
    ),
    SessionTemplate(
      title: 'Session 10 - Confirmation',
      frequencyHz: 860.0,
      amplitude: 0.40,
      durationSeconds: 15,
      notes: 'Final confirmation session',
    ),
  ];

  static List<SessionParams> buildTemplateSessionsForProfile(
    TherapyProfile profile,
  ) {
    final createdAt = DateTime.now().toIso8601String();
    return List<SessionParams>.generate(templates.length, (int index) {
      final SessionTemplate template = templates[index];
      return SessionParams(
        id: _templateId(profile.id, index + 1),
        profileId: profile.id,
        profileName: profile.name,
        title: template.title,
        frequencyHz: template.frequencyHz,
        amplitude: template.amplitude,
        durationSeconds: template.durationSeconds,
        createdAtIso: createdAt,
        category: 'template',
        notes: template.notes,
      ).normalized();
    });
  }

  static String _templateId(String profileId, int sessionNo) {
    return 'template-$profileId-${sessionNo.toString().padLeft(2, '0')}';
  }
}
