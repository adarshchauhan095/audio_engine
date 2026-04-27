import 'package:audio_engine/hearing_profile_flow/hearing_profile_flow.dart';
import 'package:audio_engine/storage/tinnitx_user_profile_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:audio_engine/session/audio_runtime_controller.dart';

void main() {
  testWidgets('HearingProfileFlow can complete with skips and persists profile', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final runtime = AudioRuntimeController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HearingProfileFlow(runtime: runtime),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Screen 1
    expect(find.text('Hearing Profile Check'), findsOneWidget);
    await tester.tap(find.text('Start Hearing Profile Check'));
    await tester.pumpAndSettle();

    // Screen 2 (250 Hz) - Skip Test
    expect(find.text('Tone at 250 Hz'), findsOneWidget);
    await tester.tap(find.text('Skip Test'));
    await tester.pumpAndSettle();

    // Screen 3 (1000 Hz) - Next (default 50%)
    expect(find.text('Tone at 1000 Hz'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Screen 4 (AMS) - Skip Test
    expect(find.textContaining('Tone at'), findsOneWidget);
    await tester.tap(find.text('Skip Test'));
    await tester.pumpAndSettle();

    // Screen 5 (12k) - Skip Test
    expect(find.text('Tone at 12000 Hz'), findsOneWidget);
    await tester.tap(find.text('Skip Test'));
    await tester.pumpAndSettle();

    // Screen 6 - Continue (persist)
    expect(find.text('Hearing Profile Complete'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final profile = await TinnitXUserProfileStorage.loadProfile();
    expect(profile, isNotNull);
    expect(profile!.hearingProfile, isNotNull);
    expect(profile.hearingProfile!.threshold250, isNull);
    expect(profile.hearingProfile!.thresholdAMS, isNull);
    expect(profile.hearingProfile!.threshold12k, isNull);
    expect(profile.hearingProfile!.balancing1000, 50.0);
    expect(profile.hearingProfile!.maxHearableFrequency, 1000);
    expect(profile.hearingProfile!.timestamp, isNotEmpty);

    runtime.dispose();
  });
}

