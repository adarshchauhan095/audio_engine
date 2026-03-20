# Neuroacoustic Audio Engine (Flutter + Native C++ via FFI)

This project is a sophisticated neuroacoustic therapy engine. It leverages a Flutter frontend with an Android native audio engine (C++17 + Oboe) deeply connected through Dart FFI.

The application is specifically designed to provide structured therapy for tinnitus patients. It generates precise real-time tones, allows for meticulous tinnitus frequency detection, and implements advanced adaptive therapy modules that disrupt pathological synchronization patterns in the auditory cortex.

## Table of Contents

1. [Current Project Scope](#current-project-scope)
2. [What Is Used in This Project](#what-is-used-in-this-project)
3. [Important vs Non-Important](#important-vs-non-important)
4. [Current App Flow](#current-app-flow)
5. [How Components Are Interconnected](#how-components-are-interconnected)
6. [Key Packages and Documentation](#key-packages-and-documentation)

---

## Current Project Scope

The app provides core tools for tinnitus detection, therapy session execution, and audio generation. It exposes 5 primary environments through a shared runtime:

- **Tinnitus Detection:** Highly refined coarse/fine tuning tools with step/sweep behaviors to isolate the user's specific tinnitus frequency.
- **Adaptive Therapy Sessions:** The core product tiering (Basic, Standard, Premium) allowing users to run adaptive, time-based therapy sessions tailored to their detected frequency. Presets carry distinct module flags and tuning; per-preset **base frequency** and **base amplitude** are applied in native `TherapyConfig` so switching presets produces audible and measurable differences. The **Adaptive Therapy** UI supports editing preset parameters (frequency, amplitude, module toggles, and tuning values) and live updates while a session runs via `TherapySessionController.updatePreset`.
- **Audio Controls:** Live frequency and amplitude sliders to directly interact with the underlying tone generator.
- **My Profile & Progress:** Tracking of completed therapy sessions and easy selection of pre-configured therapy presets (profiles). **Therapy adherence** (accumulated therapy seconds from `TherapySessionController.totalTherapySeconds`) is persisted with `shared_preferences` via `TherapyAdherenceStorage` and restored when the app restarts so progress is not lost.
- **Debug Tests:** Deep technical tests (rapid parameter checks, stability limits, sequence tests) for engine validation. **Long-run stability** duration is selectable (short cycles such as 15–60 seconds and longer runs such as 5–60 minutes) and passed into `SessionController.runLongRunStabilityTest` so extended soak tests are not capped to a fixed short length.

Additional developer-facing surfaces include **Module Demo** and **Premium Features** screens that exercise `therapyStart` / `therapyUpdate` / `therapyStop` in isolation, and **real-time module graphs** (expected vs engine-measured levels) implemented in Flutter with optional native read-only per-module meters exposed through FFI (`audio_get_therapy_module_meter`).

---

## What Is Used in This Project

### UI and App Layer
- **Framework:** Flutter (Material 3) with Dart 3.
- **State Management:** Low-overhead `ValueNotifier` and `ValueListenableBuilder` setup tailored for high-speed audio metrics.

### Native Integration & DSP (Digital Signal Processing)
- **Bridge:** Dart FFI (`dart:ffi`) to a C ABI bridge.
- **DSP Core:** Native C++17 engine code.
- **Audio Output:** Oboe (`com.google.oboe:oboe:1.10.0`) for ultra-low latency, glitch-free Android audio streams.
- **Therapy Modules:**
    - *Subthreshold Desynchronization* (Base Tone & AM/FM Modulation)
    - *Randomized Micro-Perturbation (RMP)*
    - *Phase-Interruption Patterning (PIP)*
    - *Spectral Sideband Stimulation (SSS)*
    - *Binaural Desynchronization*
- **Therapy routing:** `TherapyRouter` applies `TherapyConfig`, including per-config **base frequency and base amplitude** used for module processing, and optional **read-only module meters** (normalized) for UI visualization without altering the audio path.

### Persistence & Storage
- **Local Storage:** `shared_preferences`
- **Schemas:** JSON serialization for detected frequencies and custom saved therapy parameter sessions.
- **Therapy adherence:** Integer total seconds stored under a dedicated key (`TherapyAdherenceStorage`) and wired from `AudioRuntimeController` (debounced saves on `totalTherapySeconds` changes).

---

## Important vs Non-Important

### Highly Important (Critical Architecture)
- **The FFI Contract:** The `audio_*` symbols and signatures in the Dart/C bridge must be perfectly synchronized (including therapy APIs and any added getters such as `audio_get_therapy_module_meter`).
- **Real-time Safety:** The C++ audio render callback (`onAudioReady`) must NEVER be blocked by mutexes, allocations, or heavy calculations.
- **Parameter Smoothers:** Amplitude and frequency transitions must use one-pole smoothing to prevent acoustic clicks/pops (especially during RMP).
- **The Adaptive Parameter Engine Flow:** The timer orchestration in Flutter (`TherapySessionController`) coordinating phase changes (Warm-up -> Main Phase -> Cool-down) by dynamically injecting new parameters into C++ over time. High-resolution **`elapsedSeconds`** (sub-second) supports UI-only expected graphs (e.g. PIP timing). Stop handling uses a **stop-requested guard** and ordered **engine mute (`stop`) then therapy disable (`therapyStop`)** to reduce clicks and stray output.
- **Frequency Clamping:** Ensuring the UI prevents frequencies outside human/device limits from reaching DSP processors.

### Non-Important (Subject to Change)
- **UI Colors/Themes:** Exact color choices, font themes, or visual layouts are secondary to the precision interactions (like the long-press Sweep actions in the Detection screen).
- **Extraneous Screens:** Legacy files (e.g., old `HomeScreen` imports not actively bound to the Navigator shell).
- **Extraneous Android Artifacts:** Any Kotlin `MainActivity` files existing in unused namespaces like `com/example/...` while the active package is `com.audio.audio_engine`.

---

## Current App Flow

### 1. Initialization Core
1. The app starts and launches the `AppShell`.
2. `AppShell` singletonly initializes the `AudioRuntimeController`.
3. The controller dynamically loads `libnative_audio.so`, resolves the FFI `NativeBindings`, creates the native engine handle, and primes the initial DSP states.
4. On Android, **therapy adherence** is loaded from `TherapyAdherenceStorage` into `TherapySessionController.totalTherapySeconds`, and changes are saved with debouncing so adherence survives app restarts.

### 2. Tinnitus Detection Workflow
1. User accesses the **Detection Screen**.
2. They use coarse sliders for 100Hz steps and fine Tap (+/- 1Hz & 5Hz) / Hold (Continuous Sweep) buttons to match their tinnitus pitch precisely.
3. Amplitude controls act as an internal control frame, ensuring the tone doesn't overpower the tinnitus.
4. Saving the frequency stores it in SharedPreferences and binds it as the base frequency for future therapy sessions.

### 3. Adaptive Therapy Session Flow
This is the core therapeutic process using the architecture built in Milestone 4.
1. User selects a **Profile Preset** (Basic, Standard, Premium) from `TherapyProfilePreset` / `ProfileSessionCatalog`-driven UIs.
2. User chooses a total **Duration** (e.g., 10 minutes).
3. The `TherapySessionController` creates a schedule: **20% Warm-up**, **60% Main Phase**, **20% Cool-down**.
4. Execution:
    - **Warm-up:** The `TherapyRouter` (C++) starts. Flutter runs a 200ms timer (`Timer.periodic`), ramping intensity safely from `0%` to the configured max. **`elapsedSeconds`** is updated with millisecond-derived precision for UI graphs.
    - **Main Phase:** The `TherapyRouter` invokes the specific modules (RMP jitter, PIP interruptions, Sideband generation, Binaural offsets) at full force based on the chosen preset and current `TherapyConfig` (including **baseFreq/baseAmp** carried in config).
    - **Cool-down:** Flutter gracefully decays the intensity back to zero over the final phase.
5. The session automatically halts; **therapy adherence** increments via `totalTherapySeconds` and is persisted through `AudioRuntimeController` + `TherapyAdherenceStorage`.
6. **Module graphs:** While running, screens can show **expected** traces (derived from intensity, toggles, and PIP timing) and **measured** traces from native meters (`AudioEngine.getTherapyModuleMeter`), polled from the UI thread without changing DSP behavior.

### 4. Debug and soak testing (optional)
1. From the debug-oriented UI, the user selects a **long-run duration** (short or multi-minute) and runs `SessionController.runLongRunStabilityTest`, which steps frequency/amplitude over time without altering therapy session logic.

---

## How Components Are Interconnected

The architecture follows a strict one-way control flow from the Flutter UI down into the C++ DSP core.

```text
Flutter UI & User Interaction (Screens, Taps, Sliders)
   │
   ▼
AudioRuntimeController & Session Controllers (State tracking, Timers, Phase Logic)
   │  ├── TherapySessionController (phases, intensity, elapsedSeconds, therapyStart/Update/Stop)
   │  ├── SessionController (debug sequences / long-run tests)
   │  └── Therapy adherence persistence (TherapyAdherenceStorage + totalTherapySeconds listener)
   │
   ▼
AudioEngine (Dart Facade converting logic into FFI method calls)
   │
   ▼
NativeBindings (C ABI Bridge matching `audio_*` signatures, including therapy + module meter getter)
   │
   ▼
TherapyRouter (C++ Core taking `TherapyConfig` structs from the bridge)
   │
   ├──> SubthresholdModule
   ├──> RMPModule
   ├──> PIPModule
   ├──> SidebandModule
   └──> BinauralModule
   │
   ▼
VoiceManager / ParameterSmoother (Mixing and smoothing transitions)
   │
   ▼
Oboe (Hardware render thread outputting the final StereoSample to the Android device)