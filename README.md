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

The app provides core tools for tinnitus detection, therapy session execution, and audio generation. It exposes a **dashboard hub** of feature screens through a shared **`AudioRuntimeController`** runtime:

- **Tinnitus Detection:** Highly refined coarse/fine tuning tools with step/sweep behaviors to isolate the user's specific tinnitus frequency.
- **Adaptive Therapy Sessions:** The core product tiering (Basic, Standard, Premium) allowing users to run adaptive, time-based therapy sessions tailored to their detected frequency, with **live preset updates** while a session runs and **PIP timing resets** in native code when interval/duration change.
- **Audio Controls:** Live frequency and amplitude sliders to directly interact with the underlying tone generator.
- **My Profile & Progress:** Tracking of **total therapy time** (persisted across restarts as **therapy adherence**), live tune parameters, and navigation to **profile sessions** and **saved session parameter** libraries.
- **Debug Tests:** Deep technical tests (rapid parameter checks, stability limits, sequence tests, optional **long-run stability** with configurable duration) for engine validation.
- **Additional entry points:** **Module Demo** (isolated module parameter testing), **Premium Features**, and **Settings**, all sharing the same runtime.

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
- **Schemas:** JSON serialization for detected frequencies, **saved session parameter sets** (`SessionParams` / `SessionParamsStorage`), and **therapy adherence** (`TherapyAdherenceStorage`: accumulated **total therapy seconds** keyed as `therapy_adherence_total_seconds`).

---

## Important vs Non-Important

### Highly Important (Critical Architecture)
- **The FFI Contract:** The `audio_*` symbols and signatures in the Dart/C bridge must be perfectly synchronized.
- **Real-time Safety:** The C++ audio render callback (`onAudioReady`) must NEVER be blocked by mutexes, allocations, or heavy calculations.
- **Parameter Smoothers:** Amplitude and frequency transitions must use one-pole smoothing to prevent acoustic clicks/pops (especially during RMP).
- **The Adaptive Parameter Engine Flow:** The timer orchestration in Flutter (`TherapySessionController`) coordinating phase changes (Warm-up → Main Phase → Cool-down) by dynamically injecting new parameters into C++ over time, including **`engine.therapyUpdate`** on each tick and **`updatePreset`** for mid-session UI changes without resetting the timer.
- **Therapy Stop Ordering:** Stopping a session should **mute transport first** (`engine.stop`) then tear down therapy DSP (`engine.therapyStop`), as implemented in `TherapySessionController.stopSession`.
- **Therapy Adherence Integrity:** `totalTherapySeconds` increments while therapy runs; `AudioRuntimeController` **debounces** writes to `TherapyAdherenceStorage` and **loads** persisted seconds on engine init so totals survive app restarts.
- **Frequency Clamping:** Ensuring the UI prevents frequencies outside human/device limits from reaching DSP processors (see `AudioRuntimeController.freqMin` / `freqMax`).

### Non-Important (Subject to Change)
- **UI Colors/Themes:** Exact color choices, font themes, or visual layouts are secondary to the precision interactions (like the long-press Sweep actions in the Detection screen).
- **Extraneous Screens:** Legacy files or imports not actively reachable from the current `DashboardScreen` navigator paths.
- **Extraneous Android Artifacts:** Any Kotlin `MainActivity` files existing in unused namespaces like `com/example/...` while the active package is `com.audio.audio_engine`.

---

## Current App Flow

### 1. Initialization Core
1. The app starts and launches the **`DashboardScreen`** (`lib/main.dart`).
2. `DashboardScreen` constructs a single **`AudioRuntimeController`** for the whole app session.
3. The controller dynamically loads `libnative_audio.so`, resolves the FFI `NativeBindings`, creates the native engine handle, primes initial DSP states, constructs a **`SessionController`** (general playback / tests) and a **`TherapySessionController`**, registers the native log callback, **restores** persisted **therapy adherence** into `totalTherapySeconds`, and listens for changes to schedule **debounced** saves.

### 2. Tinnitus Detection Workflow
1. User opens the **Detection** screen from the dashboard.
2. They use coarse sliders for 100Hz steps and fine Tap (+/- 1Hz & 5Hz) / Hold (Continuous Sweep) buttons to match their tinnitus pitch precisely.
3. Amplitude controls act as an internal control frame, ensuring the tone doesn't overpower the tinnitus.
4. Saving the frequency stores it in SharedPreferences and binds it as the base frequency for future therapy sessions.

### 3. Adaptive Therapy Session Flow
This is the core therapeutic process using the architecture built in Milestone 4.
1. User selects a **Profile Preset** (Basic, Standard, Premium) and may adjust **editable** parameters vs **preset-derived** shaping parameters on **`TherapySessionScreen`**.
2. User chooses a total **Duration** (minutes → seconds internally).
3. The `TherapySessionController` creates a schedule: **20% Warm-up**, **60% Main Phase**, **20% Cool-down**.
4. Execution:
    - **Warm-up:** The `TherapyRouter` (C++) starts. Flutter runs a periodic tick (e.g. ~200ms), ramping intensity safely from `0%` to the configured max.
    - **Main Phase:** The `TherapyRouter` invokes the specific modules (RMP jitter, PIP interruptions, Sideband generation, Binaural offsets) at full force based on the chosen Product Tier. In **`TherapyRouter`**, if PIP stays enabled but **interval or duration** change, the PIP module **resets** so timing stays coherent.
    - **Cool-down:** Flutter gracefully decays the intensity back to zero over the final phase.
5. While running, **`totalTherapySeconds`** accumulates (and is **persisted** debounced). **`SessionRunSnapshot`** (via `AudioRuntimeController`) exposes **elapsed / remaining / progress** for profile-session style UIs.
6. **Live preset changes:** `TherapySessionController.updatePreset(...)` updates stored targets and immediately calls `engine.therapyUpdate(...)` using the **current phase’s intensity curve** so the timer is uninterrupted.
7. Stop / completion: **`stopSession`** cancels timers, sets phase to idle, calls **`engine.stop()`** then **`engine.therapyStop()`**. Natural completion follows the same stop path when the countdown ends.

### 4. Profile Sessions & Saved Parameters (Optional Flows)
1. From **My Profile**, users can open **profile sessions** (catalog-driven templates) and **saved session parameters** for reusable configurations.
2. **`SessionController`** drives timed **`SessionParams`** runs and exposes **`runLongRunStabilityTest`** with an optional **`durationSeconds`** override for extended soak testing (surfaced from **Debug Tests** and legacy helpers like **`HomeScreen`** if present).

---

## How Components Are Interconnected

The architecture follows a strict one-way control flow from the Flutter UI down into the C++ DSP core.

```text
Flutter UI & User Interaction (DashboardScreen → feature Screens)
   │
   ▼
AudioRuntimeController & Session Controllers (State tracking, Timers, Phase Logic,
  Therapy adherence persistence, Session snapshots)
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