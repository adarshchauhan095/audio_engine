import 'dart:async';

import 'package:flutter/material.dart';

import '../models/hearing_profile.dart';
import '../session/audio_runtime_controller.dart';
import '../storage/tinnitx_user_profile_storage.dart';
import 'tone_generator_service.dart';

class HearingProfileFlow extends StatefulWidget {
  const HearingProfileFlow({super.key, required this.runtime});

  final AudioRuntimeController runtime;

  @override
  State<HearingProfileFlow> createState() => _HearingProfileFlowState();
}

class _HearingProfileFlowState extends State<HearingProfileFlow> {
  static const String _userId = 'local_user';

  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  late final ToneGeneratorService _tones;
  late final Future<double> _amsFrequencyFuture;

  double? threshold250;
  double balancing1000 = 50.0; // percent 0–100
  double? thresholdAMS;
  double? threshold12k;

  @override
  void initState() {
    super.initState();
    _tones = ToneGeneratorService(widget.runtime);
    _amsFrequencyFuture = _loadAmsFrequencyHz();
  }

  @override
  void dispose() {
    _tones.dispose();
    super.dispose();
  }

  Future<double> _loadAmsFrequencyHz() async {
    // The client spec says the AMS frequency is provided by the system.
    // In this app, the profile's tinnitusFrequency is always set (minimal
    // profile defaults to 4000 Hz), so this remains deterministic.
    final profile =
        await TinnitXUserProfileStorage.getOrCreateMinimal(userId: _userId);
    final double hz = profile.tinnitusFrequency;
    return (hz.isFinite && hz > 0) ? hz : 4000.0;
  }

  void _toastAudioUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio output not available.')),
    );
  }

  Future<void> _persistAndExit({required double amsHz}) async {
    final String nowIso = DateTime.now().toIso8601String();
    final double maxHz = HearingProfile.computeMaxHearableFrequency(
      amsFrequencyHz: amsHz,
      thresholdAMS: thresholdAMS,
      threshold12k: threshold12k,
    );

    final HearingProfile hp = HearingProfile(
      threshold250: threshold250,
      balancing1000: balancing1000,
      thresholdAMS: thresholdAMS,
      threshold12k: threshold12k,
      maxHearableFrequency: maxHz,
      timestamp: nowIso,
    );

    final profile =
        await TinnitXUserProfileStorage.getOrCreateMinimal(userId: _userId);
    final updated = profile.copyWith(hearingProfile: hp);
    await TinnitXUserProfileStorage.saveProfile(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _amsFrequencyFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Hearing Profile')),
            body: const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final double amsHz = snap.data ?? 4000.0;

        return Navigator(
          key: _navKey,
          onGenerateRoute: (settings) {
            final String name = settings.name ?? '/';
            late Widget page;
            switch (name) {
              case '/':
                page = _IntroScreen(
                  onStart: () => _navKey.currentState!.pushNamed('/t250'),
                  onSkip: () => Navigator.of(context).pop(false),
                );
                break;
              case '/t250':
                page = _ThresholdScreen(
                  tones: _tones,
                  titleHz: 250,
                  onPlayFailed: _toastAudioUnavailable,
                  onSet: (v) {
                    threshold250 = v;
                    _navKey.currentState!.pushNamed('/b1000');
                  },
                  onSkip: () {
                    threshold250 = null;
                    _navKey.currentState!.pushNamed('/b1000');
                  },
                );
                break;
              case '/b1000':
                page = _BalancingScreen(
                  tones: _tones,
                  onPlayFailed: _toastAudioUnavailable,
                  initialPercent: balancing1000,
                  onNext: (percent) {
                    balancing1000 = percent;
                    _navKey.currentState!.pushNamed('/tams');
                  },
                );
                break;
              case '/tams':
                page = _ThresholdScreen(
                  tones: _tones,
                  titleHz: amsHz.round(),
                  onPlayFailed: _toastAudioUnavailable,
                  onSet: (v) {
                    thresholdAMS = v;
                    _navKey.currentState!.pushNamed('/t12k');
                  },
                  onSkip: () {
                    thresholdAMS = null;
                    _navKey.currentState!.pushNamed('/t12k');
                  },
                );
                break;
              case '/t12k':
                page = _ThresholdScreen(
                  tones: _tones,
                  titleHz: 12000,
                  onPlayFailed: _toastAudioUnavailable,
                  onSet: (v) {
                    threshold12k = v;
                    _navKey.currentState!.pushNamed('/summary');
                  },
                  onSkip: () {
                    threshold12k = null;
                    _navKey.currentState!.pushNamed('/summary');
                  },
                );
                break;
              case '/summary':
                page = _SummaryScreen(
                  onContinue: () => _persistAndExit(amsHz: amsHz),
                );
                break;
              default:
                page = const SizedBox.shrink();
            }

            return MaterialPageRoute(builder: (_) => page, settings: settings);
          },
        );
      },
    );
  }
}

