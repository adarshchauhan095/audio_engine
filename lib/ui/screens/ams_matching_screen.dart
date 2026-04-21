import 'dart:async';

import 'package:flutter/material.dart';

import '../../ams/ams_matching_controller.dart';
import '../../session/audio_runtime_controller.dart';

/// Automated Matching System (AMS) — structural flow only (wireframe parity).
///
/// Five logical phases: start → coarse → fine → validation → result.
class AmsMatchingScreen extends StatefulWidget {
  const AmsMatchingScreen({super.key, required this.runtime});

  final AudioRuntimeController runtime;

  @override
  State<AmsMatchingScreen> createState() => _AmsMatchingScreenState();
}

class _AmsMatchingScreenState extends State<AmsMatchingScreen> {
  late final AmsMatchingController _controller;
  bool _saving = false;
  bool _advancing = false;

  static String _formatHz(double hz) {
    final int rounded = hz.round();
    final String s = rounded.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final int remaining = s.length - i;
      out.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) out.write(',');
    }
    return '$out Hz';
  }

  Future<void> _advanceOnce(Future<void> Function() action) async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.runtime.prepareForAmsMatching();
    _controller = AmsMatchingController(widget.runtime);
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller.stopPlaybackIfOwned();
    super.dispose();
  }

  Future<void> _onSaveAndContinue() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bool ok = await _controller.saveAndContinue();
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved ${_controller.finalFrequency!.toStringAsFixed(1)} Hz',
            ),
          ),
        );
        // Return to the caller (My Profile & Progress) after saving.
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save frequency. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool engineReady = widget.runtime.hasEngine;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          _controller.stopPlaybackIfOwned();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Automated Matching System'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Restart',
              onPressed: () {
                _controller.resetPhase();
              },
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (BuildContext context, Widget? _) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: !engineReady
                    ? const Center(
                        key: ValueKey<String>('no_engine'),
                        child: Text('Audio engine unavailable on this platform.'),
                      )
                    : _buildPhaseBody(context, engineReady),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhaseBody(BuildContext context, bool engineReady) {
    switch (_controller.phase) {
      case AmsPhase.start:
        return _StartPane(
          key: const ValueKey<String>('start'),
          onStart: engineReady
              ? () async {
                  await _controller.beginMatching();
                }
              : null,
          onCancel: () => Navigator.of(context).pop(),
        );
      case AmsPhase.coarse:
        return _MatchingPane(
          key: const ValueKey<String>('coarse'),
          title: 'Coarse Matching',
          stepLabel: 'Step 1 of 3 – Find the closest',
          frequencyHz: _controller.currentHz,
          higherLabel: 'Higher',
          lowerLabel: 'Lower',
          primaryLabel: 'OK',
          onHigher: engineReady ? _controller.higher : null,
          onLower: engineReady ? _controller.lower : null,
          onHigherSweepStart: engineReady ? _controller.startSweepingHigher : null,
          onLowerSweepStart: engineReady ? _controller.startSweepingLower : null,
          onSweepEnd: engineReady ? _controller.stopSweeping : null,
          onPrimary: engineReady && !_advancing
              ? () async {
                  await _advanceOnce(_controller.confirmCoarse);
                }
              : null,
        );
      case AmsPhase.fine:
        return _MatchingPane(
          key: const ValueKey<String>('fine'),
          title: 'Fine Matching',
          stepLabel: 'Step 2 of 3 – Refine the tone',
          frequencyHz: _controller.currentHz,
          higherLabel: 'Higher',
          lowerLabel: 'Lower',
          primaryLabel: 'OK',
          onHigher: engineReady ? _controller.higher : null,
          onLower: engineReady ? _controller.lower : null,
          onHigherSweepStart: engineReady ? _controller.startSweepingHigher : null,
          onLowerSweepStart: engineReady ? _controller.startSweepingLower : null,
          onSweepEnd: engineReady ? _controller.stopSweeping : null,
          onPrimary: engineReady && !_advancing
              ? () async {
                  await _advanceOnce(_controller.confirmFine);
                }
              : null,
        );
      case AmsPhase.validation:
        return _MatchingPane(
          key: const ValueKey<String>('validation'),
          title: 'Micro Matching',
          stepLabel: 'Step 3 of 3 – Final adjustment',
          frequencyHz: _controller.currentHz,
          higherLabel: 'Higher',
          lowerLabel: 'Lower',
          primaryLabel: 'OK',
          onHigher: engineReady ? _controller.higher : null,
          onLower: engineReady ? _controller.lower : null,
          onHigherSweepStart: engineReady ? _controller.startSweepingHigher : null,
          onLowerSweepStart: engineReady ? _controller.startSweepingLower : null,
          onSweepEnd: engineReady ? _controller.stopSweeping : null,
          onPrimary: engineReady && !_advancing
              ? () async {
                  await _advanceOnce(_controller.confirmValidation);
                }
              : null,
        );
      case AmsPhase.result:
        final double? hz = _controller.finalFrequency;
        return _ResultPane(
          key: const ValueKey<String>('result'),
          frequencyHz: hz ?? 0,
          onSave: hz != null && engineReady && !_saving ? _onSaveAndContinue : null,
          onRepeat: () {
            _controller.resetPhase();
          },
          busy: _saving,
        );
    }
  }
}

