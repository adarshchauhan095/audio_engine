import 'dart:ffi';

/// Opaque handle type for the native audio engine instance.
///
/// Used by [AudioEngine] and [NativeBindings]. Do not dereference or
/// use outside the engine layer.
typedef NativeAudioHandle = Pointer<Void>;
