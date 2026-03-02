# Audio Engine — Flutter + Native C++ (Oboe) via FFI

A Flutter app with a native Android low-latency audio engine (C++/Oboe). It generates real-time tones, supports smooth parameter control and start/stop, and includes a **user-driven tinnitus frequency detection** module (Milestone 3) with coarse/fine search, sweep mode, and persistent storage.

---

## Table of contents

1. [What this project does](#1-what-this-project-does)
2. [Milestones and features](#2-milestones-and-features)
3. [Technology stack](#3-technology-stack)
4. [Project flow — how it works](#4-project-flow--how-it-works)
5. [Architecture and how things are interconnected](#5-architecture-and-how-things-are-interconnected)
6. [What is used in this project](#6-what-is-used-in-this-project)
7. [Important vs non-important](#7-important-vs-non-important)
8. [Project structure (key files)](#8-project-structure-key-files)
9. [Build and run](#9-build-and-run)
10. [Validation and testing](#10-validation-and-testing)
11. [Constraints and extension guidance](#11-constraints-and-extension-guidance)

---

## 1. What this project does

- **Real-time sine tone** from a native oscillator (smoothed frequency, no clicks).
- **Runtime controls**: frequency (Hz), amplitude (0–1), play/stop with smooth fades.
- **Tinnitus frequency detection (M3)**: user finds their tone via coarse slider, fine ±1/±5 Hz buttons, optional upward/downward sweep (adjustable speed, interruptible), then **saves** the value; it **persists across app restarts**.
- **Stability and debug**: M2 test panel (rapid params, start/stop cycles, extreme values) and session debug (sequence, adaptive, long-run tests).
- **No audio artifacts**: parameter and transport changes are ramp-smoothed in native DSP; frequency changes are smoothed in the oscillator.

---

## 2. Milestones and features

### Milestone 2 — Engine architecture and core parameter system

- **Modular structure**: DSP core (Oscillator, ParameterSmoother) → parameter layer (atomics + ramps) → UI bindings (Flutter calls only `AudioEngine`).
- **Unified API**: `setFrequency`, `setAmplitude`, `start`, `stop`, `isRunning` — single entry point for all control.
- **Sample-accurate ramps**: amplitude and transport use one-pole smoothers per sample; no zipper noise or pops.
- **Frequency control module**: real-time frequency changes with internal smoothing; stable under large jumps; same API used by M3.
- **Clean start/stop**: ~20 ms fade-in/fade-out; stream kept open to avoid HAL pops.
- **Test APK**: minimal UI with all parameters + M2 test panel.

### Milestone 3 — Individual frequency detection module

- **Coarse search**: slider 20–8000 Hz in 100 Hz steps for quick range finding.
- **Fine search**: buttons −5, −1, +1, +5 Hz for precise matching.
- **Sweep mode**: upward or downward sweep with selectable speed (slow / medium / fast); **interruptible at any time** (Stop leaves frequency at current value).
- **Persistent storage**: “Save as my frequency” writes to local storage; “Saved frequency: X Hz” is shown; value **persists across app restarts**.
- **Load saved**: applies the stored frequency to the engine so user can continue from last detection.
- **Integration**: uses only `AudioEngine.setFrequency` (and existing start/stop/amplitude); no native/FFI changes; sweep timer cancelled on widget dispose.

### Other (pre-existing / optional)

- **VoiceManager** (native): multi-voice container; default remains one active voice.
- **EventScheduler** (native): timed-event storage; not yet driven from render callback.
- **SessionController** (Dart): optional session/debug orchestration; sequence / adaptive / long-run tests.
- **High-precision API**: `setTargetFrequency`, `scheduleSequence`, `startSession`, `stopSession` — optional hooks; normal playback path unchanged.

---

## 3. Technology stack

| Layer        | Technology |
|-------------|------------|
| UI / app    | Flutter, Dart 3.x |
| Bridge      | Dart FFI (`dart:ffi`) |
| Native API  | C ABI (bridge), C++17 |
| Audio I/O   | Oboe (Android low-latency) |
| Persistence (M3) | `shared_preferences` |
| Build       | CMake, Android NDK, Gradle/Kotlin |

- **Platform**: Native audio runs **only on Android**. On other platforms the app shows “Native audio only on Android”.

---

## 4. Project flow — how it works

### A. App startup

1. `main.dart` runs the app and shows `HomeScreen`.
2. `HomeScreen.initState()` → `_initEngine()`:
   - If not Android → set error message and show error UI; **stop**.
   - If Android:
     - Load `libnative_audio.so`, create `NativeBindings`, create `AudioEngine`, call `init()` (→ native `audio_create()`).
     - Set initial frequency and amplitude on the engine.
     - Create `SessionController` with the engine and callbacks (for session/debug).
3. **M3**: When the user opens the “Tinnitus frequency detection” section, it loads saved frequency from storage (if any) and displays “Saved frequency: X Hz”. It does **not** change the engine frequency until the user uses coarse/fine/sweep or taps “Load saved”.

### B. Normal playback (Play/Stop)

1. User taps **Play** → `AudioEngine.start()` → FFI `audio_start()` → native `AudioEngine::start()`:
   - First time: open Oboe output stream, configure amplitude and transport smoothers, ramp transport to 1 (~20 ms), start stream.
   - Later: reuse existing stream, set transport target to 1 again (fade in).
2. User taps **Stop** → `AudioEngine.stop()` → native sets transport target to 0; output fades out; **stream is not closed** (avoids device pops on next start).

### C. Real-time parameter updates (sliders / detection)

1. **Main sliders**: User moves frequency or amplitude slider → `HomeScreen` calls `_engine.setFrequency(v)` or `_engine.setAmplitude(v)` → FFI → native stores **atomic target** → audio callback each sample runs **smoothers** (amplitude, transport) and **oscillator** (frequency smoothed internally) → output is artifact-free.
2. **Tinnitus detection section**: Coarse slider, fine buttons, or sweep timer update a local “detection frequency” value (clamped 20–8000 Hz), then call `engine.setFrequency(value)`. Same path as above: native target + per-sample smoothing. **Sweep** uses a Dart `Timer.periodic` to step frequency; when user taps **Stop sweep**, the timer is cancelled and the current frequency is kept.

### D. Saving and loading detected frequency (M3)

1. **Save**: User taps “Save as my frequency” → `DetectedFrequencyStorage.saveDetectedFrequency(currentHz)` → value clamped to 20–8000 Hz and written to `SharedPreferences` under key `detected_tinnitus_frequency` → UI shows SnackBar and “Saved frequency: X Hz”.
2. **Load**: User taps “Load saved” → `DetectedFrequencyStorage.loadDetectedFrequency()` → read from storage → apply to detection frequency notifier and call `engine.setFrequency(loaded)` so the tone matches the saved value.
3. **Persistence**: After app restart, the same key is read when the detection section is used; “Saved frequency: X Hz” appears; user can tap “Load saved” to apply it again.

### E. Dispose and cleanup

1. When `HomeScreen` is disposed: `SessionController.dispose()`, then `AudioEngine.dispose()` → FFI `audio_destroy()` → native engine stops/closes stream and is deleted.
2. **TinnitusDetectionSection** disposes its sweep timer (if any) and its frequency notifier so no callbacks run after the widget is gone.

---

## 5. Architecture and how things are interconnected

### Layered architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter UI (lib/ui/)                                            │
│  HomeScreen, FrequencySlider, AmplitudeSlider,                    │
│  TinnitusDetectionSection (M3)                                   │
│  → Only calls AudioEngine; never touches FFI or native directly  │
└───────────────────────────────┬─────────────────────────────────┘
                                 │
┌───────────────────────────────▼─────────────────────────────────┐
│  Dart engine facade (lib/engine/audio_engine.dart)               │
│  AudioEngine: init, start, stop, isRunning,                      │
│  setFrequency, setAmplitude, (setTargetFrequency, session APIs)  │
│  → Single app-facing API; owns native handle lifecycle            │
└───────────────────────────────┬─────────────────────────────────┘
                                 │
┌───────────────────────────────▼─────────────────────────────────┐
│  Dart bindings (lib/engine/bindings.dart)                        │
│  NativeBindings: lookup of audio_* C symbols                     │
│  → Used only by AudioEngine; not by UI                           │
└───────────────────────────────┬─────────────────────────────────┘
                                 │  FFI
┌───────────────────────────────▼─────────────────────────────────┐
│  C ABI bridge (android/.../cpp/ffi/bridge.h, bridge.cpp)         │
│  audio_create, audio_destroy, audio_start, audio_stop,           │
│  audio_is_running, audio_set_frequency, audio_set_amplitude, ...  │
│  → Thin wrappers; delegate to C++ AudioEngine                    │
└───────────────────────────────┬─────────────────────────────────┘
                                 │
┌───────────────────────────────▼─────────────────────────────────┐
│  Native engine (android/.../cpp/engine/AudioEngine.*)            │
│  Oboe stream lifecycle, onAudioReady callback,                    │
│  transport + amplitude smoothers, VoiceManager (→ Oscillator)    │
└───────────────────────────────┬─────────────────────────────────┘
                                 │
┌───────────────────────────────▼─────────────────────────────────┐
│  DSP / support (engine/Oscillator.*, ParameterSmoother.*,       │
│  VoiceManager.*, EventScheduler.*)                                │
│  → Oscillator: smoothed frequency, sine output                  │
│  → ParameterSmoother: per-sample ramp for amplitude & transport   │
└─────────────────────────────────────────────────────────────────┘
```

### M3-specific interconnection

```
HomeScreen
  └─ TinnitusDetectionSection(engine: _engine)
       ├─ Coarse slider / Fine buttons / Sweep
       │    → _detectionFrequency (ValueNotifier)
       │    → listener calls engine.setFrequency(clamped)
       ├─ Save button
       │    → DetectedFrequencyStorage.saveDetectedFrequency(...)
       │    → SharedPreferences (key: detected_tinnitus_frequency)
       └─ Load saved
            → DetectedFrequencyStorage.loadDetectedFrequency()
            → engine.setFrequency(loaded), update UI

DetectedFrequencyStorage (lib/storage/detected_frequency_storage.dart)
  └─ shared_preferences
       └─ key: 'detected_tinnitus_frequency', value: double (20–8000 Hz)
```

- **No direct link from UI to native/FFI**: All control goes through `AudioEngine`. M3 reuses the same `setFrequency` path as the main slider.
- **SessionController**: Uses `AudioEngine` (via `AudioControl` interface) and callbacks to sync frequency/amplitude/playing state with `HomeScreen` for session/debug flows; does not drive M3 detection.

---

## 6. What is used in this project

| Component | Purpose | Used by |
|-----------|--------|--------|
| **AudioEngine** (Dart) | Single API for playback and parameters | HomeScreen, SessionController, TinnitusDetectionSection |
| **NativeBindings** | FFI symbol lookup and typed wrappers | AudioEngine only |
| **bridge.h / bridge.cpp** | C ABI for Dart FFI | Native build; called from Dart via bindings |
| **AudioEngine** (C++) | Stream, transport, amplitude, voice routing | bridge, Oscillator, ParameterSmoother, VoiceManager |
| **Oscillator** | Sine wave, smoothed frequency | AudioEngine render path |
| **ParameterSmoother** | Per-sample ramp (amplitude, transport) | AudioEngine render path |
| **VoiceManager** | Multi-voice container (default 1 voice) | AudioEngine |
| **EventScheduler** | Timed events (passive until wired) | Native engine (optional) |
| **SessionController** | Session/debug orchestration | HomeScreen |
| **DetectedFrequencyStorage** | Save/load detected frequency (M3) | TinnitusDetectionSection |
| **shared_preferences** | Persistent key-value store (M3) | DetectedFrequencyStorage |
| **FrequencySlider / AmplitudeSlider** | Main screen sliders | HomeScreen |
| **TinnitusDetectionSection** | Coarse/fine/sweep/save/load UI (M3) | HomeScreen |

---

## 7. Important vs non-important

### Important (critical — must preserve)

- **No regressions** in `start()` / `stop()`: smooth fades, stream reuse, no pops.
- **No breaking changes** to existing engine API (`setFrequency`, `setAmplitude`, `start`, `stop`, `isRunning`, `init`, `dispose`).
- **No audio artifacts**: parameter and transport changes must remain ramp-smoothed; frequency changes must remain smoothed in the oscillator.
- **Real-time safety**: audio callback must not block; no mutex in the callback; only atomics and lock-free smoothers.
- **FFI contract**: C ABI symbol names and signatures must match Dart bindings.
- **Default behavior**: one active voice, normal playback path unchanged when M3 or session features are used.
- **M3**: Sweep timer must be cancelled on widget dispose; frequency must be clamped to 20–8000 Hz before engine and storage; persistence key must stay consistent.

### Non-important (lower priority for correctness)

- Visual theme, colors, icons, exact layout of panels.
- Wording of labels and docs.
- Non-Android platform boilerplate (iOS/Windows/etc. for non-audio).
- Optional APIs (`setTargetFrequency`, `scheduleSequence`, `startSession`, `stopSession`) as long as they remain opt-in and do not affect the default path.

---

## 8. Project structure (key files)

```
lib/
  main.dart                    # App entrypoint
  engine/
    audio_engine.dart          # Unified Dart engine API
    audio_control.dart         # Minimal interface for session/testing
    bindings.dart              # FFI bindings (used only by AudioEngine)
    ffi_types.dart             # Native handle type
  storage/
    detected_frequency_storage.dart   # M3: save/load detected frequency
  session/
    session_controller.dart    # Optional session/debug orchestration
  ui/
    home_screen.dart           # Main screen: sliders, Play/Stop, M2/M3/session panels
    tinnitus_detection_section.dart   # M3: coarse/fine/sweep/save/load
    widgets/
      frequency_slider.dart
      amplitude_slider.dart

android/app/src/main/cpp/
  ffi/
    bridge.h, bridge.cpp       # C ABI for FFI
  engine/
    AudioEngine.h, .cpp        # Stream, callback, smoothers, voice routing
    Oscillator.h, .cpp         # Sine + frequency smoothing
    ParameterSmoother.h, .cpp  # One-pole ramp
    VoiceManager.*             # Multi-voice (default 1)
    EventScheduler.*           # Timed events (passive)

docs/
  M2_ENGINE_ARCHITECTURE.md    # M2 technical notes
  M3_FREQUENCY_DETECTION.md    # M3 technical notes + acceptance checklist
```

---

## 9. Build and run

### Prerequisites

- Flutter SDK
- Android SDK + NDK
- Android device or emulator

### Commands

```bash
flutter clean
flutter pub get
flutter run
```

For a debug APK:

```bash
flutter build apk --debug
```

### Dependencies (from pubspec)

- `flutter`, `cupertino_icons`
- `shared_preferences` (M3 persistence)

---

## 10. Validation and testing

### Quick checks

- **Play**: smooth fade-in, no pop.
- **Stop**: smooth fade-out, no pop.
- **Sliders**: move frequency and amplitude rapidly; no clicks or zipper noise.
- **M2 tests**: Rapid params, Start/stop x10, Extreme values — app stays stable.
- **M3**: Coarse/fine move tone in real time; sweep runs and stops immediately; Save → restart → “Saved frequency” shown → Load saved applies value; no crashes on rapid or large frequency changes.

### Automated

```bash
flutter analyze
flutter test
```

### Detailed checklists

- **M2**: See `docs/M2_ENGINE_ARCHITECTURE.md` (section 6).
- **M3**: See `docs/M3_FREQUENCY_DETECTION.md` (Acceptance checklist).

---

## 11. Constraints and extension guidance

- **Platform**: Native audio is Android-only. Other platforms show “Native audio only on Android”.
- **Oboe**: Low-latency path; behavior may depend on device and Android version.
- **Package**: There are two `MainActivity.kt` locations; the app package is `com.audio.audio_engine`.

### Extending the project

- Add features through the **AudioEngine** (Dart) API first; keep the C ABI thin and stable.
- Keep optional features (scheduler, session, high-precision) opt-in so the default playback path stays unchanged.
- If you add more native DSP or callbacks, keep the render path real-time safe (no blocking, no heavy work in the callback).
