# Milestone 02 — Engine Architecture & Core Parameter System

Short technical notes on the engine structure. No long documentation.

## 1. Layer separation

- **DSP core**: `Oscillator` (sine, frequency-smoothed), `ParameterSmoother` (one-pole ramps). All run in the audio callback; no mutex in the callback.
- **Parameter layer**: Atomic targets (`amplitudeTarget_`, frequency target in Oscillator, transport target). UI writes atomics; audio thread reads and applies ramps sample-accurately.
- **UI bindings**: Flutter `HomeScreen` + sliders call only `AudioEngine` (setAmplitude, setFrequency, start, stop). No direct FFI or native access from UI.

## 2. Parameter update system

- **Sample-accurate, ramp-based**: Amplitude and transport use `ParameterSmoother`: each `process()` advances one sample toward the current target. Frequency uses an internal one-pole smoother in `Oscillator` (same style).
- **No artifacts on rapid changes**: Sliders can be moved quickly; ramps avoid zipper noise and clicks.
- **Thread-safe UI ↔ DSP**: UI calls FFI setters; native stores to atomics; audio thread only reads atomics and runs smoothers. No locks in the callback.

## 3. Frequency control module

- **Real-time frequency**: `Oscillator::setFrequency(hz)` sets an atomic target; in `process()` the frequency is smoothed (≈3 ms) and used for phase increment. Phase stays continuous, so no clicks on large jumps.
- **Stable under extreme values**: Frequency target is not clamped; phase wraps in [0, 2π). Safe for future tinnitus frequency detection using the same API.

## 4. Start/stop system

- **Smooth fades**: Start ramps transport gain to 1 (≈20 ms); stop ramps to 0. Stream is kept open to avoid HAL route changes and pops.
- **Engine state**: `isRunning` is true after a successful `start()`, false after `stop()`. UI can sync with `AudioEngine.isRunning` if desired.

## 5. Unified API surface (Dart)

- **Amplitude**: `setAmplitude(double)` — ramp-smoothed.
- **Frequency**: `setFrequency(double)` — smoothed in native.
- **Start/stop**: `start()`, `stop()` — transport ramps; stream stays open.
- **Engine state**: `isRunning` — reflects Running / Stopped.

All of the above are on `AudioEngine`; ready for Milestone 03 (e.g. tinnitus detection) to use the same API.

---

## 6. How to verify each deliverable (test APK)

- **Modular structure**: UI only uses `AudioEngine` (no `NativeBindings`/FFI in UI). Grep for `NativeBindings` outside `lib/engine/` and entrypoint to confirm.
- **Parameter updates**: Play tone; move amplitude and frequency sliders rapidly for 10+ seconds. Listen for no clicks or zipper noise.
- **Frequency module**: Play; jump frequency between 200 Hz and 4000 Hz repeatedly. No clicks. Set 20 Hz and 8000 Hz; no crash.
- **Start/stop**: Start → wait 1 s → stop → wait 1 s; repeat 10+ times. No pops at transitions.
- **Engine state**: After stop, audio is silent; after start, audio plays. Optional: read `AudioEngine.isRunning` to confirm it matches.
- **Stability**: Use the **Milestone 02 tests** panel: **Rapid params** (2 s of rapid changes), **Start/stop x10**, **Extreme values**. App must stay stable (no crash, no stuck state).
