import 'dart:ffi';

import 'audio_control.dart';
import 'bindings.dart';
import 'ffi_types.dart';

/// Unified API surface for the audio engine.
///
/// Provides a single entry point for amplitude ([setAmplitude]), frequency
/// ([setFrequency]), start/stop ([start], [stop]), and engine state ([isRunning]).
/// All UI and future modules (e.g. tinnitus detection) must use this API.
/// DSP and parameter logic run in native code; this class delegates via
/// [NativeBindings].
class AudioEngine implements AudioControl {
  final NativeBindings _bindings;
  NativeAudioHandle? _handle;

  AudioEngine(this._bindings);

  /// Initializes the native engine instance. Call once before [start] or setters.
  void init() {
    _handle = _bindings.create();
  }

  /// Starts playback with a smooth fade-in. Returns true if start succeeded.
  @override
  bool start() {
    if (_handle == null) return false;
    int result = _bindings.start(_handle!);
    if (result != 0) {
      print("engine start failed");
      return false;
    }
    return true;
  }

  /// Stops playback with a smooth fade-out; stream remains open to avoid pops.
  @override
  void stop() {
    if (_handle == null) return;
    _bindings.stop(_handle!);
  }

  /// Whether the engine is currently running (transport active).
  @override
  bool get isRunning => _handle != null && _bindings.isRunning(_handle!) != 0;

  /// Sets the oscillator frequency in Hz. Changes are applied with smoothing.
  @override
  void setFrequency(double hz) {
    if (_handle == null) return;
    _bindings.setFrequency(_handle!, hz);
  }

  /// Sets the oscillator target frequency in Hz using high-precision input.
  void setTargetFrequency(double hz) {
    if (_handle == null) return;
    _bindings.setTargetFrequency(_handle!, hz);
  }

  /// Sets the amplitude in [0, 1]. Changes are ramp-smoothed to avoid clicks.
  @override
  void setAmplitude(double amp) {
    if (_handle == null) return;
    _bindings.setAmplitude(_handle!, amp);
  }

  /// Loads a sequence payload for future scheduler-driven playback.
  void scheduleSequence() {
    if (_handle == null) return;
    _bindings.scheduleSequence(_handle!);
  }

  /// Starts a scheduler session context.
  void startSession() {
    if (_handle == null) return;
    _bindings.startSession(_handle!);
  }

  /// Stops the scheduler session context.
  void stopSession() {
    if (_handle == null) return;
    _bindings.stopSession(_handle!);
  }

  void therapyStart({
    bool subthreshold = false,
    bool rmp = false,
    bool pip = false,
    bool sidebands = false,
    bool binaural = false,
    double intensity = 0.5,
    double baseFreq = 6200.0,
    double baseAmp = 0.2,
    double rmpDepth = 0.1,
    double rmpRate = 5.0,
    double pipInterval = 0.2,
    double pipDuration = 0.02,
    double sidebandOffset = 100.0,
    double sidebandIntensity = 0.33,
    double binauralOffset = 5.0,
  }) {
    if (_handle == null) return;
    _bindings.therapyStart(
      _handle!,
      subthreshold ? 1 : 0,
      rmp ? 1 : 0,
      pip ? 1 : 0,
      sidebands ? 1 : 0,
      binaural ? 1 : 0,
      intensity,
      baseFreq,
      baseAmp,
      rmpDepth,
      rmpRate,
      pipInterval,
      pipDuration,
      sidebandOffset,
      sidebandIntensity,
      binauralOffset,
    );
  }

  void therapyUpdate({
    bool subthreshold = false,
    bool rmp = false,
    bool pip = false,
    bool sidebands = false,
    bool binaural = false,
    double intensity = 0.5,
    double baseFreq = 6200.0,
    double baseAmp = 0.2,
    double rmpDepth = 0.1,
    double rmpRate = 5.0,
    double pipInterval = 0.2,
    double pipDuration = 0.02,
    double sidebandOffset = 100.0,
    double sidebandIntensity = 0.33,
    double binauralOffset = 5.0,
  }) {
    if (_handle == null) return;
    _bindings.therapyUpdate(
      _handle!,
      subthreshold ? 1 : 0,
      rmp ? 1 : 0,
      pip ? 1 : 0,
      sidebands ? 1 : 0,
      binaural ? 1 : 0,
      intensity,
      baseFreq,
      baseAmp,
      rmpDepth,
      rmpRate,
      pipInterval,
      pipDuration,
      sidebandOffset,
      sidebandIntensity,
      binauralOffset,
    );
  }

  void therapyStop() {
    if (_handle == null) return;
    _bindings.therapyStop(_handle!);
  }

  void setStereoEnabled(bool enabled) {
    if (_handle == null) return;
    _bindings.setStereoEnabled(_handle!, enabled ? 1 : 0);
  }

  void registerLogCallback(Pointer<NativeFunction<LogCallbackC>> cb) {
    if (_handle == null) return;
    _bindings.registerLogCallback(_handle!, cb);
  }

  /// Releases the native engine. Do not call other methods after this.
  void dispose() {
    if (_handle != null) {
      _bindings.destroy(_handle!);
      _handle = null;
    }
  }
}
