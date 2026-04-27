import 'package:audio_engine/models/hearing_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HearingProfile.computeMaxHearableFrequency', () {
    test('prefers 12k when threshold12k exists', () {
      final v = HearingProfile.computeMaxHearableFrequency(
        amsFrequencyHz: 4321,
        thresholdAMS: 0.2,
        threshold12k: 0.1,
      );
      expect(v, 12000);
    });

    test('uses AMS when thresholdAMS exists and 12k missing', () {
      final v = HearingProfile.computeMaxHearableFrequency(
        amsFrequencyHz: 4321,
        thresholdAMS: 0.2,
        threshold12k: null,
      );
      expect(v, 4321);
    });

    test('falls back to 1000 when thresholds missing', () {
      final v = HearingProfile.computeMaxHearableFrequency(
        amsFrequencyHz: 4321,
        thresholdAMS: null,
        threshold12k: null,
      );
      expect(v, 1000);
    });
  });
}

