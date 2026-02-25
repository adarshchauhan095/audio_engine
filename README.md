# Audio Engine (Flutter + Native C++ Oboe via FFI)

This project is a Flutter app with a native Android low-latency audio engine built in C++ using Oboe.

It is designed so that current behavior stays stable while architecture can grow safely:
- Existing API behavior is preserved.
- Existing start/stop behavior is preserved.
- Existing click/pop protections are preserved.
- New capabilities are optional and additive.

## 1. What this project does

- Generates a real-time sine tone.
- Supports runtime controls for:
  - Frequency (Hz)
  - Amplitude (0.0 to 1.0)
  - Playback start/stop
- Applies smoothing/ramping in native DSP to avoid zipper noise and clicks.
- Includes debug/stability actions in the Flutter UI.

## 2. Phase status (implemented)

- Phase 1: `VoiceManager` added in native layer.
  - Supports multiple oscillators.
  - Default remains one active voice (backward-compatible output behavior).
- Phase 2: `EventScheduler` added.
  - Stores timed parameter events.
  - Not active in render callback yet.
- Phase 3: High-precision frequency control added.
  - Oscillator target and ramp now support double precision through optional API.
- Phase 4: New API hooks exposed (not used by normal flow by default):
  - `setTargetFrequency()`
  - `scheduleSequence()`
  - `startSession()`
  - `stopSession()`
- Phase 5: Flutter session layer added.
  - `SessionController` introduced.
  - Debug panel includes:
    - Sequence test
    - Adaptive test
    - Long run stability test

## 3. Technology stack

- Flutter (UI, app lifecycle, state updates)
- Dart FFI (`dart:ffi`) for Flutter <-> native bridge
- C++17 for native engine and DSP
- Oboe `com.google.oboe:oboe:1.10.0` for Android low-latency audio
- CMake + Android NDK for native build
- Kotlin/Gradle Android host app

## 4. Platform support

- UI builds on multiple Flutter platforms.
- Native audio runtime is Android-only.
- On non-Android platforms, app shows: `Native audio only on Android`.

## 5. Architecture and interconnection

### Layered architecture

1. Flutter UI layer (`lib/ui/*`)
   - Displays controls and debug panels.
   - Never calls native symbols directly.

2. Dart engine facade (`lib/engine/audio_engine.dart`)
   - Single app-facing engine API.
   - Owns the native handle lifecycle.

3. Dart bindings layer (`lib/engine/bindings.dart`)
   - Symbol lookup and typed FFI wrappers.

4. C ABI bridge (`android/app/src/main/cpp/ffi/bridge.*`)
   - Thin C functions exported to FFI.
   - Delegates to C++ `AudioEngine`.

5. Native engine core (`android/app/src/main/cpp/engine/AudioEngine.*`)
   - Stream lifecycle, render callback, start/stop transport ramp.

6. Native DSP/support modules
   - `Oscillator.*`: sine generator + smoothed frequency ramp
   - `ParameterSmoother.*`: amplitude/transport one-pole smoothing
   - `VoiceManager.*`: multi-voice container (default 1 active voice)
   - `EventScheduler.*`: timed-event storage scaffold (passive for now)

### Interconnection map

`HomeScreen / SessionController`  
-> `AudioEngine` (Dart facade)  
-> `NativeBindings` (Dart FFI wrappers)  
-> `audio_*` C ABI symbols  
-> `AudioEngine` (C++)  
-> `VoiceManager / ParameterSmoother / EventScheduler / Oscillator`  
-> Oboe callback output (`onAudioReady`)

## 6. End-to-end runtime flow

### A. Startup flow

1. `main.dart` loads `HomeScreen`.
2. `HomeScreen` checks platform.
3. On Android:
   - Loads `libnative_audio.so`.
   - Creates `NativeBindings`.
   - Creates Dart `AudioEngine`, calls `init()` -> native `audio_create()`.
   - Sets initial frequency/amplitude defaults.
   - Creates `SessionController` (optional debug orchestration).

### B. Normal playback start flow

1. User presses Play.
2. Flutter calls `AudioEngine.start()`.
3. FFI calls `audio_start()`.
4. Native `AudioEngine::start()`:
   - Opens Oboe stream on first start.
   - Configures smoothing ramps.
   - Uses transport ramp-up (fade in).
   - Keeps stream for reuse across stop/start cycles.

### C. Real-time parameter flow

1. UI slider or test action updates frequency/amplitude.
2. Dart facade calls FFI setters.
3. Native layer updates targets (thread-safe atomics).
4. Audio callback applies per-sample smoothing/ramping:
   - Transport smoother
   - Amplitude smoother
   - VoiceManager output (currently 1 active voice by default)

### D. Stop flow

