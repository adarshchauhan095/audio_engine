import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/audio_engine.dart';
import '../engine/bindings.dart';
import '../models/session_params.dart';
import '../storage/detected_frequency_storage.dart';
import '../storage/therapy_adherence_storage.dart';
import '../storage/tinnitx_user_profile_storage.dart';
import 'profile_session_catalog.dart';
import 'session_controller.dart';
import 'therapy_session_controller.dart';

void _logNativeMessage(Pointer<Utf8> msg) {
  final str = msg.toDartString();
  debugPrint('NativeEngine: $str');
}

class SessionRunSnapshot {
  const SessionRunSnapshot({
    required this.sessionId,
    required this.profileId,
    required this.profileName,
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
  final String profileId;
  final String profileName;
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
  TherapySessionController? _therapySessionController;
  NativeCallable<LogCallbackC>? _logCallable;
  NativeCallable<OutputLostCallbackC>? _outputLostCallable;
  MethodChannel? _routeChannel;
  Timer? _routeRecoveryTimer;
  bool _routeRecoveryAttached = false;

  static const String _routeChannelName = 'com.audio.audio_engine/audio_route';

  final ValueNotifier<bool> stereoEnabled = ValueNotifier<bool>(true);

  final ValueNotifier<bool> playing = ValueNotifier<bool>(false);
  final ValueNotifier<double> frequency = ValueNotifier<double>(440.0);
  final ValueNotifier<double> amplitude = ValueNotifier<double>(0.3);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  final ValueNotifier<bool> debugActionRunning = ValueNotifier<bool>(false);
  final ValueNotifier<double> debugProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> profileSessionRunning = ValueNotifier<bool>(false);
  final ValueNotifier<SessionRunSnapshot?> activeSession =
      ValueNotifier<SessionRunSnapshot?>(null);

  static const double freqMin = kMinFrequencyHz;
  static const double freqMax = kMaxFrequencyHz;

  /// Baseline tone for modules that use the raw oscillator (detection, audio
  /// controls, debug, etc.). Matches initial engine defaults.
  static const double moduleDefaultFrequencyHz = 440.0;
  static const double moduleDefaultAmplitude = 0.3;

  static const Duration _sessionTickInterval = Duration(milliseconds: 200);
  static const Duration _routeRecoveryDebounce = Duration(milliseconds: 400);

  AudioEngine? get engine => _engine;
  TherapySessionController? get therapySession => _therapySessionController;
  bool get hasEngine => _engine != null;
  bool get hasActiveSession => activeSession.value != null;

  Timer? _sessionTicker;
  bool _sessionCancelRequested = false;
  bool _disposed = false;
  Future<void> _engineSerial = Future<void>.value();

  Timer? _therapyAdherenceDebounceTimer;
  bool _isRestoringTherapyAdherence = false;

  void _scheduleTherapyAdherenceSave() {
    if (_isRestoringTherapyAdherence) return;
    _therapyAdherenceDebounceTimer?.cancel();
    _therapyAdherenceDebounceTimer = Timer(const Duration(seconds: 2), () {
      final int seconds =
          _therapySessionController?.totalTherapySeconds.value ?? 0;
      TherapyAdherenceStorage.saveTotalTherapySeconds(seconds);
    });
  }

  void _restoreTherapyAdherence() {
    _isRestoringTherapyAdherence = true;
    () async {
      final int saved = await TherapyAdherenceStorage.loadTotalTherapySeconds();
      _therapySessionController?.totalTherapySeconds.value = saved;
      _isRestoringTherapyAdherence = false;
    }();
  }

  /// Wires platform route notifications (preferred output added/removed, e.g.
  /// Bluetooth or wired). Call once from the root widget after
  /// [WidgetsFlutterBinding.ensureInitialized].
  void attachRouteRecoveryChannel(BinaryMessenger messenger) {
    if (!Platform.isAndroid || _disposed || _routeRecoveryAttached) return;
    _routeRecoveryAttached = true;
    _routeChannel = MethodChannel(
      _routeChannelName,
      const StandardMethodCodec(),
      messenger,
    );
    _routeChannel!.setMethodCallHandler(_onRoutePlatformCall);
    unawaited(_primePreferredOutputDeviceFromPlatform());
  }

  /// Sets native preferred Oboe device from the platform list (e.g. BT already
  /// connected at cold start) without reopening the stream.
  Future<void> _primePreferredOutputDeviceFromPlatform() async {
    if (_disposed || _engine == null || _routeChannel == null) return;
    try {
      final Object? raw = await _routeChannel!.invokeMethod<Object?>(
        'getPreferredMusicOutputDeviceId',
      );
      int deviceId = -1;
      if (raw is int) {
        deviceId = raw;
      } else if (raw is num) {
        deviceId = raw.toInt();
      }
      if (deviceId >= 0) {
        _engine!.setPreferredOutputDeviceId(deviceId);
      }
    } catch (e) {
      debugPrint('Audio route: prime preferred device failed: $e');
    }
  }

  Future<void> _onRoutePlatformCall(MethodCall call) async {
    if (call.method == 'onPreferredAudioOutputChanged' ||
        call.method == 'onBluetoothAudioRouteLost') {
      _scheduleAudioRouteRecovery();
    }
  }

  void _onNativeOutputLost() {
    _scheduleAudioRouteRecovery();
  }

  void _scheduleAudioRouteRecovery() {
    if (_disposed || _engine == null) return;
    _routeRecoveryTimer?.cancel();
    _routeRecoveryTimer = Timer(_routeRecoveryDebounce, () {
      _routeRecoveryTimer = null;
      unawaited(_recoverAudioOutputAfterRouteLoss());
    });
  }

  Future<void> _recoverAudioOutputAfterRouteLoss() async {
    if (_disposed || _engine == null) return;

    final bool therapyRunning =
        _therapySessionController?.isRunning.value ?? false;
    final bool wantsSound = playing.value ||
        therapyRunning ||
        profileSessionRunning.value ||
        debugActionRunning.value ||
        _engine!.isRunning;

    await resetEngine(resumeIfNeeded: wantsSound, restoreTherapyState: therapyRunning);
  }

  void _initEngine() {
    if (!Platform.isAndroid) {
      error.value = 'Native audio only on Android';
      return;
    }

    try {
      final DynamicLibrary lib = DynamicLibrary.open('libnative_audio.so');
      final NativeBindings bindings = NativeBindings(lib);
      _engine = AudioEngine(bindings)..init();
      _engine!.setFrequency(moduleDefaultFrequencyHz);
      _engine!.setAmplitude(moduleDefaultAmplitude);
      frequency.value = moduleDefaultFrequencyHz;
      amplitude.value = moduleDefaultAmplitude;
      _engine!.setStereoEnabled(stereoEnabled.value); // Initialize stereo state
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
        onProgress: (double p) {
          debugProgress.value = p;
        },
      );
      
      _therapySessionController = TherapySessionController(_engine!);
      _therapySessionController!.totalTherapySeconds
          .addListener(_scheduleTherapyAdherenceSave);
      _restoreTherapyAdherence();

      // Create or migrate a schema-aligned user profile from legacy values.
      // This keeps terminology consistent as the project evolves.
      unawaited(
        TinnitXUserProfileStorage.migrateLegacyIfNeeded(userId: 'local_user'),
      );

      _logCallable = NativeCallable<LogCallbackC>.listener(_logNativeMessage);
      _engine!.registerLogCallback(_logCallable!.nativeFunction);

      _outputLostCallable =
          NativeCallable<OutputLostCallbackC>.listener(_onNativeOutputLost);
      _engine!.registerOutputLostCallback(_outputLostCallable!.nativeFunction);
    } catch (e) {
      error.value = 'Engine init failed: $e';
    }
  }

  void _setEnginePlaying(bool isPlaying) {
    if (_engine == null) return;
    // Keep the existing API synchronous for callers, but apply a short fade
    // around transport transitions to reduce squeaks/clicks.
    unawaited(_setEnginePlayingSmooth(isPlaying));
  }

  static const Duration _transportFade = Duration(milliseconds: 40);

  Future<void> _setEnginePlayingSmooth(bool isPlaying) async {
    if (_engine == null || _disposed) return;
    final AudioEngine engine = _engine!;
    final double targetAmp = amplitude.value.clamp(0.0, 1.0);

    if (isPlaying) {
      // Fade in: start transport at 0 then ramp to target amplitude.
      engine.setAmplitude(0.0);
      final bool ok = engine.start();
      playing.value = ok;
      if (!ok) return;
      await _rampEngineAmplitude(engine, from: 0.0, to: targetAmp, duration: _transportFade);
      // Ensure the engine target amplitude matches user setting.
      engine.setAmplitude(targetAmp);
      return;
    }

    // Fade out: ramp to 0 then stop transport; preserve the user's amplitude.
    await _rampEngineAmplitude(engine, from: targetAmp, to: 0.0, duration: _transportFade);
    engine.setAmplitude(targetAmp);
    engine.stop();
    playing.value = false;
  }

  Future<void> _rampEngineAmplitude(
    AudioEngine engine, {
    required double from,
    required double to,
    required Duration duration,
  }) async {
    const int steps = 6;
    final int stepMs = (duration.inMilliseconds / steps).clamp(1, 1000).toInt();
    for (int i = 0; i <= steps; i++) {
      if (_disposed) return;
      final double t = i / steps;
      final double v = from + (to - from) * t;
      engine.setAmplitude(v.clamp(0.0, 1.0));
      if (i < steps) {
        await Future<void>.delayed(Duration(milliseconds: stepMs));
      }
    }
  }

  void togglePlay() {
    if (_engine == null) return;
    if (playing.value) {
      _setEnginePlaying(false);
    } else {
    // Start engine playback
    _setEnginePlaying(true);
  }
  }

  void setStereoEnabled(bool enabled) {
    stereoEnabled.value = enabled;
    _engine?.setStereoEnabled(enabled);
  }

  void stopPlayback() {
    if (_engine == null || !playing.value) return;
    _setEnginePlaying(false);
  }

  /// Deterministic engine reset:
  /// - stops transport
  /// - closes the output stream (forces next [start] to open on current route)
  /// - optionally resumes playback if it was desired
  ///
  /// This is safe to call on Bluetooth connect/disconnect or module boundaries.
  Future<void> resetEngine({
    bool resumeIfNeeded = true,
    bool restoreTherapyState = false,
  }) {
    return _enqueueEngineOp(() async {
      if (_disposed || _engine == null) return;

      // Snapshot desired state.
      final bool wantsSound = resumeIfNeeded;
      final double f = frequency.value.clamp(freqMin, freqMax);
      final double a = amplitude.value.clamp(0.0, 1.0);
      final bool stereo = stereoEnabled.value;

      try {
        if (Platform.isAndroid) {
          final AudioSession session = await AudioSession.instance;
          await session.setActive(false);
          await session.setActive(true);
        }
      } catch (e, st) {
        debugPrint('Engine reset: session re-activate failed: $e $st');
      }

      int deviceId = -1;
      if (_routeChannel != null) {
        try {
          final Object? raw = await _routeChannel!.invokeMethod<Object?>(
            'getPreferredMusicOutputDeviceId',
          );
          if (raw is int) {
            deviceId = raw;
          } else if (raw is num) {
            deviceId = raw.toInt();
          }
        } catch (e) {
          debugPrint('Engine reset: preferred device id query failed: $e');
        }
      }

      // Stop + close stream (route-safe).
      if (_engine!.isRunning) {
        _engine!.stop();
      }
      _engine!.resetOutputStream();

      // Re-apply parameters for deterministic restart.
      _engine!.setStereoEnabled(stereo);
      _engine!.setAmplitude(a);
      _engine!.setFrequency(f);
      frequency.value = f;
      amplitude.value = a;

      if (!wantsSound) {
        if (playing.value) playing.value = false;
        return;
      }

      if (deviceId >= 0) {
        _engine!.setPreferredOutputDeviceId(deviceId);
      }

      final bool ok = _engine!.start();
      playing.value = ok;

      if (ok && restoreTherapyState) {
        _therapySessionController?.applyEngineOutputRecovery();
      }
    });
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

  /// Stops cross-module leakage: profile timers, adaptive therapy, native
  /// therapy DSP, and simple-tone playback. Does not change stereo preference
  /// or adherence totals.
  void _prepareModuleBoundary() {
    if (_engine == null || _disposed) return;
    // If a route recovery is pending, cancel it: module boundaries should win.
    _routeRecoveryTimer?.cancel();
    _routeRecoveryTimer = null;

    endRunningSession();
    if (_therapySessionController?.isRunning.value ?? false) {
      _therapySessionController!.stopSession();
    } else {
      _engine!.therapyStop();
    }
    if (playing.value) {
      _engine!.stop();
      playing.value = false;
    }
    // Ensure the next module opens a fresh stream on the current route.
    // This prevents cross-module state leakage and makes re-entry deterministic.
    _engine!.resetOutputStream();
  }

  /// Opening **Tinnitus Detection**: clean oscillator workspace.
  void prepareForTinnitusDetection() {
    _prepareModuleBoundary();
    setFrequency(moduleDefaultFrequencyHz);
    setAmplitude(moduleDefaultAmplitude);
  }

  /// Opening **Automated Matching System (AMS)**: isolated oscillator for guided
  /// frequency matching (coarse → fine → validation). Same boundary as other modules.
  void prepareForAmsMatching() {
    _prepareModuleBoundary();
    setFrequency(moduleDefaultFrequencyHz);
    setAmplitude(moduleDefaultAmplitude);
  }

  /// Opening **Adaptive Therapy**: clear prior module state; idle tone matches
  /// the first preset’s base parameters.
  void prepareForAdaptiveTherapy() {
    _prepareModuleBoundary();
    final TherapyProfilePreset p = TherapyProfilePreset.presets.first;
    setFrequency(p.baseFreq ?? 4000.0);
    setAmplitude(p.baseAmp ?? 0.15);
  }

  /// Opening **Audio Controls**.
  void prepareForLiveToneControls() {
    _prepareModuleBoundary();
    setFrequency(moduleDefaultFrequencyHz);
    setAmplitude(moduleDefaultAmplitude);
  }

  /// Opening **Module Demo** or **Debug Tests**.
  void prepareForEngineExperiments() {
    _prepareModuleBoundary();
    setFrequency(moduleDefaultFrequencyHz);
    setAmplitude(moduleDefaultAmplitude);
  }

  /// Opening **Profile Sessions** (runs still apply their own [SessionParams]).
  void prepareForProfileSessionsWorkspace() {
    _prepareModuleBoundary();
    setFrequency(moduleDefaultFrequencyHz);
    setAmplitude(moduleDefaultAmplitude);
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
    if (!profileSessionRunning.value) return;
    _sessionCancelRequested = true;
    _stopSessionTicker();
    activeSession.value = null;
    if (_engine != null && playing.value) {
      _engine!.stop();
      playing.value = false;
    }
  }

  Future<bool> runProfileSession(
    SessionParams params, {
    bool stopWhenDone = true,
  }) async {
    if (_engine == null || _disposed) return false;
    if (debugActionRunning.value || profileSessionRunning.value) return false;

    profileSessionRunning.value = true;
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
      profileSessionRunning.value = false;
    }
  }

  Future<bool> runProfileSessionBatch(List<SessionParams> sessions) async {
    if (_engine == null || _disposed) return false;
    if (sessions.isEmpty) return false;
    if (debugActionRunning.value || profileSessionRunning.value) return false;

    profileSessionRunning.value = true;
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
      profileSessionRunning.value = false;
    }
  }

