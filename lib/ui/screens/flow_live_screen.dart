import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../session/audio_runtime_controller.dart';
import '../../session/flow/flow_definition.dart';
import '../../session/flow/flow_engine_controller.dart';
import '../../session/flow/flow_state.dart';
import '../../session/flow/flow_step.dart';
import '../../session/phase3_module_params.dart';
import '../../session/therapy_session_controller.dart';
import '../../storage/detected_frequency_storage.dart';

/// Phase 4 — live flow execution UI.
class FlowLiveScreen extends StatefulWidget {
  const FlowLiveScreen({super.key, required this.flow});

  final FlowDefinition flow;

  @override
  State<FlowLiveScreen> createState() => _FlowLiveScreenState();
}

class _FlowLiveScreenState extends State<FlowLiveScreen> {
  late final AudioRuntimeController _runtime;
  late final FlowEngineController _flowEngine;

  double _tinnitusFrequencyHz = 4000.0;
  bool _loadingFrequency = true;
  double _sessionDisplayBaseAmp = 0.15;
  bool _flowStarted = false;

  @override
  void initState() {
    super.initState();
    _runtime = AudioRuntimeController();
    _runtime.attachRouteRecoveryChannel(
      ServicesBinding.instance.defaultBinaryMessenger,
    );
    _runtime.prepareForAdaptiveTherapy();
    final TherapySessionController? session = _runtime.therapySession;
    _flowEngine = FlowEngineController(session!);
    _loadFrequencyAndStart();
  }

