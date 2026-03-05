import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../engine/audio_engine.dart';
import '../engine/bindings.dart';
import '../models/session_params.dart';
import 'session_controller.dart';

class SessionRunSnapshot {
  const SessionRunSnapshot({
    required this.sessionId,
    required this.patientId,
    required this.patientName,
    required this.title,
    required this.frequencyHz,
    required this.amplitude,
    required this.durationSeconds,
    required this.elapsedSeconds,
    required this.remainingSeconds,
    required this.progress,
    required this.startedAtIso,
    required this.endsAtIso,
    this.batchIndex,
    this.batchTotal,
  });

  final String sessionId;
  final String patientId;
  final String patientName;
  final String title;
  final double frequencyHz;
  final double amplitude;
  final int durationSeconds;
  final int elapsedSeconds;
  final int remainingSeconds;
  final double progress;
  final String startedAtIso;
  final String endsAtIso;
  final int? batchIndex;
  final int? batchTotal;
}

/// Shared runtime controller for all screens.
///
/// Keeps core engine logic in one place while exposing independent APIs
/// for each feature screen.
class AudioRuntimeController {
  AudioRuntimeController() {
    _initEngine();
  }

  AudioEngine? _engine;
  SessionController? _sessionController;

  final ValueNotifier<bool> playing = ValueNotifier<bool>(false);
  final ValueNotifier<double> frequency = ValueNotifier<double>(440.0);
  final ValueNotifier<double> amplitude = ValueNotifier<double>(0.3);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  final ValueNotifier<bool> debugActionRunning = ValueNotifier<bool>(false);
  final ValueNotifier<bool> patientSessionRunning = ValueNotifier<bool>(false);
  final ValueNotifier<SessionRunSnapshot?> activeSession =
      ValueNotifier<SessionRunSnapshot?>(null);

  static const double freqMin = 110.0;
  static const double freqMax = 880.0;
  static const Duration _sessionTickInterval = Duration(milliseconds: 200);

  AudioEngine? get engine => _engine;
  bool get hasEngine => _engine != null;
  bool get hasActiveSession => activeSession.value != null;

  Timer? _sessionTicker;
  bool _sessionCancelRequested = false;
  bool _disposed = false;

  void _initEngine() {
    if (!Platform.isAndroid) {
      error.value = 'Native audio only on Android';
      return;
    }

    try {
      final DynamicLibrary lib = DynamicLibrary.open('libnative_audio.so');
      final NativeBindings bindings = NativeBindings(lib);
      _engine = AudioEngine(bindings)..init();
      _engine!.setFrequency(frequency.value);
      _engine!.setAmplitude(amplitude.value);
      _sessionController = SessionController(
        engine: _engine!,
        onFrequencyChanged: (double frequencyHz) {
          frequency.value = frequencyHz.clamp(freqMin, freqMax);
        },
        onAmplitudeChanged: (double amp) {
          amplitude.value = amp.clamp(0.0, 1.0);
        },
        onPlayingChanged: (bool isPlaying) {
          playing.value = isPlaying;
        },
      );
    } catch (e) {
      error.value = 'Engine init failed: $e';
    }
  }

  void togglePlay() {
    if (_engine == null) return;
    if (playing.value) {
      _engine!.stop();
      playing.value = false;
    } else {
      _engine!.start();
      playing.value = true;
    }
  }

  void stopPlayback() {
    if (_engine == null || !playing.value) return;
    _engine!.stop();
    playing.value = false;
  }

  void setFrequency(double hz) {
    if (_engine == null) return;
    final double clamped = hz.clamp(freqMin, freqMax);
    _engine!.setFrequency(clamped);
    frequency.value = clamped;
  }

  void setAmplitude(double amp) {
    if (_engine == null) return;
    final double clamped = amp.clamp(0.0, 1.0);
    _engine!.setAmplitude(clamped);
    amplitude.value = clamped;
  }

