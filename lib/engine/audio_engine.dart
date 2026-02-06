import 'bindings.dart';
import 'ffi_types.dart';

class AudioEngine {
  final NativeBindings _bindings;
  NativeAudioHandle? _handle;

  AudioEngine(this._bindings);

  void init() {
    _handle = _bindings.create();
  }

  void start() => _bindings.start(_handle!) == 0;
  void stop() => _bindings.stop(_handle!);

  void setFrequency(double hz) => _bindings.setFrequency(_handle!, hz);

  void setAmplitude(double amp) => _bindings.setAmplitude(_handle!, amp);

  void dispose() {
    _bindings.destroy(_handle!);
    _handle = null;
  }
}
