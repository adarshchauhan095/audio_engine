import '../models/session_params.dart';

class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.name,
    required this.conditionSummary,
  });

  final String id;
  final String name;
  final String conditionSummary;
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

/// Provides reusable patient examples and template sessions.
///
/// - 6 patient examples
/// - 10 session templates (minimum requested)
class PatientSessionCatalog {
  static const List<PatientProfile> patientExamples = <PatientProfile>[
    PatientProfile(
      id: 'pt-001',
      name: 'Patient Alpha',
      conditionSummary: 'Left-side tonal tinnitus',
    ),
    PatientProfile(
      id: 'pt-002',
      name: 'Patient Bravo',
      conditionSummary: 'Broadband high-frequency tinnitus',
    ),
    PatientProfile(
      id: 'pt-003',
      name: 'Patient Charlie',
      conditionSummary: 'Intermittent medium-frequency tinnitus',
    ),
    PatientProfile(
      id: 'pt-004',
      name: 'Patient Delta',
      conditionSummary: 'Bilateral ringing with stress trigger',
    ),
    PatientProfile(
      id: 'pt-005',
      name: 'Patient Echo',
      conditionSummary: 'Stable narrow-band tinnitus',
    ),
    PatientProfile(
      id: 'pt-006',
      name: 'Patient Foxtrot',
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

  static List<SessionParams> buildTemplateSessionsForPatient(
    PatientProfile patient,
  ) {
    final createdAt = DateTime.now().toIso8601String();
    return List<SessionParams>.generate(templates.length, (int index) {
      final SessionTemplate template = templates[index];
      return SessionParams(
        id: _templateId(patient.id, index + 1),
        patientId: patient.id,
        patientName: patient.name,
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

  static String _templateId(String patientId, int sessionNo) {
    return 'template-$patientId-${sessionNo.toString().padLeft(2, '0')}';
  }
}
