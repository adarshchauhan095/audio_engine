/// Phase 3 modulation modules (mutually exclusive per session).
enum Phase3ModuleType {
  rmp,
  pip,
  binaural,
}

/// PIP pulse envelope shape (UI; native PIP uses a smoothed gate).
enum PipPulseShape {
  sine,
  square,
  ramp,
}
