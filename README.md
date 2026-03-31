# TinnitX Audio Engine (Flutter + Native C++ via FFI)

TinnitX is a sound-based support and self-management platform. This repo contains the Flutter app and the Android native audio engine (C++17 + Oboe) connected via Dart FFI.

The system provides:
- Guided tinnitus pitch matching (AMS)
- A schema-aligned user profile foundation (Phase 6)
- Stimulus configuration generation APIs (Phase 6)
- A time-based sound support session runner built on the native DSP router
- Technical validation tools (debug tests, stress tests, stability checks)

Important: **TinnitX avoids medical claims**. UI strings, logs, and identifiers must not imply “cure/heal/treat/medical therapy/guaranteed improvement”.

## Table of Contents

1. [Current Project Scope](#current-project-scope)
2. [What Is Used in This Project](#what-is-used-in-this-project)
3. [Important vs Non-Important](#important-vs-non-important)
4. [Current App Flow](#current-app-flow)
5. [How Components Are Interconnected](#how-components-are-interconnected)
6. [Key Packages and Documentation](#key-packages-and-documentation)

---

## Current Project Scope

The app provides core tools for tinnitus matching/detection, sound support session execution, and audio generation. It exposes a **dashboard hub** of feature screens through a shared **`AudioRuntimeController`** runtime:

- **Tinnitus Detection:** Highly refined coarse/fine tuning tools with step/sweep behaviors to isolate the user's specific tinnitus frequency.
- **AMS Matching (Adaptive Modulation System):** Guided 3-step pitch matching (Coarse → Fine → Validation) using instant frequency jumps and deterministic engine behavior.
- **Sound Support Sessions:** A time-based session runner (Basic/Standard/Premium presets) built on the native DSP router, with **live preset updates** while a session runs and **PIP timing resets** in native code when interval/duration change.
- **Audio Controls:** Live frequency and amplitude sliders to directly interact with the underlying tone generator.
- **My Profile & Progress:** A fully user-driven TinnitX profile editor (Phase 6) + tracking of total session time (persisted across restarts), live tune parameters, and navigation to **profile sessions** and **saved session parameter** libraries.
- **Debug Tests:** Deep technical tests (rapid parameter checks, stability limits, sequence tests, optional **long-run stability** with configurable duration) for engine validation.
- **Additional entry points:** **Module Demo** (isolated module parameter testing), **Premium Features**, and **Settings**, all sharing the same runtime.

### Phase 6 additions (Terminology + Schema + Engines)
Phase 6 introduces the official terminology and data foundations used by TinnitX across code and future modules:

- **System names (fixed)**:
  - **TinnitX** (platform/app)
  - **AMS** (Adaptive Modulation System, baseline engine)
  - **ANAPS** (Adaptive Neuro‑Acoustic Profiling System, adaptive engine)
- **Schema-aligned models**:
  - `TinnitXUserProfile` (`lib/models/tinnitx_user_profile.dart`)
  - `TinnitXStimulusConfig` (`lib/models/tinnitx_stimulus_config.dart`)
- **Core API functions (roadmap-aligned)**:
  - `generateStimulus(userProfile)` (Phase 1/6)
  - `applyTherapyRules(params)` (Phase 1/6 internal mapping layer; user-facing wording remains neutral)
  - `updateProfileWithFeedback(profile, feedback)` (Phase 3 scaffold)
  - `getCurrentParameters(userId)` (Phase 3 scaffold)

---

## What Is Used in This Project

### UI and App Layer
- **Framework:** Flutter (Material 3) with Dart 3.
- **State Management:** Low-overhead `ValueNotifier` and `ValueListenableBuilder` setup tailored for high-speed audio metrics.

### Native Integration & DSP (Digital Signal Processing)
- **Bridge:** Dart FFI (`dart:ffi`) to a C ABI bridge.
- **DSP Core:** Native C++17 engine code.
- **Audio Output:** Oboe (`com.google.oboe:oboe:1.10.0`) for ultra-low latency, glitch-free Android audio streams.
- **DSP Routing Modules (native):**
    - *Subthreshold Desynchronization* (Base Tone & AM/FM Modulation)
    - *Randomized Micro-Perturbation (RMP)*
    - *Phase-Interruption Patterning (PIP)*
    - *Spectral Sideband Stimulation (SSS)*
    - *Binaural Desynchronization*

### Persistence & Storage
- **Local Storage:** `shared_preferences`
- **Schemas & persistence:**
  - **Detected frequency**: legacy single value (`detected_tinnitus_frequency`)
  - **AMS milestone frequencies**: coarse/fine/final (`ams_*_frequency_hz`)
  - **TinnitXUserProfile (Phase 6)**: schema-aligned JSON stored as `tinnitx_user_profile_v1`
  - **Session parameter sets**: `SessionParams` / `SessionParamsStorage`
  - **Session adherence/progress**: `TherapyAdherenceStorage` persists accumulated total seconds (`therapy_adherence_total_seconds`)

### Phase 6 profile migration (backwards compatible)
On startup, the runtime performs a one-time migration into the schema profile if needed:
- Prefer **AMS final frequency** (if present)
- Else use **detected frequency**
- Else fall back to a conservative default

Migration + storage: `lib/storage/tinnitx_user_profile_storage.dart`

---

## Important vs Non-Important

### Highly Important (Critical Architecture)
- **The FFI Contract:** The `audio_*` symbols and signatures in the Dart/C bridge must be perfectly synchronized.
- **Real-time Safety:** The C++ audio render callback (`onAudioReady`) must NEVER be blocked by mutexes, allocations, or heavy calculations.
- **Parameter Smoothers:** Amplitude and frequency transitions must use one-pole smoothing to prevent acoustic clicks/pops (especially during RMP).
- **The Phase / Parameter Flow:** The timer orchestration in Flutter (`TherapySessionController`) coordinating phase changes (Warm-up → Main Phase → Cool-down) by dynamically injecting new parameters into native code over time, including **`engine.therapyUpdate`** on each tick and **`updatePreset`** for mid-session UI changes without resetting the timer.
- **Stop Ordering:** Stopping a session should **mute transport first** (`engine.stop`) then tear down the routed DSP (`engine.therapyStop`), as implemented in `TherapySessionController.stopSession`.
- **Adherence Integrity:** `totalTherapySeconds` increments while a session runs; `AudioRuntimeController` **debounces** writes to `TherapyAdherenceStorage` and **loads** persisted seconds on engine init so totals survive app restarts.
- **Frequency Clamping:** Ensuring the UI prevents frequencies outside human/device limits from reaching DSP processors (see `AudioRuntimeController.freqMin` / `freqMax`).
- **Terminology consistency (Phase 6):** schema keys and official terms must be used exactly (e.g. `tinnitus_frequency`, `session_feedback`, `generateStimulus(userProfile)`).
- **Wording constraints:** do not introduce “heal/cure/treat/medical therapy” in UI strings, logs, or identifiers.

### Non-Important (Subject to Change)
- **UI Colors/Themes:** Exact color choices, font themes, or visual layouts are secondary to the precision interactions (like the long-press Sweep actions in the Detection screen).
- **Extraneous Screens:** Legacy files or imports not actively reachable from the current `DashboardScreen` navigator paths.
- **Extraneous Android Artifacts:** Any Kotlin `MainActivity` files existing in unused namespaces like `com/example/...` while the active package is `com.audio.audio_engine`.

---

## Current App Flow

### 1. Initialization Core
1. The app starts and launches the **`DashboardScreen`** (`lib/main.dart`).
2. `DashboardScreen` constructs a single **`AudioRuntimeController`** for the whole app session.
3. The controller dynamically loads `libnative_audio.so`, resolves the FFI `NativeBindings`, creates the native engine handle, primes initial DSP states, constructs a **`SessionController`** (general playback / tests) and a **`TherapySessionController`**, registers the native log callback, restores persisted total seconds into `totalTherapySeconds`, listens for changes to schedule debounced saves, and performs a one-time migration into `TinnitXUserProfile` if needed.

### 2. Tinnitus Detection Workflow
1. User opens the **Detection** screen from the dashboard.
2. They use coarse sliders for 100Hz steps and fine Tap (+/- 1Hz & 5Hz) / Hold (Continuous Sweep) buttons to match their tinnitus pitch precisely.
3. Amplitude controls act as an internal control frame, ensuring the tone doesn't overpower the tinnitus.
4. Saving the frequency stores it in SharedPreferences and binds it as the base frequency for future therapy sessions.

### 3. AMS Matching Flow (Adaptive Modulation System)
1. User opens **AMS Matching** from the dashboard.
2. AMS runs a guided state machine:
   - **Coarse**: large steps
   - **Fine**: small steps within a band around the coarse pick
   - **Validation**: micro steps within a band around the fine pick
3. AMS stores milestone values (coarse/fine/final) and saves the final match to:
   - legacy detected frequency storage (for compatibility)
   - the schema-aligned `TinnitXUserProfile.tinnitus_frequency` (Phase 6)

### 4. Sound Support Session Flow
This is the core session runner built on the native DSP router.
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

### 5. Profile Sessions & Saved Parameters (Optional Flows)
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
  adherence persistence, Session snapshots, schema profile migration)
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

---

## Key Packages and Documentation

### Packages
- `shared_preferences`: local persistence (profile, adherence, stored parameters)
- `ffi`: Dart FFI bridge to `libnative_audio.so`
- `audio_session`: Android audio focus/session management for routing recovery

### Internal docs
- `docs/M2_ENGINE_ARCHITECTURE.md`: engine parameter smoothing, thread safety, and API surface
- `docs/M3_FREQUENCY_DETECTION.md`: frequency detection / tuning notes

### Phase 6 naming & schema rules (must follow)
- **Use fixed system names**: `TinnitX`, `AMS`, `ANAPS`
- **Use schema keys exactly** (snake_case): `tinnitus_frequency`, `tinnitus_loudness`, `laterality_mix`, etc.
- **Functions**: `generateStimulus(userProfile)`, `applyTherapyRules(params)`, `updateProfileWithFeedback(profile, feedback)`, `getCurrentParameters(userId)`
- **No medical claims** in UI strings, logs, or identifiers (avoid “cure/heal/treat/medical therapy”)