  void applySessionParams(SessionParams params) {
    if (_engine == null) return;
    setFrequency(params.frequencyHz);
    setAmplitude(params.amplitude);
  }

  bool isSessionRunning(String sessionId) {
    return activeSession.value?.sessionId == sessionId;
  }

  void endRunningSession() {
    if (!patientSessionRunning.value) return;
    _sessionCancelRequested = true;
    _stopSessionTicker();
    activeSession.value = null;
    if (_engine != null && playing.value) {
      _engine!.stop();
      playing.value = false;
    }
  }

  Future<bool> runPatientSession(
    SessionParams params, {
    bool stopWhenDone = true,
  }) async {
    if (_engine == null || _disposed) return false;
    if (debugActionRunning.value || patientSessionRunning.value) return false;

    patientSessionRunning.value = true;
    _sessionCancelRequested = false;
    try {
      return _runSingleSessionInternal(
        params.normalized(),
        stopWhenDone: stopWhenDone,
      );
    } finally {
      _sessionCancelRequested = false;
      _stopSessionTicker();
      activeSession.value = null;
      patientSessionRunning.value = false;
    }
  }

  Future<bool> runPatientSessionBatch(List<SessionParams> sessions) async {
    if (_engine == null || _disposed) return false;
    if (sessions.isEmpty) return false;
    if (debugActionRunning.value || patientSessionRunning.value) return false;

    patientSessionRunning.value = true;
    _sessionCancelRequested = false;
    bool completedAll = true;
    try {
      for (int i = 0; i < sessions.length; i++) {
        if (_engine == null || _sessionCancelRequested || _disposed) {
          completedAll = false;
          break;
        }
        final bool completed = await _runSingleSessionInternal(
          sessions[i].normalized(),
          stopWhenDone: false,
          batchIndex: i + 1,
          batchTotal: sessions.length,
        );
        if (!completed) {
          completedAll = false;
          break;
        }
      }
      if (_engine != null && playing.value) {
        _engine!.stop();
        playing.value = false;
      }
      return completedAll;
    } finally {
      _sessionCancelRequested = false;
      _stopSessionTicker();
      activeSession.value = null;
      patientSessionRunning.value = false;
    }
  }

  Future<void> runExclusiveDebugAction(Future<void> Function() action) async {
    if (debugActionRunning.value || patientSessionRunning.value) return;
    debugActionRunning.value = true;
    try {
      await action();
    } finally {
      debugActionRunning.value = false;
    }
  }