  Future<void> _loadFrequencyAndStart() async {
    final double? stored =
        await DetectedFrequencyStorage.loadDetectedFrequency();
    if (!mounted) return;
    setState(() {
      _tinnitusFrequencyHz = stored ?? _runtime.frequency.value;
      _loadingFrequency = false;
      _sessionDisplayBaseAmp = _runtime.amplitude.value;
    });
    if (_flowStarted) return;
    _flowStarted = true;
    await _flowEngine.startFlow(
      flow: widget.flow,
      tinnitusFrequencyHz: _tinnitusFrequencyHz,
      baseAmp: _sessionDisplayBaseAmp,
    );
    if (_flowEngine.errorMessage.value != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_flowEngine.errorMessage.value!)),
      );
    }
  }

  @override
  void dispose() {
    if (_flowEngine.state.value != FlowEngineState.idle &&
        _flowEngine.state.value != FlowEngineState.finished) {
      _flowEngine.stopFlow();
    }
    _flowEngine.dispose();
    _runtime.dispose();
    super.dispose();
  }

  String _formatHz(double hz) {
    final int rounded = hz.round();
    return rounded.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatClock(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _phaseLabel(TherapyPhase phase) {
    switch (phase) {
      case TherapyPhase.warmup:
        return 'RAMP-UP';
      case TherapyPhase.mainPhase:
        return 'ACTIVE';
      case TherapyPhase.cooldown:
        return 'RAMP-DOWN';
      case TherapyPhase.idle:
        return 'IDLE';
    }
  }

  double _displayFrequency(TherapySessionController session, FlowStep? step) {
    if (step == null) return _tinnitusFrequencyHz;
    final Phase3ModuleParams params = step.resolvedParams();
    return params.engineBaseFreq(_tinnitusFrequencyHz);
  }

  @override
  Widget build(BuildContext context) {
    final TherapySessionController? session = _runtime.therapySession;

    return ValueListenableBuilder<String?>(
      valueListenable: _runtime.error,
      builder: (BuildContext context, String? error, _) {
        if (error != null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.flow.name)),
            body: Center(child: Text('Engine Error: $error')),
          );
        }
        if (session == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return ValueListenableBuilder<FlowEngineState>(
          valueListenable: _flowEngine.state,
          builder: (BuildContext context, FlowEngineState flowState, _) {
            if (flowState == FlowEngineState.feedback || flowState == FlowEngineState.adapt) {
              return Scaffold(
                appBar: AppBar(title: Text(widget.flow.name)),
                body: _FeedbackModal(
                  onSubmit: (i, c, e) async {
                    await _flowEngine.submitFeedback(i, c, e);
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  onSkip: () {
                    _flowEngine.skipFeedback();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  isAdapting: flowState == FlowEngineState.adapt,
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(widget.flow.name),
              ),
              body: _loadingFrequency
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ValueListenableBuilder<int>(
                            valueListenable: _flowEngine.currentStepIndex,
                            builder: (BuildContext context, int stepIdx, _) {
                              return ValueListenableBuilder<int>(
                                valueListenable:
                                    _flowEngine.globalRemainingSeconds,
                                builder: (
                                  BuildContext context,
                                  int globalRemain,
                                  _,
                                ) {
                                  return Text(
                                    'Step ${stepIdx + 1}/${widget.flow.stepCount} · '
                                    'Global ${_formatClock(globalRemain)}',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildActiveModulePanel(session),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Steps',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  ValueListenableBuilder<int>(
                                    valueListenable:
                                        _flowEngine.currentStepIndex,
                                    builder: (
                                      BuildContext context,
                                      int currentIdx,
                                      _,
                                    ) {
                                      return Column(
                                        children: List<Widget>.generate(
                                          widget.flow.steps.length,
                                          (int i) {
                                            final FlowStep step =
                                                widget.flow.steps[i];
                                            final bool isCurrent =
                                                i == currentIdx;
                                            final bool isDone =
                                                i < currentIdx;
                                            return _stepTile(
                                              step: step,
                                              isCurrent: isCurrent,
                                              isDone: isDone,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: flowState ==
                                    FlowEngineState.stopping
                                ? null
                                : () => _flowEngine.stopFlow(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: Colors.red.shade200,
                            ),
                            child: const Text('STOP'),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveModulePanel(TherapySessionController session) {
    return ValueListenableBuilder<int>(
      valueListenable: _flowEngine.currentStepIndex,
      builder: (BuildContext context, int stepIdx, _) {
        final FlowStep? step = stepIdx < widget.flow.steps.length
            ? widget.flow.steps[stepIdx]
            : null;
        final Phase3ModuleParams params =
            step?.resolvedParams() ?? Phase3ModuleParams.defaultsFor(
                  widget.flow.steps.first.module,
                );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step?.moduleLabel ?? '—',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Frequency')),
                    Text(
                      '${_formatHz(_displayFrequency(session, step))} Hz',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Base Amplitude')),
                    Text(_sessionDisplayBaseAmp.toStringAsFixed(3)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Current Phase')),
                    ValueListenableBuilder<TherapyPhase>(
                      valueListenable: session.currentPhase,
                      builder: (BuildContext context, TherapyPhase phase, _) =>
                          Text(
                        _phaseLabel(phase),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Remaining Time')),
                    ValueListenableBuilder<int>(
                      valueListenable: session.remainingSeconds,
                      builder: (BuildContext context, int seconds, _) =>
                          Text(_formatClock(seconds)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Current Intensity (%)')),
                    ValueListenableBuilder<double>(
                      valueListenable: session.intensity,
                      builder: (BuildContext context, double intensity, _) =>
                          Text('${(intensity * 100).toStringAsFixed(0)} %'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: Text('Module Params')),
                    Expanded(
                      flex: 2,
                      child: Text(
                        params.summaryLine(
                          liveRmpRate: session.targetRmpRate,
                          liveBinauralOffset: session.targetBinauralOffset,
                          liveBaseFreqHz: session.baseFreq,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stepTile({
    required FlowStep step,
    required bool isCurrent,
    required bool isDone,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color? bg = isCurrent
        ? scheme.primaryContainer
        : isDone
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : null;
    final TextStyle? style = isDone
        ? TextStyle(color: scheme.onSurface.withValues(alpha: 0.5))
        : null;

    return Card(
      color: bg,
      child: ListTile(
        title: Text(
          '${step.moduleLabel} · ${step.durationMinutes} min · '
          'Max ${step.maxIntensityPercent}%',
          style: style,
        ),
        trailing: isCurrent
            ? Icon(Icons.play_arrow, color: scheme.primary)
            : isDone
                ? Icon(Icons.check, color: scheme.outline)
                : null,
      ),
    );
  }
}

class _FeedbackModal extends StatefulWidget {
  const _FeedbackModal({
    required this.onSubmit,
    required this.onSkip,
    required this.isAdapting,
  });

  final Future<void> Function(
    IntensityPerception,
    ComfortLevel,
    Effectiveness,
  ) onSubmit;
  final VoidCallback onSkip;
  final bool isAdapting;

  @override
  State<_FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<_FeedbackModal> {
  IntensityPerception? _intensity;
  ComfortLevel? _comfort;
  Effectiveness? _effectiveness;

  bool get _canSubmit =>
      _intensity != null && _comfort != null && _effectiveness != null;

  @override
  Widget build(BuildContext context) {
    if (widget.isAdapting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Adapting parameters...'),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Session Completed',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How was the flow? Your feedback helps adapt the system.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Question 1: Intensity
                  Text('1. Intensity perception',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<IntensityPerception>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(
                          value: IntensityPerception.tooLow, label: Text('TOO LOW')),
                      ButtonSegment(
                          value: IntensityPerception.ok, label: Text('OK')),
                      ButtonSegment(
                          value: IntensityPerception.tooHigh, label: Text('TOO HIGH')),
                    ],
                    selected: _intensity != null ? {_intensity!} : {},
                    onSelectionChanged: (Set<IntensityPerception> newSelection) {
                      setState(() {
                        _intensity = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Question 2: Comfort
                  Text('2. Comfort level',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<ComfortLevel>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(
                          value: ComfortLevel.uncomfortable,
                          label: Text('UNCOMFORTABLE')),
                      ButtonSegment(
                          value: ComfortLevel.neutral, label: Text('NEUTRAL')),
                      ButtonSegment(
                          value: ComfortLevel.comfortable,
                          label: Text('COMFORTABLE')),
                    ],
                    selected: _comfort != null ? {_comfort!} : {},
                    onSelectionChanged: (Set<ComfortLevel> newSelection) {
                      setState(() {
                        _comfort = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Question 3: Effectiveness
                  Text('3. Effectiveness',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<Effectiveness>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(
                          value: Effectiveness.low, label: Text('LOW')),
                      ButtonSegment(
                          value: Effectiveness.medium, label: Text('MEDIUM')),
                      ButtonSegment(
                          value: Effectiveness.high, label: Text('HIGH')),
                    ],
                    selected: _effectiveness != null ? {_effectiveness!} : {},
                    onSelectionChanged: (Set<Effectiveness> newSelection) {
                      setState(() {
                        _effectiveness = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onSkip,
                        child: const Text('Skip'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _canSubmit
                            ? () => widget.onSubmit(
                                  _intensity!,
                                  _comfort!,
                                  _effectiveness!,
                                )
                            : null,
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