class _BaseScaffold extends StatelessWidget {
  const _BaseScaffold({required this.body});
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hearing Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: body,
        ),
      ),
    );
  }
}

class _IntroScreen extends StatelessWidget {
  const _IntroScreen({required this.onStart, required this.onSkip});
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _BaseScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Hearing Profile Check',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'This short check helps us understand how you perceive\n'
            'different frequencies.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text('• No medical test'),
          const SizedBox(height: 6),
          const Text('• Takes about 1–2 minutes'),
          const SizedBox(height: 6),
          const Text('• Helps optimize your personalized sound programs'),
          const Spacer(),
          FilledButton(
            onPressed: onStart,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Start Hearing Profile Check'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onSkip,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Skip'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdScreen extends StatefulWidget {
  const _ThresholdScreen({
    required this.tones,
    required this.titleHz,
    required this.onPlayFailed,
    required this.onSet,
    required this.onSkip,
  });

  final ToneGeneratorService tones;
  final int titleHz;
  final VoidCallback onPlayFailed;
  final ValueChanged<double> onSet;
  final VoidCallback onSkip;

  @override
  State<_ThresholdScreen> createState() => _ThresholdScreenState();
}

class _ThresholdScreenState extends State<_ThresholdScreen> {
  bool _busy = false;
  double _level01 = 0.30;

  @override
  void initState() {
    super.initState();
    widget.tones.configure(frequencyHz: widget.titleHz.toDouble(), level01: _level01);
  }

  @override
  void dispose() {
    widget.tones.stop();
    super.dispose();
  }

  Future<void> _debounced(FutureOr<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Future<void>.sync(fn);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool playing = widget.tones.isPlaying;

    return _BaseScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Tone at ${widget.titleHz} Hz',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _busy
                ? null
                : () => _debounced(() {
                      if (!widget.tones.canOutputAudio) {
                        widget.onPlayFailed();
                        return;
                      }
                      widget.tones.toggle();
                      setState(() {});
                    }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(playing ? 'Stop' : 'Play'),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Can you hear this tone?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _debounced(() {
                            _level01 = widget.tones.stepDb(-2.0);
                            widget.tones.configure(
                              frequencyHz: widget.titleHz.toDouble(),
                              level01: _level01,
                            );
                          }),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Heard'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _debounced(() {
                            _level01 = widget.tones.stepDb(2.0);
                            widget.tones.configure(
                              frequencyHz: widget.titleHz.toDouble(),
                              level01: _level01,
                            );
                          }),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Not heard'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'When the tone becomes just barely audible:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _debounced(() {
                      widget.tones.stop();
                      widget.onSet(_level01);
                    }),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Set Threshold'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _busy
                ? null
                : () => _debounced(() {
                      widget.tones.stop();
                      widget.onSkip();
                    }),
            child: const Text('Skip Test'),
          ),
        ],
      ),
    );
  }
}

class _BalancingScreen extends StatefulWidget {
  const _BalancingScreen({
    required this.tones,
    required this.onPlayFailed,
    required this.initialPercent,
    required this.onNext,
  });

  final ToneGeneratorService tones;
  final VoidCallback onPlayFailed;
  final double initialPercent;
  final ValueChanged<double> onNext;

  @override
  State<_BalancingScreen> createState() => _BalancingScreenState();
}

class _BalancingScreenState extends State<_BalancingScreen> {
  bool _busy = false;
  double _percent = 50.0;

  @override
  void initState() {
    super.initState();
    _percent = widget.initialPercent.clamp(0.0, 100.0);
    widget.tones.configure(frequencyHz: 1000.0, level01: _percent / 100.0);
  }

  @override
  void dispose() {
    widget.tones.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool playing = widget.tones.isPlaying;
    return _BaseScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Tone at 1000 Hz',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _busy
                ? null
                : () {
                    if (!widget.tones.canOutputAudio) {
                      widget.onPlayFailed();
                      return;
                    }
                    setState(() {
                      widget.tones.toggle();
                    });
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(playing ? 'Stop' : 'Play'),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Adjust loudness:'),
          Slider(
            value: _percent,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: _busy
                ? null
                : (v) {
                    setState(() => _percent = v);
                    widget.tones.setLevelSmooth(v / 100.0);
                  },
          ),
          const SizedBox(height: 6),
          Text(
            'Current Level: ${_percent.toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() => _busy = true);
                    widget.tones.stop();
                    widget.onNext(_percent);
                  },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryScreen extends StatelessWidget {
  const _SummaryScreen({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _BaseScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Hearing Profile Complete',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your hearing profile has been created.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text('• Lower audible range'),
          const SizedBox(height: 6),
          const Text('• Upper audible range'),
          const SizedBox(height: 6),
          const Text('• Sensitivity around tinnitus frequency'),
          const Spacer(),
          FilledButton(
            onPressed: onContinue,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