class _StartPane extends StatelessWidget {
  const _StartPane({super.key, this.onStart, this.onCancel});

  final Future<void> Function()? onStart;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'AMS Intro',
          style: Theme.of(context).textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Automated Matching System',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'This adjustment finds the tone that matches your tinnitus.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        FilledButton(
          onPressed: onStart == null
              ? null
              : () {
                  unawaited(onStart!());
                },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Start Matching'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MatchingPane extends StatelessWidget {
  const _MatchingPane({
    super.key,
    required this.title,
    required this.stepLabel,
    required this.frequencyHz,
    required this.higherLabel,
    required this.lowerLabel,
    required this.primaryLabel,
    this.onHigher,
    this.onLower,
    this.onHigherSweepStart,
    this.onLowerSweepStart,
    this.onSweepEnd,
    this.onPrimary,
  });

  final String title;
  final String stepLabel;
  final double frequencyHz;
  final String higherLabel;
  final String lowerLabel;
  final String primaryLabel;
  final VoidCallback? onHigher;
  final VoidCallback? onLower;
  final VoidCallback? onHigherSweepStart;
  final VoidCallback? onLowerSweepStart;
  final VoidCallback? onSweepEnd;
  final Future<void> Function()? onPrimary;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    const double visualMinHz = 1000;
    const double visualMaxHz = 12000;
    final double clampedHz = frequencyHz.clamp(visualMinHz, visualMaxHz);
    final double sliderValue =
        (clampedHz - visualMinHz) / (visualMaxHz - visualMinHz);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          stepLabel,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Text(
          _AmsMatchingScreenState._formatHz(frequencyHz),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: primary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: primary.withValues(alpha: 0.45),
            inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
            thumbColor: primary,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: sliderValue.isFinite ? sliderValue : 0,
            min: 0,
            max: 1,
            onChanged: null, // visual only
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onLower,
                onLongPressStart:
                    onLowerSweepStart == null ? null : (_) => onLowerSweepStart!(),
                onLongPressEnd: onSweepEnd == null ? null : (_) => onSweepEnd!(),
                onLongPressUp: onSweepEnd,
                child: FilledButton.tonal(
                  onPressed: onLower,
                  child: Text(lowerLabel),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onHigher,
                onLongPressStart: onHigherSweepStart == null
                    ? null
                    : (_) => onHigherSweepStart!(),
                onLongPressEnd: onSweepEnd == null ? null : (_) => onSweepEnd!(),
                onLongPressUp: onSweepEnd,
                child: FilledButton.tonal(
                  onPressed: onHigher,
                  child: Text(higherLabel),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onPrimary == null
              ? null
              : () {
                  unawaited(onPrimary!());
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(primaryLabel),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ResultPane extends StatelessWidget {
  const _ResultPane({
    super.key,
    required this.frequencyHz,
    this.onSave,
    this.onRepeat,
    this.busy = false,
  });

  final double frequencyHz;
  final VoidCallback? onSave;
  final VoidCallback? onRepeat;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          'Matching Complete',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Text(
          'Your matched frequency is: ${_AmsMatchingScreenState._formatHz(frequencyHz)}',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: primary,
              ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        FilledButton(
          onPressed: busy ? null : onSave,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save & Continue'),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: busy ? null : onRepeat,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Repeat Matching'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
