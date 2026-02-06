import 'dart:ffi';
import 'ffi_types.dart';

typedef _CreateC = NativeAudioHandle Function();
typedef _CreateDart = NativeAudioHandle Function();

typedef _StartC = Int32 Function(NativeAudioHandle);
typedef _StartDart = int Function(NativeAudioHandle);

typedef _VoidNativeAudioHandleFuncC = Void Function(NativeAudioHandle);
typedef _VoidNativeAudioHandleFuncDart = void Function(NativeAudioHandle);

typedef _SetFloatC = Void Function(NativeAudioHandle, Float);
typedef _SetFloatDart = void Function(NativeAudioHandle, double);

class NativeBindings {
  late final _CreateDart create;
  late final _StartDart start;
  late final _VoidNativeAudioHandleFuncDart stop;
  late final _VoidNativeAudioHandleFuncDart destroy;
  late final _SetFloatDart setFrequency;
  late final _SetFloatDart setAmplitude;

  NativeBindings(DynamicLibrary lib) {
    create = lib.lookupFunction<_CreateC, _CreateDart>('audio_create');
    start = lib.lookupFunction<_StartC, _StartDart>('audio_start');
    stop = lib
        .lookupFunction<
          _VoidNativeAudioHandleFuncC,
          _VoidNativeAudioHandleFuncDart
        >('audio_stop');
    destroy = lib
        .lookupFunction<
          _VoidNativeAudioHandleFuncC,
          _VoidNativeAudioHandleFuncDart
        >('audio_destroy');
    setFrequency = lib.lookupFunction<_SetFloatC, _SetFloatDart>(
      'audio_set_frequency',
    );
    setAmplitude = lib.lookupFunction<_SetFloatC, _SetFloatDart>(
      'audio_set_amplitude',
    );
  }
}
