import 'dart:async';

import 'package:flutter/foundation.dart';

import '../phase3_module_params.dart';
import '../phase3_module_type.dart';
import '../therapy_session_controller.dart';
import 'flow_definition.dart';
import 'flow_state.dart';
import 'flow_step.dart';
import 'flow_timer.dart';
import 'flow_transitions.dart';
import '../../storage/anaps_storage.dart';

enum IntensityPerception { tooLow, ok, tooHigh }
enum ComfortLevel { uncomfortable, neutral, comfortable }
enum Effectiveness { low, medium, high }

/// Sequences Phase-3 modules with strict timing and click-free transitions.
class FlowEngineController {
  FlowEngineController(this._session);

  final TherapySessionController _session;

  final ValueNotifier<FlowEngineState> state =
      ValueNotifier<FlowEngineState>(FlowEngineState.idle);
  final ValueNotifier<int> currentStepIndex = ValueNotifier<int>(0);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  FlowDefinition? _flow;
  double _tinnitusFrequencyHz = 4000.0;
  double _baseAmp = 0.15;
  double _anapsMaxIntensity = 0.20;
  double _anapsFreqOffset = 0.0;
  bool _stopRequested = false;
  bool _advancing = false;

  late final FlowTimer _timer = FlowTimer(onTick: () {});

  ValueNotifier<int> get globalRemainingSeconds =>
      _timer.globalRemainingSeconds;

  ValueNotifier<int> get stepRemainingSeconds => _timer.stepRemainingSeconds;

  FlowDefinition? get activeFlow => _flow;

  FlowStep? get currentStep {
    final FlowDefinition? flow = _flow;
    if (flow == null) return null;
    final int idx = currentStepIndex.value;
    if (idx < 0 || idx >= flow.steps.length) return null;
    return flow.steps[idx];
  }

  void dispose() {
    _timer.dispose();
    state.dispose();
    currentStepIndex.dispose();
    errorMessage.dispose();
  }

  Future<void> startFlow({
    required FlowDefinition flow,
    required double tinnitusFrequencyHz,
    required double baseAmp,
  }) async {
    if (_session.isRunning.value) return;

    _flow = flow;
    _tinnitusFrequencyHz = tinnitusFrequencyHz;
    _baseAmp = baseAmp;
    _anapsMaxIntensity = await AnapsStorage.loadMaxIntensity();
    _anapsFreqOffset = await AnapsStorage.loadFrequencyOffset();
    _stopRequested = false;
    _advancing = false;
    errorMessage.value = null;
    currentStepIndex.value = 0;
    state.value = FlowEngineState.runningStep;

    final DateTime now = DateTime.now();
    final DateTime globalEnds =
        now.add(Duration(seconds: flow.totalDurationSeconds));
    final FlowStep step = flow.steps.first;
    final DateTime stepEnds =
        now.add(Duration(seconds: step.durationSeconds));

    _session.flowOrchestrated = true;
    _session.onFlowStepElapsed = _handleStepElapsed;
    _timer.start(globalEndsAt: globalEnds, stepEndsAt: stepEnds);

    final bool started = await _launchStep(step, isFirstStep: true);
    if (!started) {
      await _failFlow('Module failed to start');
    }
  }

  Future<bool> _launchStep(FlowStep step, {required bool isFirstStep}) async {
    final Phase3ModuleParams params = step.resolvedParams();
    final double baseFreq = params.engineBaseFreq(_tinnitusFrequencyHz + _anapsFreqOffset);
    final bool rmp = step.module == Phase3ModuleType.rmp;
    final bool pip = step.module == Phase3ModuleType.pip;
    final bool binaural = step.module == Phase3ModuleType.binaural;

    if (isFirstStep) {
      _session.startSession(
        subthreshold: false,
        rmp: rmp,
        pip: pip,
        sidebands: false,
        binaural: binaural,
        baseFreq: baseFreq,
        baseAmp: _baseAmp,
        maxIntensity: _anapsMaxIntensity,
        durationMinutes: step.durationMinutes,
        targetRmpDepth: params.engineRmpDepth(),
        targetRmpRate: params.rmpChangeRateHz,
        targetPipInterval: params.enginePipPauseSec(),
        targetPipDuration: params.enginePipPulseSec(),
        targetBinauralOffset: params.engineBinauralOffset(),
      );
      return _session.isRunning.value;
    }

    final bool ok = await FlowTransitions.crossfadeToStep(
      session: _session,
      step: step,
      tinnitusFrequencyHz: _tinnitusFrequencyHz,
      baseAmp: _baseAmp,
    );
    if (!ok) return false;

    _session.beginOrchestratedStep(
      subthreshold: false,
      rmp: rmp,
      pip: pip,
      sidebands: false,
      binaural: binaural,
      baseFreq: baseFreq,
      baseAmp: _baseAmp,
      maxIntensity: _anapsMaxIntensity,
      durationMinutes: step.durationMinutes,
      targetRmpDepth: params.engineRmpDepth(),
      targetRmpRate: params.rmpChangeRateHz,
      targetPipInterval: params.enginePipPauseSec(),
      targetPipDuration: params.enginePipPulseSec(),
      targetSidebandOffset: 100.0,
      targetSidebandIntensity: 0.0,
      targetBinauralOffset: params.engineBinauralOffset(),
    );
    return _session.isRunning.value;
  }

