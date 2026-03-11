import 'dart:ffi';
import 'package:ffi/ffi.dart';

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

typedef _TherapyFuncC = Int32 Function(NativeAudioHandle, Int32, Int32, Int32, Int32, Int32, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float);
typedef _TherapyFuncDart = int Function(NativeAudioHandle, int, int, int, int, int, double, double, double, double, double, double, double, double, double, double);

typedef _TherapyStopFuncC = Int32 Function(NativeAudioHandle);
typedef _TherapyStopFuncDart = int Function(NativeAudioHandle);

typedef LogCallbackC = Void Function(Pointer<Utf8>);
typedef _RegisterLogC = Void Function(NativeAudioHandle, Pointer<NativeFunction<LogCallbackC>>);
typedef _RegisterLogDart = void Function(NativeAudioHandle, Pointer<NativeFunction<LogCallbackC>>);

typedef _SetIntC = Void Function(NativeAudioHandle, Int32);
typedef _SetIntDart = void Function(NativeAudioHandle, int);

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
  late final _TherapyFuncDart _therapyStart;
  late final _TherapyFuncDart _therapyUpdate;
  late final _TherapyStopFuncDart _therapyStop;
  late final _RegisterLogDart _registerLogCallback;
  late final _SetIntDart _setStereoEnabled;

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
    _therapyStart = lib.lookupFunction<_TherapyFuncC, _TherapyFuncDart>('audio_therapy_start');
    _therapyUpdate = lib.lookupFunction<_TherapyFuncC, _TherapyFuncDart>('audio_therapy_update');
    _therapyStop = lib
        .lookupFunction<
          _TherapyStopFuncC,
          _TherapyStopFuncDart
        >('audio_therapy_stop');
    _registerLogCallback = lib.lookupFunction<_RegisterLogC, _RegisterLogDart>('audio_register_log_callback');
    _setStereoEnabled = lib.lookupFunction<_SetIntC, _SetIntDart>('audio_set_stereo_enabled');
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

  int therapyStart(
    NativeAudioHandle handle, 
    int sub, int rmp, int pip, int side, int bin, 
    double intensity, double freq, double amp,
    double rmpDepth, double rmpRate,
    double pipInterval, double pipDuration,
    double sidebandOffset, double sidebandIntensity,
    double binauralOffset
  ) =>
      _therapyStart(handle, sub, rmp, pip, side, bin, intensity, freq, amp, rmpDepth, rmpRate, pipInterval, pipDuration, sidebandOffset, sidebandIntensity, binauralOffset);
      
  int therapyUpdate(
    NativeAudioHandle handle, 
    int sub, int rmp, int pip, int side, int bin, 
    double intensity, double freq, double amp,
    double rmpDepth, double rmpRate,
    double pipInterval, double pipDuration,
    double sidebandOffset, double sidebandIntensity,
    double binauralOffset
  ) =>
      _therapyUpdate(handle, sub, rmp, pip, side, bin, intensity, freq, amp, rmpDepth, rmpRate, pipInterval, pipDuration, sidebandOffset, sidebandIntensity, binauralOffset);
      
  int therapyStop(NativeAudioHandle handle) => _therapyStop(handle);
  
  void setStereoEnabled(NativeAudioHandle handle, int enabled) => _setStereoEnabled(handle, enabled);
  
  void registerLogCallback(NativeAudioHandle handle, Pointer<NativeFunction<LogCallbackC>> cb) =>
      _registerLogCallback(handle, cb);
}
