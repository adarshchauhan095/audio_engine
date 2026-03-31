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
        );
      case AmsPhase.coarse:
        return _MatchingPane(
          key: const ValueKey<String>('coarse'),
          title: 'Coarse matching',
          subtitle:
              'Large steps (${AmsMatchingController.coarseStepHz.toStringAsFixed(0)} Hz). '
              'Use Higher / Lower, then OK when the tone is close enough.',
          frequencyHz: _controller.currentHz,
          higherLabel: 'Higher',
          lowerLabel: 'Lower',
          primaryLabel: 'OK',
          onHigher: engineReady ? _controller.higher : null,
          onLower: engineReady ? _controller.lower : null,
          onPrimary: engineReady
              ? () async {
                  await _controller.confirmCoarse();
                }
              : null,
        );
      case AmsPhase.fine:
        return _MatchingPane(
          key: const ValueKey<String>('fine'),
          title: 'Fine matching',
          subtitle:
              'Small steps (${AmsMatchingController.fineStepHz.toStringAsFixed(0)} Hz) '
              'within ±${AmsMatchingController.fineBandHalfWidthHz.toStringAsFixed(0)} Hz '
              'of your coarse pick.',
          frequencyHz: _controller.currentHz,
          higherLabel: 'Higher',
          lowerLabel: 'Lower',
          primaryLabel: 'OK',
          onHigher: engineReady ? _controller.higher : null,
          onLower: engineReady ? _controller.lower : null,
          onPrimary: engineReady
              ? () async {
                  await _controller.confirmFine();
                }
              : null,
        );
      case AmsPhase.validation:
        return _MatchingPane(
          key: const ValueKey<String>('validation'),
          title: 'Validation',
          subtitle:
              'Micro steps (${AmsMatchingController.microStepHz.toStringAsFixed(0)} Hz) '
              'within ±${AmsMatchingController.validationBandHalfWidthHz.toStringAsFixed(0)} Hz '
              'of your fine pick. Press Confirm when ready.',
          frequencyHz: _controller.currentHz,
          higherLabel: 'Adjust Higher',
          lowerLabel: 'Adjust Lower',
          primaryLabel: 'Confirm',
          onHigher: engineReady ? _controller.higher : null,
          onLower: engineReady ? _controller.lower : null,
          onPrimary: engineReady
              ? () async {
                  await _controller.confirmValidation();
                }
              : null,
        );
      case AmsPhase.result:
        final double? hz = _controller.finalFrequency;
        return _ResultPane(
          key: const ValueKey<String>('result'),
          frequencyHz: hz ?? 0,
          onSave: hz != null && engineReady && !_saving ? _onSaveAndContinue : null,
          busy: _saving,
        );
    }
  }
}

class _StartPane extends StatelessWidget {
  const _StartPane({super.key, this.onStart});

  final Future<void> Function()? onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Automated Matching System',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We will find your tinnitus frequency in three steps.',
          style: Theme.of(context).textTheme.bodyLarge,
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
    required this.subtitle,
    required this.frequencyHz,
    required this.higherLabel,
    required this.lowerLabel,
    required this.primaryLabel,
    this.onHigher,
    this.onLower,
    this.onPrimary,
  });

  final String title;
  final String subtitle;
  final double frequencyHz;
  final String higherLabel;
  final String lowerLabel;
  final String primaryLabel;
  final VoidCallback? onHigher;
  final VoidCallback? onLower;
  final Future<void> Function()? onPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Current tone',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${frequencyHz.toStringAsFixed(1)} Hz',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onLower,
                child: Text(lowerLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onHigher,
                child: Text(higherLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }
}

class _ResultPane extends StatelessWidget {
  const _ResultPane({
    super.key,
    required this.frequencyHz,
    this.onSave,
    this.busy = false,
  });

  final double frequencyHz;
  final VoidCallback? onSave;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          'Your matched frequency is: ${frequencyHz.toStringAsFixed(1)} Hz',
          style: Theme.of(context).textTheme.titleLarge,
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
        const SizedBox(height: 24),
      ],
    );
  }
}