  Future<void> _handleStepElapsed() async {
    if (_stopRequested || _advancing) return;
    final FlowDefinition? flow = _flow;
    if (flow == null) return;

    _advancing = true;

    final int idx = currentStepIndex.value;
    final bool isLast = idx >= flow.steps.length - 1;

    if (isLast) {
      state.value = FlowEngineState.transitioning;
      _timer.stop();
      await _session.completeFlowAndStop();
      state.value = FlowEngineState.feedback;
      currentStepIndex.value = 0;
      _advancing = false;
      return;
    }

    state.value = FlowEngineState.transitioning;

    final FlowStep next = flow.steps[idx + 1];
    final bool ok = await FlowTransitions.crossfadeToStep(
      session: _session,
      step: next,
      tinnitusFrequencyHz: _tinnitusFrequencyHz,
      baseAmp: _baseAmp,
    );

    if (!ok || _stopRequested) {
      _advancing = false;
      if (!_stopRequested) await _failFlow('Transition failed');
      return;
    }

    currentStepIndex.value = idx + 1;

    final Phase3ModuleParams params = next.resolvedParams();
    final double baseFreq = params.engineBaseFreq(_tinnitusFrequencyHz + _anapsFreqOffset);

    _session.beginOrchestratedStep(
      subthreshold: false,
      rmp: next.module == Phase3ModuleType.rmp,
      pip: next.module == Phase3ModuleType.pip,
      sidebands: false,
      binaural: next.module == Phase3ModuleType.binaural,
      baseFreq: baseFreq,
      baseAmp: _baseAmp,
      maxIntensity: _anapsMaxIntensity,
      durationMinutes: next.durationMinutes,
      targetRmpDepth: params.engineRmpDepth(),
      targetRmpRate: params.rmpChangeRateHz,
      targetPipInterval: params.enginePipPauseSec(),
      targetPipDuration: params.enginePipPulseSec(),
      targetSidebandOffset: 100.0,
      targetSidebandIntensity: 0.0,
      targetBinauralOffset: params.engineBinauralOffset(),
    );

    _timer.setStepEndsAt(
      DateTime.now().add(Duration(seconds: next.durationSeconds)),
    );

    state.value = FlowEngineState.runningStep;
    _advancing = false;
  }

  Future<void> stopFlow() async {
    if (state.value == FlowEngineState.idle) return;
    _stopRequested = true;
    state.value = FlowEngineState.stopping;
    _session.clearFlowOrchestration();
    _timer.stop();
    if (_session.isRunning.value) {
      _session.stopSession();
    }
    state.value = FlowEngineState.feedback;
    currentStepIndex.value = 0;
  }

  Future<void> _failFlow(String message) async {
    errorMessage.value = message;
    if (state.value == FlowEngineState.idle) return;
    _stopRequested = true;
    state.value = FlowEngineState.stopping;
    _session.clearFlowOrchestration();
    _timer.stop();
    if (_session.isRunning.value) {
      _session.stopSession();
    }
    _flow = null;
    state.value = FlowEngineState.idle;
    currentStepIndex.value = 0;
  }

  void resetToIdle() {
    _stopRequested = false;
    _advancing = false;
    _flow = null;
    errorMessage.value = null;
    currentStepIndex.value = 0;
    state.value = FlowEngineState.idle;
    _session.clearFlowOrchestration();
    _session.resetCompletion();
  }

  void skipFeedback() {
    resetToIdle();
  }

  Future<void> submitFeedback(
    IntensityPerception perception,
    ComfortLevel comfort,
    Effectiveness effectiveness,
  ) async {
    state.value = FlowEngineState.adapt;

    // Intensity Adjustment Rules
    double nextIntensity = _anapsMaxIntensity;
    
    // Rule Set 1 - Intensity Perception
    if (perception == IntensityPerception.tooLow) {
      nextIntensity += 0.05;
    } else if (perception == IntensityPerception.tooHigh) {
      nextIntensity -= 0.05;
    }
    nextIntensity = nextIntensity.clamp(0.20, 0.50);

    // Rule Set 2 - Comfort Level
    if (comfort == ComfortLevel.uncomfortable) {
      nextIntensity -= 0.05;
    } else if (comfort == ComfortLevel.comfortable) {
      nextIntensity += 0.05;
    }
    nextIntensity = nextIntensity.clamp(0.20, 0.50);

    // Frequency Offset Adjustment Rules
    double nextFreqOffset = _anapsFreqOffset;

    // Rule Set - Effectiveness
    if (effectiveness == Effectiveness.low) {
      nextFreqOffset += 10.0;
    } else if (effectiveness == Effectiveness.high) {
      nextFreqOffset -= 10.0;
    }
    nextFreqOffset = nextFreqOffset.clamp(-50.0, 50.0);

    _anapsMaxIntensity = nextIntensity;
    _anapsFreqOffset = nextFreqOffset;

    await AnapsStorage.saveParams(_anapsMaxIntensity, _anapsFreqOffset);

    resetToIdle();
  }
}
