import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().toList();
  for (final file in files) {
    if (file.path.endsWith('.dart')) {
      String content = file.readAsStringSync();
      
      String newContent = content
        .replaceAll('PatientProfile', 'TherapyProfile')
        .replaceAll('patient_session_catalog.dart', 'profile_session_catalog.dart')
        .replaceAll('patient_sessions_screen.dart', 'profile_sessions_screen.dart')
        .replaceAll('Patient', 'Profile')
        .replaceAll('patient', 'profile');

      if (newContent != content) {
        file.writeAsStringSync(newContent);
        print('Updated ${file.path}');
      }
    }
  }

  final cat = File('lib/session/patient_session_catalog.dart');
  if (cat.existsSync()) {
    cat.renameSync('lib/session/profile_session_catalog.dart');
    print('Renamed catalog');
  }

  final screen = File('lib/ui/screens/patient_sessions_screen.dart');
  if (screen.existsSync()) {
    screen.renameSync('lib/ui/screens/profile_sessions_screen.dart');
    print('Renamed screen');
  }
}
