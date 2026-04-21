import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';
import '../../storage/detected_frequency_storage.dart';
import '../../storage/tinnitx_user_profile_storage.dart';
import 'edge_detection/edge_detection_intro_screen.dart';

class HearingProfileCheckScreen extends StatefulWidget {
  const HearingProfileCheckScreen({super.key, required this.runtime});

  final AudioRuntimeController runtime;

  @override
  State<HearingProfileCheckScreen> createState() =>
      _HearingProfileCheckScreenState();
}

class _HearingProfileCheckScreenState extends State<HearingProfileCheckScreen> {
  static const String _userId = 'local_user';

  late Future<double?> _freqFuture;

  @override
  void initState() {
    super.initState();
    _freqFuture = _loadMatchedFrequencyHz();
  }

  Future<double?> _loadMatchedFrequencyHz() async {
    // Priority:
    // 1) Profile tinnitusFrequency (schema-aligned)
    // 2) Legacy detected frequency storage
    // 3) null (user must run AMS first)
    final profile =
        await TinnitXUserProfileStorage.getOrCreateMinimal(userId: _userId);
    final double fromProfile = profile.tinnitusFrequency;
    if (fromProfile.isFinite && fromProfile > 0) {
      return fromProfile;
    }

    final double? fromDetected =
        await DetectedFrequencyStorage.loadDetectedFrequency();
    if (fromDetected != null && fromDetected.isFinite && fromDetected > 0) {
      return fromDetected;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double?>(
      future: _freqFuture,
      builder: (context, snap) {
        final bool done = snap.connectionState == ConnectionState.done;
        if (!done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Hearing Profile Check')),
            body: const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final double? hz = snap.data;
        return EdgeDetectionIntroScreen(
          runtime: widget.runtime,
          amsFrequencyHz: hz,
          key: ValueKey<String>('hpe_intro_${hz ?? 'none'}'),
        );
      },
    );
  }
}