  Future<void> runExclusiveDebugAction(Future<void> Function() action) async {
    if (debugActionRunning.value || profileSessionRunning.value) return;
    debugActionRunning.value = true;
    debugProgress.value = 0.0;
    try {
      await action();
    } finally {
      debugActionRunning.value = false;
      debugProgress.value = 0.0;
      stopPlayback(); // Auto stop when debug test completes
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
    final DateTime start = DateTime.now();
    final DateTime end = start.add(duration);
    while (DateTime.now().isBefore(end)) {
      final now = DateTime.now();
      debugProgress.value = (now.difference(start).inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      
      final double f =
          freqMin + (freqMax - freqMin) * (now.millisecond % 1000 / 1000);
      final double a = (now.millisecond % 1000) / 1000.0;
      _engine!.setFrequency(f);
      _engine!.setAmplitude(a);
      frequency.value = f.clamp(freqMin, freqMax);
      amplitude.value = a.clamp(0.0, 1.0);
      await Future<void>.delayed(interval);
    }
    debugProgress.value = 1.0;
  }

  Future<void> runStartStop10() async {
    if (_engine == null) return;
    const int iterations = 10;
    for (int i = 0; i < iterations; i++) {
      debugProgress.value = i / iterations;
      _engine!.start();
      playing.value = true;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _engine!.stop();
      playing.value = false;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    debugProgress.value = 1.0;
  }

  void runExtremeValues() {
    if (_engine == null) return;
    _engine!.setFrequency(freqMin);
    _engine!.setFrequency(freqMax);
    _engine!.setAmplitude(0);
    _engine!.setAmplitude(1);
    frequency.value = freqMax;
    amplitude.value = 1;
    debugProgress.value = 1.0;
  }

  Future<void> runSequenceTest() async {
    if (_sessionController == null) return;
    await _sessionController!.runSequenceTest();
  }

  Future<void> runAdaptiveTest() async {
    if (_sessionController == null) return;
    await _sessionController!.runAdaptiveTest();
  }

  Future<void> runLongRunStabilityTest({int? durationSeconds}) async {
    if (_sessionController == null) return;
    await _sessionController!.runLongRunStabilityTest(durationSeconds: durationSeconds);
  }

  void dispose() {
    _disposed = true;
    _routeRecoveryTimer?.cancel();
    _routeChannel?.setMethodCallHandler(null);
    _routeChannel = null;
    _logCallable?.close();
    _outputLostCallable?.close();
    _therapyAdherenceDebounceTimer?.cancel();
    _therapySessionController
        ?.totalTherapySeconds
        .removeListener(_scheduleTherapyAdherenceSave);
    endRunningSession();
    _stopSessionTicker();
    _sessionController?.dispose();
    _therapySessionController?.dispose();
    _engine?.dispose();
    _engine = null;

    playing.dispose();
    frequency.dispose();
    amplitude.dispose();
    error.dispose();
    debugActionRunning.dispose();
    debugProgress.dispose();
    profileSessionRunning.dispose();
    activeSession.dispose();
  }

  Future<void> _enqueueEngineOp(Future<void> Function() op) {
    // Serialize potentially conflicting engine operations:
    // route recovery, module boundaries, and explicit resets.
    _engineSerial = _engineSerial.then((_) => op()).catchError((_) {});
    return _engineSerial;
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
      profileId: session.profileId,
      profileName: session.profileName,
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
