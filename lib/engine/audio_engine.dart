import 'bindings.dart';
import 'ffi_types.dart';

/// Unified API surface for the audio engine.
///
/// Provides a single entry point for amplitude ([setAmplitude]), frequency
/// ([setFrequency]), start/stop ([start], [stop]), and engine state ([isRunning]).
/// All UI and future modules (e.g. tinnitus detection) must use this API.
/// DSP and parameter logic run in native code; this class delegates via
/// [NativeBindings].
class AudioEngine {
  final NativeBindings _bindings;
  NativeAudioHandle? _handle;

  AudioEngine(this._bindings);

  /// Initializes the native engine instance. Call once before [start] or setters.
  void init() {
    _handle = _bindings.create();
  }

  /// Starts playback with a smooth fade-in. Returns true if start succeeded.
  bool start() => _bindings.start(_handle!) == 0;

  /// Stops playback with a smooth fade-out; stream remains open to avoid pops.
  void stop() => _bindings.stop(_handle!);

  /// Whether the engine is currently running (transport active).
  bool get isRunning => _handle != null && _bindings.isRunning(_handle!) != 0;

  /// Sets the oscillator frequency in Hz. Changes are applied with smoothing.
  void setFrequency(double hz) => _bindings.setFrequency(_handle!, hz);

  /// Sets the amplitude in [0, 1]. Changes are ramp-smoothed to avoid clicks.
  void setAmplitude(double amp) => _bindings.setAmplitude(_handle!, amp);

  /// Releases the native engine. Do not call other methods after this.
  void dispose() {
    _bindings.destroy(_handle!);
    _handle = null;
  }
}
