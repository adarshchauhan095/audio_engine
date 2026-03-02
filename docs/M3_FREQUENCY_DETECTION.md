# Milestone 03 — Individual Frequency Detection Module

Short technical notes. Full workflow: coarse/fine search → sweep (optional) → save → persists across restarts.

## 1. Scope

User-driven tinnitus frequency detection: coarse localization, fine adjustment, optional sweep, persistent storage. Integrates with existing DSP engine (no native changes). All control via `AudioEngine` API.

## 2. Implemented pieces

- **Persistence**: `lib/storage/detected_frequency_storage.dart` — `saveDetectedFrequency(double)`, `loadDetectedFrequency() -> double?`. Uses `shared_preferences`; key `detected_tinnitus_frequency`. Values clamped to 20–8000 Hz.
- **UI**: `lib/ui/tinnitus_detection_section.dart` — ExpansionTile with:
  - Coarse slider: 20–8000 Hz, 100 Hz steps.
  - Fine buttons: −5, −1, +1, +5 Hz.
  - Sweep: speed (slow/medium/fast), Sweep up, Sweep down, Stop. Timer-based; cancelled on dispose.
  - Save as my frequency, Load saved. Displays “Saved frequency: X Hz” when present.
- **Integration**: `HomeScreen` includes `TinnitusDetectionSection(engine: _engine)`. No changes to existing sliders, M2 tests, or session debug. Sweep timer is cancelled in section `dispose()`.

## 3. Validation

- All frequency values clamped to `kMinFrequencyHz` (20) and `kMaxFrequencyHz` (8000) in storage and in the section before calling `engine.setFrequency()`.
- UI: buttons disabled when engine is null or when appropriate (e.g. speed dropdown during sweep).

## 4. Acceptance checklist (test APK)

- [ ] Coarse slider moves tone in real time; no clicks or pops.
- [ ] Fine +1 / −1 / +5 / −5 update tone smoothly; no artifacts.
- [ ] Sweep up/down runs smoothly; speed change works when sweep stopped; Stop stops immediately and leaves frequency at current value.
- [ ] Save as my frequency: SnackBar confirms; after restart, “Saved frequency: X Hz” appears and Load saved applies that value.
- [ ] No crashes, freezes, or dropouts during rapid or large frequency changes or repeated sweep start/stop.
- [ ] Full workflow: coarse → fine → (optional) sweep → Stop → fine-tune → Save → restart app → Load saved → play tone at saved frequency.
