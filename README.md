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
- **Adaptive Therapy Sessions:** The core product tiering (Basic, Standard, Premium) allowing users to run adaptive, time-based therapy sessions tailored to their detected frequency.
- **Audio Controls:** Live frequency and amplitude sliders to directly interact with the underlying tone generator.
- **My Profile & Progress:** Tracking of completed therapy sessions and easy selection of pre-configured therapy presets (profiles).
- **Debug Tests:** Deep technical tests (rapid parameter checks, stability limits, sequence tests) for engine validation.

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

### Persistence & Storage
- **Local Storage:** `shared_preferences`
- **Schemas:** JSON serialization for detected frequencies and custom saved therapy parameter sessions.

---

## Important vs Non-Important

### Highly Important (Critical Architecture)
- **The FFI Contract:** The `audio_*` symbols and signatures in the Dart/C bridge must be perfectly synchronized.
- **Real-time Safety:** The C++ audio render callback (`onAudioReady`) must NEVER be blocked by mutexes, allocations, or heavy calculations.
- **Parameter Smoothers:** Amplitude and frequency transitions must use one-pole smoothing to prevent acoustic clicks/pops (especially during RMP).
- **The Adaptive Parameter Engine Flow:** The timer orchestration in Flutter (`TherapySessionController`) coordinating phase changes (Warm-up -> Main Phase -> Cool-down) by dynamically injecting new parameters into C++ over time.
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

### 2. Tinnitus Detection Workflow
1. User accesses the **Detection Screen**.
2. They use coarse sliders for 100Hz steps and fine Tap (+/- 1Hz & 5Hz) / Hold (Continuous Sweep) buttons to match their tinnitus pitch precisely.
3. Amplitude controls act as an internal control frame, ensuring the tone doesn't overpower the tinnitus.
4. Saving the frequency stores it in SharedPreferences and binds it as the base frequency for future therapy sessions.

### 3. Adaptive Therapy Session Flow
This is the core therapeutic process using the architecture built in Milestone 4.
1. User selects a **Profile Preset** (Basic, Standard, Premium).
2. User chooses a total **Duration** (e.g., 10 minutes).
3. The `TherapySessionController` creates a schedule: **20% Warm-up**, **60% Main Phase**, **20% Cool-down**.
4. Execution:
   - **Warm-up:** The `TherapyRouter` (C++) starts. Flutter continuously polls a 200ms timer, ramping intensity safely from `0%` to the configured max.
   - **Main Phase:** The `TherapyRouter` invokes the specific modules (RMP jitter, PIP interruptions, Sideband generation, Binaural offsets) at full force based on the chosen Product Tier.
   - **Cool-down:** Flutter gracefully decays the intensity back to zero over the final phase.
5. The session automatically halts and logs completion to the Profile tracker.

---

## How Components Are Interconnected

The architecture follows a strict one-way control flow from the Flutter UI down into the C++ DSP core.

```text
Flutter UI & User Interaction (Screens, Taps, Sliders)
   │
   ▼
AudioRuntimeController & Session Controllers (State tracking, Timers, Phase Logic)
   │
   ▼
AudioEngine (Dart Facade converting logic into FFI method calls)
   │
   ▼
NativeBindings (C ABI Bridge matching `audio_*` signatures)
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
```

## Key Packages and Documentation

- **`lib/session/audio_runtime_controller.dart`:** The nerve center. Owns the Flutter Engine instance bindings and global state (frequency, amplitude, play state).
- **`lib/session/therapy_session_controller.dart`:** The Adaptive Parameter Engine. Orchestrates the timing, math for Warm-up/Cooldown ramps, and module active states.
- **`lib/engine/bindings.dart`:** Maps Dart data types directly to C memory limits.
- **`android/app/src/main/cpp/engine/TherapyRouter.cpp`:** The C++ heart of Milestone 4. Routes the base sine wave through the array of enabled neuroacoustic modifiers before final mixing.
- **`lib/ui/tinnitus_detection_section.dart`:** Implements the intricate logic for sweep/hold timers required for precision clinical frequency matching.

### Documentation references
For further reading on the logic implemented:
- **DSP Modules:** Custom modifications utilizing the standard `<random>` and `<atomic>` C++ headers, implemented inside `android/app/src/main/cpp/engine/modules`.
- **UI Architecture:** Built entirely utilizing Flutter's `ValueNotifier` system instead of heavy state management frameworks to keep audio pipeline fast.
