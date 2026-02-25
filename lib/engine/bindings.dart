import 'dart:ffi';
import 'ffi_types.dart';

/// FFI bindings for the native audio engine.
///
/// Used only by [AudioEngine]. Not part of the public API; UI and
/// other modules must interact with the engine via [AudioEngine].
typedef _CreateC = NativeAudioHandle Function();
typedef _CreateDart = NativeAudioHandle Function();

typedef _StartC = Int32 Function(NativeAudioHandle);
typedef _StartDart = int Function(NativeAudioHandle);

typedef _IsRunningC = Int32 Function(NativeAudioHandle);
typedef _IsRunningDart = int Function(NativeAudioHandle);

typedef _VoidNativeAudioHandleFuncC = Void Function(NativeAudioHandle);
typedef _VoidNativeAudioHandleFuncDart = void Function(NativeAudioHandle);

typedef _SetFloatC = Void Function(NativeAudioHandle, Float);
typedef _SetFloatDart = void Function(NativeAudioHandle, double);

typedef _SetDoubleC = Void Function(NativeAudioHandle, Double);
typedef _SetDoubleDart = void Function(NativeAudioHandle, double);

class NativeBindings {
  late final _CreateDart _create;
  late final _StartDart _start;
  late final _IsRunningDart _isRunning;
  late final _VoidNativeAudioHandleFuncDart _stop;
  late final _VoidNativeAudioHandleFuncDart _destroy;
  late final _SetFloatDart _setFrequency;
  late final _SetDoubleDart _setTargetFrequency;
  late final _SetFloatDart _setAmplitude;
  late final _VoidNativeAudioHandleFuncDart _scheduleSequence;
  late final _VoidNativeAudioHandleFuncDart _startSession;
  late final _VoidNativeAudioHandleFuncDart _stopSession;

  NativeBindings(DynamicLibrary lib) {
    _create = lib.lookupFunction<_CreateC, _CreateDart>('audio_create');
    _start = lib.lookupFunction<_StartC, _StartDart>('audio_start');
    _isRunning = lib.lookupFunction<_IsRunningC, _IsRunningDart>(
      'audio_is_running',
    );
    _stop = lib
        .lookupFunction<
          _VoidNativeAudioHandleFuncC,
          _VoidNativeAudioHandleFuncDart
        >('audio_stop');
    _destroy = lib
        .lookupFunction<
          _VoidNativeAudioHandleFuncC,
          _VoidNativeAudioHandleFuncDart
        >('audio_destroy');
    _setFrequency = lib.lookupFunction<_SetFloatC, _SetFloatDart>(
      'audio_set_frequency',
    );
    _setTargetFrequency = lib.lookupFunction<_SetDoubleC, _SetDoubleDart>(
      'audio_set_target_frequency',
    );
    _setAmplitude = lib.lookupFunction<_SetFloatC, _SetFloatDart>(
      'audio_set_amplitude',
    );
    _scheduleSequence = lib
        .lookupFunction<
          _VoidNativeAudioHandleFuncC,
          _VoidNativeAudioHandleFuncDart
        >('audio_schedule_sequence');
    _startSession = lib
        .lookupFunction<
          _VoidNativeAudioHandleFuncC,
          _VoidNativeAudioHandleFuncDart
        >('audio_start_session');
    _stopSession = lib
        .lookupFunction<
          _VoidNativeAudioHandleFuncC,
          _VoidNativeAudioHandleFuncDart
        >('audio_stop_session');
  }

  NativeAudioHandle create() => _create();
  int start(NativeAudioHandle handle) => _start(handle);
  int isRunning(NativeAudioHandle handle) => _isRunning(handle);
  void stop(NativeAudioHandle handle) => _stop(handle);
  void destroy(NativeAudioHandle handle) => _destroy(handle);
  void setFrequency(NativeAudioHandle handle, double hz) =>
      _setFrequency(handle, hz);
  void setTargetFrequency(NativeAudioHandle handle, double hz) =>
      _setTargetFrequency(handle, hz);
  void setAmplitude(NativeAudioHandle handle, double amplitude) =>
      _setAmplitude(handle, amplitude);
  void scheduleSequence(NativeAudioHandle handle) => _scheduleSequence(handle);
  void startSession(NativeAudioHandle handle) => _startSession(handle);
  void stopSession(NativeAudioHandle handle) => _stopSession(handle);
}
