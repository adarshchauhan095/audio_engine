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

  /// Tracks routes so [_ThresholdScreen]/[_BalancingScreen] can run
  /// [RouteAware.didPopNext] when the user pops back (stack preserves state).
  final RouteObserver<ModalRoute<Object?>> _routeObserver =
      RouteObserver<ModalRoute<Object?>>();

  late final ToneGeneratorService _tones;
  late final Future<double> _amsFrequencyFuture;

  double? threshold250;
  double balancing1000 = 50.0; // percent 0–100
  double? thresholdAMS;
  double? threshold12k;

  @override
  void initState() {
    super.initState();
    // Stop any running therapy/debug session before the tone generator takes over.
    widget.runtime.prepareForHearingProfile();
    _tones = ToneGeneratorService(widget.runtime);
    _amsFrequencyFuture = _loadAmsFrequencyHz();
  }

  @override
  void dispose() {
    _tones.dispose();
    super.dispose();
  }

  Future<double> _loadAmsFrequencyHz() async {
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
          observers: <NavigatorObserver>[
            _routeObserver,
          ],
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
                  routeObserver: _routeObserver,
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
                  routeObserver: _routeObserver,
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
                  routeObserver: _routeObserver,
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
                  routeObserver: _routeObserver,
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
                  threshold250: threshold250,
                  balancing1000: balancing1000,
                  thresholdAMS: thresholdAMS,
                  threshold12k: threshold12k,
                  amsHz: amsHz,
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

// ---------------------------------------------------------------------------
// Shared scaffold
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Intro screen
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Threshold screen (250 Hz / AMS / 12 kHz)
// ---------------------------------------------------------------------------

class _ThresholdScreen extends StatefulWidget {
  const _ThresholdScreen({
    required this.routeObserver,
    required this.tones,
    required this.titleHz,
    required this.onPlayFailed,
    required this.onSet,
    required this.onSkip,
  });

  final RouteObserver<ModalRoute<Object?>> routeObserver;
  final ToneGeneratorService tones;
  final int titleHz;
  final VoidCallback onPlayFailed;
  final ValueChanged<double> onSet;
  final VoidCallback onSkip;

  @override
  State<_ThresholdScreen> createState() => _ThresholdScreenState();
}

class _ThresholdScreenState extends State<_ThresholdScreen> with RouteAware {
  static const double _initialLevel = 0.30;

  double _level01 = _initialLevel;

  /// Guards against double-taps and in-flight async operations.
  bool _busy = false;

  /// Syncs tone engine + local level when this screen becomes active — both
  /// first visit ([initState]) and return via back navigation ([didPopNext]).
  void _syncFromRouteEntry() {
    _level01 = _initialLevel;
    widget.tones.reset(
      frequencyHz: widget.titleHz.toDouble(),
      level01: _level01,
    );
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _syncFromRouteEntry();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(
      this,
      ModalRoute.of(context)!,
    );
  }

  @override
  void didPopNext() {
    _syncFromRouteEntry();
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    // Immediate stop so the next screen's initState is never racing a fade.
    widget.tones.stopNow();
    super.dispose();
  }

  Future<void> _debounced(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onToggle() => _debounced(() async {
        if (!widget.tones.canOutputAudio) {
          widget.onPlayFailed();
          return;
        }
        await widget.tones.toggle();
        if (mounted) setState(() {});
      });

  Future<void> _onHeard() => _debounced(() async {
        _level01 = widget.tones.stepDb(-2.0);
        widget.tones.configure(
          frequencyHz: widget.titleHz.toDouble(),
          level01: _level01,
        );
      });

  Future<void> _onNotHeard() => _debounced(() async {
        _level01 = widget.tones.stepDb(2.0);
        widget.tones.configure(
          frequencyHz: widget.titleHz.toDouble(),
          level01: _level01,
        );
      });

  Future<void> _onSetThreshold() => _debounced(() async {
        await widget.tones.stopFaded();
        if (!mounted) return;
        widget.onSet(_level01);
      });

  Future<void> _onSkip() => _debounced(() async {
        await widget.tones.stopFaded();
        if (!mounted) return;
        widget.onSkip();
      });

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder keeps the Play/Stop label in sync with the actual
    // audio state even when the engine's async fade changes it externally.
    return ValueListenableBuilder<bool>(
      valueListenable: widget.tones.playingNotifier,
      builder: (context, playing, _) {
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
                onPressed: _busy ? null : _onToggle,
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
                      onPressed: _busy ? null : _onHeard,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Heard'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _onNotHeard,
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
                onPressed: _busy ? null : _onSetThreshold,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Set Threshold'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : _onSkip,
                child: const Text('Skip Test'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Balancing screen (1000 Hz)
// ---------------------------------------------------------------------------

class _BalancingScreen extends StatefulWidget {
  const _BalancingScreen({
    required this.routeObserver,
    required this.tones,
    required this.onPlayFailed,
    required this.initialPercent,
    required this.onNext,
  });

  final RouteObserver<ModalRoute<Object?>> routeObserver;
  final ToneGeneratorService tones;
  final VoidCallback onPlayFailed;
  final double initialPercent;
  final ValueChanged<double> onNext;

  @override
  State<_BalancingScreen> createState() => _BalancingScreenState();
}

class _BalancingScreenState extends State<_BalancingScreen> with RouteAware {
  double _percent = 50.0;

  /// Guards "Next" from being pressed twice.
  bool _navigating = false;

  void _syncFromRouteEntry() {
    // After pushing forward with _navigating=true, underlying route stays
    // mounted; clear so Play/Slider work when user pops back.
    _navigating = false;
    _percent = widget.initialPercent.clamp(0.0, 100.0);
    widget.tones.reset(
      frequencyHz: 1000.0,
      level01: _percent / 100.0,
    );
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _syncFromRouteEntry();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(
      this,
      ModalRoute.of(context)!,
    );
  }

  @override
  void didPopNext() {
    _syncFromRouteEntry();
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    widget.tones.stopNow();
    super.dispose();
  }

  Future<void> _onToggle() async {
    if (!widget.tones.canOutputAudio) {
      widget.onPlayFailed();
      return;
    }
    await widget.tones.toggle();
    if (mounted) setState(() {});
  }

  void _onSliderChanged(double v) {
    setState(() => _percent = v);
    widget.tones.setLevelSmooth(v / 100.0);
  }

  Future<void> _onNext() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await widget.tones.stopFaded();
    if (!mounted) return;
    widget.onNext(_percent);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.tones.playingNotifier,
      builder: (context, playing, _) {
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
              // Play/Stop — identical pattern to _ThresholdScreen
              FilledButton.tonal(
                onPressed: _navigating ? null : _onToggle,
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
                onChanged: _navigating ? null : _onSliderChanged,
              ),
              const SizedBox(height: 6),
              Text(
                'Current Level: ${_percent.toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _navigating ? null : _onNext,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Next'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Summary screen
// ---------------------------------------------------------------------------

class _SummaryScreen extends StatelessWidget {
  const _SummaryScreen({
    required this.onContinue,
    required this.threshold250,
    required this.balancing1000,
    required this.thresholdAMS,
    required this.threshold12k,
    required this.amsHz,
  });

  final VoidCallback onContinue;
  final double? threshold250;
  final double balancing1000;
  final double? thresholdAMS;
  final double? threshold12k;
  final double amsHz;

  String _fmtLevel(double? v) {
    if (v == null) return 'skipped';
    return '${(v * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        label: 'Lower audible range (250 Hz)',
        value: threshold250 == null
            ? 'skipped'
            : 'threshold: ${_fmtLevel(threshold250)}',
      ),
      (
        label: 'Balancing level (1000 Hz)',
        value: '${balancing1000.toStringAsFixed(0)}%',
      ),
      (
        label: 'Tinnitus frequency (${amsHz.toStringAsFixed(0)} Hz)',
        value: thresholdAMS == null
            ? 'skipped'
            : 'threshold: ${_fmtLevel(thresholdAMS)}',
      ),
      (
        label: 'Upper audible range (12 kHz)',
        value: threshold12k == null
            ? 'skipped'
            : 'threshold: ${_fmtLevel(threshold12k)}',
      ),
    ];

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
          const SizedBox(height: 20),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          r.value,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(180),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