1. User presses Stop.
2. Flutter calls `AudioEngine.stop()`.
3. Native `AudioEngine::stop()` sets transport target to 0.
4. Output fades out smoothly; stream is not torn down immediately.

### E. Dispose flow

1. Flutter widget disposes engine.
2. Dart calls `audio_destroy()`.
3. Native engine stops/closes stream and releases resources.

### F. Optional session/scheduler flow (currently non-default)

- `setTargetFrequency(double)`:
  - Uses high-precision frequency target path.
- `scheduleSequence()`:
  - Loads default scheduler events into `EventScheduler`.
- `startSession()` / `stopSession()`:
  - Toggles session state in scheduler.
- Current status:
  - Scheduler events are stored but not consumed by `onAudioReady()` yet.
  - Normal playback path remains unchanged.

## 7. Public APIs

### Dart facade (`AudioEngine`)

- Existing stable API:
  - `init()`
  - `start()`
  - `stop()`
  - `isRunning`
  - `setFrequency(double)`
  - `setAmplitude(double)`
  - `dispose()`
- Optional new API:
  - `setTargetFrequency(double)`
  - `scheduleSequence()`
  - `startSession()`
  - `stopSession()`

### Native C ABI exports (`bridge.h`)

- Lifecycle/state:
  - `audio_create`, `audio_destroy`, `audio_start`, `audio_stop`, `audio_is_running`
- Existing parameter control:
  - `audio_set_frequency`, `audio_set_amplitude`
- Optional new hooks:
  - `audio_set_target_frequency`
  - `audio_schedule_sequence`
  - `audio_start_session`
  - `audio_stop_session`

## 8. Flutter UI and debug controls

### Main controls

- Frequency slider
- Amplitude slider
- Play/Stop floating action button

### Debug sections

- `Milestone 02 tests`:
  - Rapid params
  - Start/stop x10
  - Extreme values
- `Session debug`:
  - Sequence test
  - Adaptive test
  - Long run stability test

## 9. Important vs non-important

### Important (critical, must preserve)

- No regressions in `start()/stop()` behavior.
- No API break for existing engine calls.
- No audio artifacts from parameter changes or transport changes.
- Keep render callback real-time safe (no blocking/heavy work).
- Preserve FFI symbol consistency between Dart and C++.
- Keep default one-voice output behavior unless explicitly changed.
- Keep scheduler features optional and non-disruptive.

### Non-important (low priority for core audio correctness)

- Visual theme/colors/animations.
- UI icon choices and layout details.
- Non-audio platform boilerplate files.
- Documentation wording style.

## 10. Project structure (key files)

- `lib/main.dart` - app entrypoint.
- `lib/ui/home_screen.dart` - main UI, controls, debug panels.
- `lib/session/session_controller.dart` - optional test orchestrator.
- `lib/engine/audio_engine.dart` - unified Dart engine API.
- `lib/engine/bindings.dart` - FFI bindings.
- `lib/engine/ffi_types.dart` - native handle types.
- `android/app/src/main/cpp/ffi/bridge.h/.cpp` - native C ABI for FFI.
- `android/app/src/main/cpp/engine/AudioEngine.*` - core stream and callback logic.
- `android/app/src/main/cpp/engine/Oscillator.*` - oscillator + frequency ramp.
- `android/app/src/main/cpp/engine/ParameterSmoother.*` - smoothing utility.
- `android/app/src/main/cpp/engine/VoiceManager.*` - optional multi-voice management.
- `android/app/src/main/cpp/engine/EventScheduler.*` - passive scheduling scaffold.
- `android/app/src/main/cpp/CMakeLists.txt` - native library build target.
- `test/widget_test.dart` - platform-aware smoke test.

## 11. Build and run

### Prerequisites

- Flutter SDK
- Android SDK + NDK
- Android device/emulator

### Commands

```bash
flutter clean
flutter pub get
flutter run
```

### Quality checks

```bash
flutter analyze
flutter test
```

## 12. Validation checklist

- Start playback: smooth fade-in, no pop.
- Stop playback: smooth fade-out, no pop.
- Rapidly move frequency slider: no clicks/crackle.
- Rapidly move amplitude slider: no zipper noise.
- Run Milestone 02 test buttons: app remains stable.
- Run Session debug buttons: app remains stable.
- Verify optional APIs are callable and do not change normal flow unless used.

## 13. Constraints and notes

- Native audio output path is Android-only.
- Oboe engine config expects low-latency path and compatible device support.
- There are two `MainActivity.kt` files in different package folders; Gradle namespace/applicationId is `com.audio.audio_engine`.

## 14. Extension guidance

- Add future modules through `AudioEngine` facade first.
- Keep C ABI thin and stable.
- Keep optional features opt-in.
- If scheduler is activated in future, introduce it behind a guarded path and re-verify artifact-free behavior.

