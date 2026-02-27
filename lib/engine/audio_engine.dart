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
  bool start() => _bindings.start(_handle!) == 0;

  /// Stops playback with a smooth fade-out; stream remains open to avoid pops.
  void stop() => _bindings.stop(_handle!);

  /// Whether the engine is currently running (transport active).
  @override
  bool get isRunning => _handle != null && _bindings.isRunning(_handle!) != 0;

  /// Sets the oscillator frequency in Hz. Changes are applied with smoothing.
  @override
  void setFrequency(double hz) => _bindings.setFrequency(_handle!, hz);

  /// Sets the oscillator target frequency in Hz using high-precision input.
  void setTargetFrequency(double hz) =>
      _bindings.setTargetFrequency(_handle!, hz);

  /// Sets the amplitude in [0, 1]. Changes are ramp-smoothed to avoid clicks.
  @override
  void setAmplitude(double amp) => _bindings.setAmplitude(_handle!, amp);

  /// Loads a sequence payload for future scheduler-driven playback.
  void scheduleSequence() => _bindings.scheduleSequence(_handle!);

  /// Starts a scheduler session context.
  void startSession() => _bindings.startSession(_handle!);

  /// Stops the scheduler session context.
  void stopSession() => _bindings.stopSession(_handle!);

  /// Releases the native engine. Do not call other methods after this.
  void dispose() {
    _bindings.destroy(_handle!);
    _handle = null;
  }
}
