import 'package:flutter/material.dart';

import '../../hearing_threshold/hearing_threshold_controller.dart';
import '../../models/hearing_threshold_result.dart';
import '../../session/audio_runtime_controller.dart';
import '../../storage/detected_frequency_storage.dart';
import '../../storage/hearing_threshold_storage.dart';
import '../../storage/tinnitx_user_profile_storage.dart';
import 'hearing_profile_check_screen.dart';

class HearingThresholdCheckScreen extends StatefulWidget {
  const HearingThresholdCheckScreen({super.key, required this.runtime});

  final AudioRuntimeController runtime;

  @override
  State<HearingThresholdCheckScreen> createState() =>
      _HearingThresholdCheckScreenState();
}

class _HearingThresholdCheckScreenState extends State<HearingThresholdCheckScreen> {
  static const String _userId = 'local_user';

  late final HearingThresholdController _controller;
  late Future<double?> _freqFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = HearingThresholdController(widget.runtime);
    _freqFuture = _loadMatchedFrequencyHz();
  }

  Future<double?> _loadMatchedFrequencyHz() async {
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
  void dispose() {
    _controller.stopTone();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final HearingThresholdResult result = _controller.buildResult();
      await HearingThresholdStorage.saveResult(result);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

        final double? amsHz = snap.data;
        final bool missingAms = amsHz == null;

        if (_controller.amsFrequencyHz == null && !missingAms) {
          _controller.init(amsFrequencyHz: amsHz);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hearing Profile Check'),
            actions: [
              IconButton(
                tooltip: 'Legacy slider test',
                icon: const Icon(Icons.tune),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HearingProfileCheckScreen(runtime: widget.runtime),
                    ),
                  );
                },
              ),
            ],
          ),
          body: missingAms
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Missing AMS frequency.',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please complete AMS Matching first.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Back'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              : ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final bool playing = widget.runtime.playing.value;
                    final int step = _controller.index + 1;
                    final int total = HearingThresholdController.testFrequenciesHz.length;
                    final double progress = step / total;

                    if (_controller.finished) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              'Check Complete',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Save your thresholds to My Profile & Progress.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: _saving ? null : _saveAndExit,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: _saving
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Save & Continue'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 16),
                          Text(
                            'Tone at ${_controller.currentHz.toStringAsFixed(0)} Hz',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Level: ${(_controller.level * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton.tonal(
                            onPressed: _controller.toggleTone,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(playing ? 'Stop' : 'Play'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(
                                  onPressed: _controller.respondHeard,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text('Heard'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _controller.respondNotHeard,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text('Not heard'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Skip'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