  Future<void> runRapidParams() async {
    if (_engine == null) return;
    if (!playing.value) {
      _engine!.start();
      playing.value = true;
    }
    const Duration duration = Duration(milliseconds: 2000);
    const Duration interval = Duration(milliseconds: 50);
    final DateTime end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      final double f =
          110.0 + (8000 - 110) * (DateTime.now().millisecond % 1000 / 1000);
      final double a = (DateTime.now().millisecond % 1000) / 1000.0;
      _engine!.setFrequency(f);
      _engine!.setAmplitude(a);
      frequency.value = f.clamp(freqMin, freqMax);
      amplitude.value = a.clamp(0.0, 1.0);
      await Future<void>.delayed(interval);
    }
  }

  Future<void> runStartStop10() async {
    if (_engine == null) return;
    for (int i = 0; i < 10; i++) {
      _engine!.start();
      playing.value = true;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _engine!.stop();
      playing.value = false;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void runExtremeValues() {
    if (_engine == null) return;
    _engine!.setFrequency(110);
    _engine!.setFrequency(8000);
    _engine!.setAmplitude(0);
    _engine!.setAmplitude(1);
    frequency.value = freqMax;
    amplitude.value = 1;
  }

  Future<void> runSequenceTest() async {
    if (_sessionController == null) return;
    await _sessionController!.runSequenceTest();
  }

  Future<void> runAdaptiveTest() async {
    if (_sessionController == null) return;
    await _sessionController!.runAdaptiveTest();
  }

  Future<void> runLongRunStabilityTest() async {
    if (_sessionController == null) return;
    await _sessionController!.runLongRunStabilityTest();
  }

  void dispose() {
    _disposed = true;
    endRunningSession();
    _stopSessionTicker();
    _sessionController?.dispose();
    _engine?.dispose();
    _engine = null;

    playing.dispose();
    frequency.dispose();
    amplitude.dispose();
    error.dispose();
    debugActionRunning.dispose();
    patientSessionRunning.dispose();
    activeSession.dispose();
  }

  Future<bool> _runSingleSessionInternal(
    SessionParams params, {
    required bool stopWhenDone,
    int? batchIndex,
    int? batchTotal,
  }) async {
    if (_engine == null || _disposed) return false;

    final SessionParams session = params.normalized();
    applySessionParams(session);

    if (!playing.value) {
      _engine!.start();
      playing.value = true;
    }

    final int durationSeconds = session.durationSeconds < 1
        ? 1
        : session.durationSeconds;
    final DateTime startedAt = DateTime.now();
    final DateTime endsAt = startedAt.add(Duration(seconds: durationSeconds));
    _startSessionTicker(
      session: session,
      startedAt: startedAt,
      endsAt: endsAt,
      batchIndex: batchIndex,
      batchTotal: batchTotal,
    );

    while (!_sessionCancelRequested &&
        !_disposed &&
        DateTime.now().isBefore(endsAt)) {
      await Future<void>.delayed(_sessionTickInterval);
    }

    final bool completedNaturally = !_sessionCancelRequested && !_disposed;
    _stopSessionTicker();
    activeSession.value = null;

    if (stopWhenDone && _engine != null && playing.value) {
      _engine!.stop();
      playing.value = false;
    }

    return completedNaturally;
  }

  void _startSessionTicker({
    required SessionParams session,
    required DateTime startedAt,
    required DateTime endsAt,
    int? batchIndex,
    int? batchTotal,
  }) {
    _stopSessionTicker();
    _publishActiveSession(
      session: session,
      startedAt: startedAt,
      endsAt: endsAt,
      batchIndex: batchIndex,
      batchTotal: batchTotal,
    );
    _sessionTicker = Timer.periodic(_sessionTickInterval, (_) {
      if (_disposed || _sessionCancelRequested) return;
      _publishActiveSession(
        session: session,
        startedAt: startedAt,
        endsAt: endsAt,
        batchIndex: batchIndex,
        batchTotal: batchTotal,
      );
    });
  }

  void _publishActiveSession({
    required SessionParams session,
    required DateTime startedAt,
    required DateTime endsAt,
    int? batchIndex,
    int? batchTotal,
  }) {
    final DateTime now = DateTime.now();
    final int totalMs = endsAt.difference(startedAt).inMilliseconds;
    final int elapsedMs = _clampInt(
      now.difference(startedAt).inMilliseconds,
      0,
      totalMs,
    );
    final int remainingMs = _clampInt(totalMs - elapsedMs, 0, totalMs);
    final double progress = totalMs <= 0 ? 1.0 : elapsedMs / totalMs;

    activeSession.value = SessionRunSnapshot(
      sessionId: session.id,
      patientId: session.patientId,
      patientName: session.patientName,
      title: session.title,
      frequencyHz: frequency.value,
      amplitude: amplitude.value,
      durationSeconds: session.durationSeconds,
      elapsedSeconds: elapsedMs ~/ 1000,
      remainingSeconds: (remainingMs / 1000.0).ceil(),
      progress: progress.clamp(0.0, 1.0),
      startedAtIso: startedAt.toIso8601String(),
      endsAtIso: endsAt.toIso8601String(),
      batchIndex: batchIndex,
      batchTotal: batchTotal,
    );
  }

  void _stopSessionTicker() {
    _sessionTicker?.cancel();
    _sessionTicker = null;
  }

  static int _clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
