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

typedef _Phase2FuncC = Int32 Function(
  NativeAudioHandle,
  Int32, // modulationType
  Int32, // filterType
  Float, // intensity
  Float, // baseFreq
  Float, // baseAmp
  Float, // depth
  Float, // rateHz
  Float, // bandwidthHz
  Float, // filterFreqHz
  Float, // q
  Float, // transitionMs
);
typedef _Phase2FuncDart = int Function(
  NativeAudioHandle,
  int,
  int,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
);

typedef _Phase2StopFuncC = Int32 Function(NativeAudioHandle);
typedef _Phase2StopFuncDart = int Function(NativeAudioHandle);

typedef LogCallbackC = Void Function(Pointer<Utf8>);
typedef _RegisterLogC = Void Function(NativeAudioHandle, Pointer<NativeFunction<LogCallbackC>>);
typedef _RegisterLogDart = void Function(NativeAudioHandle, Pointer<NativeFunction<LogCallbackC>>);

typedef OutputLostCallbackC = Void Function();
typedef _RegisterOutputLostC = Void Function(
  NativeAudioHandle,
  Pointer<NativeFunction<OutputLostCallbackC>>,
);
typedef _RegisterOutputLostDart = void Function(
  NativeAudioHandle,
  Pointer<NativeFunction<OutputLostCallbackC>>,
);

typedef _SetIntC = Void Function(NativeAudioHandle, Int32);
typedef _SetIntDart = void Function(NativeAudioHandle, int);

typedef _RunTestC = Int32 Function(NativeAudioHandle, Int32);
typedef _RunTestDart = int Function(NativeAudioHandle, int);

typedef _Phase52SetGeneratorParamsC = Void Function(NativeAudioHandle, Int32, Float, Float, Float, Float, Float);
typedef _Phase52SetGeneratorParamsDart = void Function(NativeAudioHandle, int, double, double, double, double, double);

typedef _Phase52GetDiagnosticsC = Void Function(NativeAudioHandle, Pointer<Float>, Pointer<Float>, Pointer<Int32>, Pointer<Int32>);
typedef _Phase52GetDiagnosticsDart = void Function(NativeAudioHandle, Pointer<Float>, Pointer<Float>, Pointer<Int32>, Pointer<Int32>);

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
  late final _Phase2FuncDart _phase2Start;
  late final _Phase2FuncDart _phase2Update;
  late final _Phase2StopFuncDart _phase2Stop;
  late final _RegisterLogDart _registerLogCallback;
  late final _RegisterOutputLostDart _registerOutputLostCallback;
  late final _VoidNativeAudioHandleFuncDart _resetOutputStream;
  late final _SetIntDart _setOutputDeviceId;
  late final _SetIntDart _setStereoEnabled;
  late final _RunTestDart _runTestPhase52;
  late final _Phase52SetGeneratorParamsDart _phase52SetGeneratorParams;
  late final _Phase52GetDiagnosticsDart _phase52GetDiagnostics;

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
    _phase2Start = lib.lookupFunction<_Phase2FuncC, _Phase2FuncDart>(
      'audio_phase2_start',
    );
    _phase2Update = lib.lookupFunction<_Phase2FuncC, _Phase2FuncDart>(
      'audio_phase2_update',
    );
    _phase2Stop = lib
        .lookupFunction<
          _Phase2StopFuncC,
          _Phase2StopFuncDart
        >('audio_phase2_stop');
    _registerLogCallback = lib.lookupFunction<_RegisterLogC, _RegisterLogDart>('audio_register_log_callback');
    _registerOutputLostCallback = lib.lookupFunction<_RegisterOutputLostC, _RegisterOutputLostDart>(
      'audio_register_output_lost_callback',
    );
    _resetOutputStream = lib
        .lookupFunction<
          _VoidNativeAudioHandleFuncC,
          _VoidNativeAudioHandleFuncDart
        >('audio_reset_output_stream');
    _setOutputDeviceId = lib.lookupFunction<_SetIntC, _SetIntDart>(
      'audio_set_output_device_id',
    );
    _setStereoEnabled = lib.lookupFunction<_SetIntC, _SetIntDart>('audio_set_stereo_enabled');
    _runTestPhase52 = lib.lookupFunction<_RunTestC, _RunTestDart>('audio_phase52_run_test');
    _phase52SetGeneratorParams = lib.lookupFunction<_Phase52SetGeneratorParamsC, _Phase52SetGeneratorParamsDart>('audio_phase52_set_generator_params');
    _phase52GetDiagnostics = lib.lookupFunction<_Phase52GetDiagnosticsC, _Phase52GetDiagnosticsDart>('audio_phase52_get_diagnostics');
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

  int phase2Start(
    NativeAudioHandle handle,
    int modulationType,
    int filterType,
    double intensity,
    double baseFreq,
    double baseAmp,
    double depth,
    double rateHz,
    double bandwidthHz,
    double filterFreqHz,
    double q,
    double transitionMs,
  ) =>
      _phase2Start(
        handle,
        modulationType,
        filterType,
        intensity,
        baseFreq,
        baseAmp,
        depth,
        rateHz,
        bandwidthHz,
        filterFreqHz,
        q,
        transitionMs,
      );

  int phase2Update(
    NativeAudioHandle handle,
    int modulationType,
    int filterType,
    double intensity,
    double baseFreq,
    double baseAmp,
    double depth,
    double rateHz,
    double bandwidthHz,
    double filterFreqHz,
    double q,
    double transitionMs,
  ) =>
      _phase2Update(
        handle,
        modulationType,
        filterType,
        intensity,
        baseFreq,
        baseAmp,
        depth,
        rateHz,
        bandwidthHz,
        filterFreqHz,
        q,
        transitionMs,
      );

  int phase2Stop(NativeAudioHandle handle) => _phase2Stop(handle);
  
  void setStereoEnabled(NativeAudioHandle handle, int enabled) => _setStereoEnabled(handle, enabled);
  
  void registerLogCallback(NativeAudioHandle handle, Pointer<NativeFunction<LogCallbackC>> cb) =>
      _registerLogCallback(handle, cb);

  void registerOutputLostCallback(
    NativeAudioHandle handle,
    Pointer<NativeFunction<OutputLostCallbackC>> cb,
  ) =>
      _registerOutputLostCallback(handle, cb);

  void resetOutputStream(NativeAudioHandle handle) => _resetOutputStream(handle);

  void setOutputDeviceId(NativeAudioHandle handle, int deviceId) =>
      _setOutputDeviceId(handle, deviceId);

  int runTestPhase52(NativeAudioHandle handle, int testId) =>
      _runTestPhase52(handle, testId);
      
  void setPhase52GeneratorParams(NativeAudioHandle handle, int generatorId, double p1, double p2, double p3, double p4, double p5) =>
      _phase52SetGeneratorParams(handle, generatorId, p1, p2, p3, p4, p5);
      
  void getDiagnostics(NativeAudioHandle handle, Pointer<Float> outRms, Pointer<Float> outPeak, Pointer<Int32> outNanCount, Pointer<Int32> outClipCount) =>
      _phase52GetDiagnostics(handle, outRms, outPeak, outNanCount, outClipCount);
}
