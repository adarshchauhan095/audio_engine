# Audio Engine (Flutter + Native C++ via FFI)

This project is a Flutter app with an Android native audio engine (C++ + Oboe) connected through Dart FFI.

It generates real-time tone audio, supports live control of frequency and amplitude, includes tinnitus frequency detection, and provides session planning/debug tools with local persistence.

## Table of Contents

1. [Current Project Scope](#current-project-scope)
2. [What Is Used in This Project](#what-is-used-in-this-project)
3. [Current App Flow](#current-app-flow)
4. [How Components Are Interconnected](#how-components-are-interconnected)
5. [Important vs Non-Important](#important-vs-non-important)
6. [Key Files and Responsibilities](#key-files-and-responsibilities)
7. [Build, Run, and Validate](#build-run-and-validate)
8. [Known Constraints and Notes](#known-constraints-and-notes)

## Current Project Scope

The app currently exposes 5 screens through a shared runtime:

- Audio Controls: live frequency/amplitude sliders for tone playback.
- Tinnitus Detection: coarse/fine tuning, sweep up/down, save/load detected frequency.
- Debug Tests: rapid parameter tests, repeated start/stop, sequence/adaptive/long-run checks.
- Patient Sessions: run session templates for selected patients, batch or single execution.
- Saved Params: load/delete previously saved session parameter sets.

## What Is Used in This Project

### UI and app layer

- Flutter (Material 3)
- Dart 3
- `ValueNotifier` based state updates

### Native integration

- Dart FFI (`dart:ffi`)
- C ABI bridge (`audio_*` functions)
- C++17 engine code
- Oboe (`com.google.oboe:oboe:1.10.0`) for low-latency Android audio
- Android NDK + CMake

### Persistence

- `shared_preferences`
- One key for detected tinnitus frequency: `detected_tinnitus_frequency`
- One key for saved session params list: `saved_session_params_list_v1`

### Main runtime modules

- `AudioRuntimeController`: shared app runtime for all screens.
- `AudioEngine` (Dart): single facade around FFI bindings.
- `NativeBindings`: typed FFI lookups for C ABI functions.
- Native `AudioEngine` (C++): owns Oboe stream + DSP path.
- `VoiceManager` + `Oscillator`: tone generation.
- `ParameterSmoother`: artifact-free parameter ramps.
- `SessionController`: optional debug/session orchestrator.

## Current App Flow

### 1. Startup flow

1. `main.dart` starts `MyApp`.
2. `MyApp` loads `AppShell`.
3. `AppShell` creates one shared `AudioRuntimeController`.
4. `AudioRuntimeController`:
   - On Android: opens `libnative_audio.so`, builds bindings, creates native engine handle, sets initial frequency and amplitude.
   - On non-Android: publishes error `Native audio only on Android` and no engine is created.
5. `AppShell` shows a bottom navigation with 5 screens, all using the same runtime instance.

### 2. Playback flow (Play/Stop)

1. User taps floating action button (Play/Stop on non-session screens).
2. Runtime calls `AudioEngine.start()` or `AudioEngine.stop()`.
3. Dart `AudioEngine` calls FFI binding.
4. C bridge function forwards to C++ `AudioEngine`.
5. Native engine behavior:
   - Start: opens stream on first call, sets smoother targets, requests stream start.
   - Stop: sets transport smoother target to `0.0` (fade out), keeps stream allocated.

### 3. Live controls flow (Audio Controls screen)

1. Frequency slider calls `runtime.setFrequency()`.
2. Amplitude slider calls `runtime.setAmplitude()`.
3. Runtime clamps values to control range (`110..880` Hz for frequency, `0..1` for amplitude).
4. Runtime forwards values to native engine through `AudioEngine`.
5. Audio callback applies smooth transitions sample-by-sample and renders output.

### 4. Tinnitus detection flow

1. Detection screen hosts `TinnitusDetectionSection`.
2. Coarse slider (`20..8000` Hz, 100 Hz steps), fine buttons (`-5/-1/+1/+5`), and sweep timer update a local detection frequency notifier.
3. Detection notifier listener calls `engine.setFrequency()` directly.
4. Save action stores clamped frequency in `SharedPreferences` (`detected_tinnitus_frequency`).
5. Load action restores saved value and applies it back to engine.

Important current behavior:

- Detection screen updates engine frequency directly, not `AudioRuntimeController.frequency` notifier.
- This keeps detection isolated, but the Controls screen frequency label can stay stale until controls update it.

### 5. Debug tests flow

Debug screen triggers runtime actions:

- Rapid params: frequent frequency/amplitude updates over short interval.
- Start/stop x10: repeated transport transitions.
- Extreme values: stress setter path.
- Sequence/adaptive/long-run: delegated to `SessionController`.

Only one debug action runs at a time through `runExclusiveDebugAction`.

### 6. Patient sessions flow

1. User selects a patient profile.
2. App builds 10 template sessions for that patient.
3. User can run single session or full batch.
4. Runtime starts playback if needed, applies session params, tracks elapsed/remaining/progress, and publishes `activeSession` snapshots.
5. User can end running session; runtime stops ticker and playback.
6. Current values can be saved into persistent "saved params" storage.

### 7. Saved params flow

1. Saved params screen loads all entries from `SessionParamsStorage`.
2. Each entry can be:
   - Applied to runtime.
   - Executed as a session.
   - Deleted from storage.
3. List persists across app restarts (JSON list in SharedPreferences).

### 8. Native render flow

Inside `AudioEngine::onAudioReady` for each output sample:

1. Read transport smoother.
2. Read amplitude smoother.
3. Generate oscillator sample through `VoiceManager`.
4. Write `transport * amplitude * sample`.

This keeps updates artifact-resistant during rapid UI changes.

## How Components Are Interconnected

```text
Flutter UI Screens
  -> AudioRuntimeController (shared state + orchestration)
      -> AudioEngine (Dart facade)
          -> NativeBindings (FFI symbols)
              -> C ABI bridge (audio_* functions)
                  -> AudioEngine (C++)
                      -> ParameterSmoother (transport/amplitude)
                      -> VoiceManager -> Oscillator(s)
                      -> Oboe output stream
```

Persistence interconnections:

```text
TinnitusDetectionSection -> DetectedFrequencyStorage -> SharedPreferences
Patient/Saved screens    -> SessionParamsStorage     -> SharedPreferences
```

Session interconnections:

```text
PatientScreens/Debug -> AudioRuntimeController -> SessionController (optional orchestrator)
                                           -> AudioEngine (actual playback + setters)
```

## Important vs Non-Important

### Important (critical for correctness)

- Keep the FFI contract stable (`audio_*` symbols and signatures in Dart/C bridge).
- Keep render callback real-time safe (no blocking operations in audio callback).
- Preserve smoother-based parameter transitions to avoid clicks/pops.
- Preserve transport fade behavior for `start()` and `stop()`.
- Keep Android-only engine initialization guard.
- Keep storage key compatibility for persisted user data.
- Maintain single shared runtime across screens (state continuity).
- Ensure timers are cleaned up (`TinnitusDetectionSection` sweep timer, runtime session ticker).

### Non-important (lower priority)

- Theme colors and icon choices.
- Exact UI text phrasing.
- Visual layout details that do not affect logic.
- Legacy `HomeScreen` (not current app entry path).
- Extra Kotlin `MainActivity` file under `com/example/...` if not referenced by active package.

## Key Files and Responsibilities

### App entry and shell

- `lib/main.dart`: starts app and mounts `AppShell`.
- `lib/ui/app_shell.dart`: navigation shell and shared runtime ownership.

### Runtime and business flow

- `lib/session/audio_runtime_controller.dart`: shared state, playback toggles, tests, patient sessions.
- `lib/session/session_controller.dart`: sequence/adaptive/long-run orchestration logic.
- `lib/session/patient_session_catalog.dart`: patient examples + 10 template sessions.

### UI screens

- `lib/ui/screens/audio_control_screen.dart`: frequency/amplitude controls.
- `lib/ui/screens/tinnitus_detection_screen.dart`: tinnitus screen wrapper.
- `lib/ui/tinnitus_detection_section.dart`: detection logic, sweep, save/load.
- `lib/ui/screens/debug_tests_screen.dart`: debug actions.
- `lib/ui/screens/patient_sessions_screen.dart`: templates and execution.
- `lib/ui/screens/saved_session_params_screen.dart`: saved params CRUD and session start.

### Storage

- `lib/storage/detected_frequency_storage.dart`: single detected frequency storage.
- `lib/storage/session_params_storage.dart`: list storage for reusable session params.
- `lib/models/session_params.dart`: serializable session model with normalization.

### Engine bridge and native core

- `lib/engine/audio_engine.dart`: Dart facade.
- `lib/engine/bindings.dart`: FFI mapping.
- `android/app/src/main/cpp/ffi/bridge.h` and `bridge.cpp`: C ABI bridge.
- `android/app/src/main/cpp/engine/AudioEngine.*`: stream lifecycle + render callback.
- `android/app/src/main/cpp/engine/ParameterSmoother.*`: one-pole smoothing.
- `android/app/src/main/cpp/engine/Oscillator.*`: sine oscillator with frequency smoothing.
- `android/app/src/main/cpp/engine/VoiceManager.*`: multi-voice container (default one active voice).
- `android/app/src/main/cpp/engine/EventScheduler.*`: passive scheduling scaffold.

## Build, Run, and Validate

### Prerequisites

- Flutter SDK
- Android SDK and NDK
- Android device/emulator

### Run

```bash
flutter clean
flutter pub get
flutter run
```

### Analyze and test

```bash
flutter analyze
flutter test
```

### Quick manual checks

- Play/Stop fades without clicks.
- Frequency and amplitude sliders respond smoothly.
- Tinnitus detection coarse/fine/sweep updates live tone.
- Save detected frequency, restart app, load detected frequency.
- Run debug actions one by one; no crash/hang.
- Run patient single and batch sessions; progress/countdown updates correctly.
- Save session params, verify they appear in Saved Params screen after restart.

## Known Constraints and Notes

- Native audio engine is Android-only by design in current flow.
- Frequency range policy differs by module:
  - Controls runtime clamp: `110..880` Hz.
  - Detection and session model clamp: `20..8000` Hz.
- `HomeScreen` still exists in repository but is not the active route from `main.dart`.
- `test/engine_tests.dart` is currently empty; native engine behavior is mainly validated manually.
- There are two `MainActivity.kt` files in tree, but active package namespace is `com.audio.audio_engine`.
