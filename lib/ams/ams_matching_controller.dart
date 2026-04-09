import 'dart:async';

import 'package:flutter/foundation.dart';

import '../session/audio_runtime_controller.dart';
import '../storage/ams_matching_storage.dart';
import '../storage/detected_frequency_storage.dart';
import '../storage/tinnitx_user_profile_storage.dart';

/// Distinct AMS UI / engine states (one screen per phase after start).
enum AmsPhase {
  start,
  coarse,
  fine,
  validation,
  result,
}

/// State machine for guided tinnitus frequency matching (AMS).
///
/// Frequency jumps are applied via [AudioRuntimeController.setFrequency] for
/// deterministic, engine-wide state. Coarse uses large steps; fine uses small
/// steps within a band around the coarse pick; validation uses micro steps
/// around the fine pick.
class AmsMatchingController extends ChangeNotifier {
  AmsMatchingController(this._runtime);

  final AudioRuntimeController _runtime;

  AmsPhase _phase = AmsPhase.start;

  /// Starting point for coarse matching (Hz).
  static const double initialFrequencyHz = 4000.0;

  static const double coarseStepHz = 100.0;
  static const double fineStepHz = 5.0;
  static const double microStepHz = 1.0;

  /// Fine matching stays within ± this width (Hz) of the stored coarse frequency.
  ///
  /// In the adaptive implementation, this is the *maximum* width; the actual
  /// width shrinks based on how wide the user explored in the previous stage.
  static const double fineBandHalfWidthHz = 100.0;

  /// Validation micro-adjustments stay within ± this width (Hz) of the fine pick.
  ///
  /// In the adaptive implementation, this is the *maximum* width; the actual
  /// width shrinks based on how wide the user explored in the previous stage.
  static const double validationBandHalfWidthHz = 25.0;

  /// Adaptive minimum widths (so the band never collapses to nothing).
  static const double fineBandHalfWidthMinHz = 10.0;
  static const double validationBandHalfWidthMinHz = 5.0;

  /// Current adaptive band widths (updated on confirm transitions).
  double _fineBandHalfWidthCurrentHz = fineBandHalfWidthHz;
  double _validationBandHalfWidthCurrentHz = validationBandHalfWidthHz;

  double _currentHz = initialFrequencyHz;

  double? _coarseHz;
  double? _fineHz;
  double? _finalHz;

  Timer? _sweepTimer;
  double _sweepDirection = 0.0; // +1 higher, -1 lower
  DateTime? _lastSweepTickAt;

  /// Throttle `notifyListeners()` during continuous sweeps.
  DateTime? _lastUiNotifyAt;
  double? _lastNotifiedHz;

  /// Adaptive exploration tracking.
  double? _coarseVisitMinHz;
  double? _coarseVisitMaxHz;
  double? _fineVisitMinHz;
  double? _fineVisitMaxHz;

  /// Sweeping tick-rate and continuity tuning.
  /// Higher tick rate => smoother ramp.
  static const int _sweepTickMs = 16; // ~60 Hz

  /// How fast the ramp should move relative to the stage step size.
  /// Speed (Hz/sec) = stageStepHz * thisValue
  static const double _sweepStepsPerSecond = 4.0;

  AmsPhase get phase => _phase;
  double get currentHz => _currentHz;
  double? get coarseFrequency => _coarseHz;
  double? get fineFrequency => _fineHz;
  double? get finalFrequency => _finalHz;

  double _globalMin() => AudioRuntimeController.freqMin;
  double _globalMax() => AudioRuntimeController.freqMax;

  void _emitFrequency(double hz) {
    final double g = hz.clamp(_globalMin(), _globalMax());
    _currentHz = g;
    _trackVisitedForAdaptiveNarrowing(g);
    _runtime.setFrequency(g);

    final DateTime now = DateTime.now();
    const int uiNotifyTickMs = 50; // ~20fps
    const double uiNotifyMinHzDelta = 0.25;
    final bool shouldNotify = _lastUiNotifyAt == null ||
        now.difference(_lastUiNotifyAt!).inMilliseconds >= uiNotifyTickMs ||
        _lastNotifiedHz == null ||
        (g - _lastNotifiedHz!).abs() >= uiNotifyMinHzDelta;

    if (shouldNotify) {
      _lastUiNotifyAt = now;
      _lastNotifiedHz = g;
      notifyListeners();
    }
  }

  void _trackVisitedForAdaptiveNarrowing(double hz) {
    if (_phase == AmsPhase.coarse) {
      _coarseVisitMinHz = (_coarseVisitMinHz == null) ? hz : hz < _coarseVisitMinHz! ? hz : _coarseVisitMinHz;
      _coarseVisitMaxHz = (_coarseVisitMaxHz == null) ? hz : hz > _coarseVisitMaxHz! ? hz : _coarseVisitMaxHz;
    } else if (_phase == AmsPhase.fine) {
      _fineVisitMinHz = (_fineVisitMinHz == null) ? hz : hz < _fineVisitMinHz! ? hz : _fineVisitMinHz;
      _fineVisitMaxHz = (_fineVisitMaxHz == null) ? hz : hz > _fineVisitMaxHz! ? hz : _fineVisitMaxHz;
    }
  }

  double _fineLow() {
    final double c = _coarseHz ?? _currentHz;
    return (c - _fineBandHalfWidthCurrentHz).clamp(_globalMin(), _globalMax());
  }

  double _fineHigh() {
    final double c = _coarseHz ?? _currentHz;
    return (c + _fineBandHalfWidthCurrentHz).clamp(_globalMin(), _globalMax());
  }

  double _validationLow() {
    final double f = _fineHz ?? _currentHz;
    return (f - _validationBandHalfWidthCurrentHz).clamp(_globalMin(), _globalMax());
  }

  double _validationHigh() {
    final double f = _fineHz ?? _currentHz;
    return (f + _validationBandHalfWidthCurrentHz).clamp(_globalMin(), _globalMax());
  }

  double _computeAdaptiveHalfWidth({
    required double exploredMinHz,
    required double exploredMaxHz,
    required double defaultMaxHalfWidthHz,
    required double minHalfWidthHz,
  }) {
    final double range = (exploredMaxHz - exploredMinHz).abs();
    final double half = range * 0.5;
    if (half <= 0.0) return minHalfWidthHz;
    return half.clamp(minHalfWidthHz, defaultMaxHalfWidthHz);
  }

  /// Clears module state and primes engine for a new AMS run.
  Future<void> beginMatching() async {
    _coarseHz = null;
    _fineHz = null;
    _finalHz = null;
    _fineBandHalfWidthCurrentHz = fineBandHalfWidthHz;
    _validationBandHalfWidthCurrentHz = validationBandHalfWidthHz;
    _coarseVisitMinHz = null;
    _coarseVisitMaxHz = null;
    _fineVisitMinHz = null;
    _fineVisitMaxHz = null;
    _sweepDirection = 0.0;
    _lastSweepTickAt = null;
    _lastUiNotifyAt = null;
    _lastNotifiedHz = null;
    _phase = AmsPhase.coarse;
    _runtime.prepareForAmsMatching();
    _emitFrequency(initialFrequencyHz);
    if (!_runtime.playing.value) {
      _runtime.togglePlay();
    }
    await AmsMatchingStorage.clearSession();
  }

  void higher() {
    if (_sweepTimer != null) stopSweeping();
    switch (_phase) {
      case AmsPhase.coarse:
        _emitFrequency(_currentHz + coarseStepHz);
        break;
      case AmsPhase.fine:
        _emitFrequency(
          (_currentHz + fineStepHz).clamp(_fineLow(), _fineHigh()),
        );
        break;
      case AmsPhase.validation:
        _emitFrequency(
          (_currentHz + microStepHz).clamp(_validationLow(), _validationHigh()),
        );
        break;
      default:
        break;
    }
  }

  void lower() {
    if (_sweepTimer != null) stopSweeping();
    switch (_phase) {
      case AmsPhase.coarse:
        _emitFrequency(_currentHz - coarseStepHz);
        break;
      case AmsPhase.fine:
        _emitFrequency(
          (_currentHz - fineStepHz).clamp(_fineLow(), _fineHigh()),
        );
        break;
      case AmsPhase.validation:
        _emitFrequency(
          (_currentHz - microStepHz).clamp(_validationLow(), _validationHigh()),
        );
        break;
      default:
        break;
    }
  }

  void startSweepingHigher() {
    _startSweeping(direction: 1.0);
  }

  void startSweepingLower() {
    _startSweeping(direction: -1.0);
  }

  void stopSweeping() {
    _sweepTimer?.cancel();
    _sweepTimer = null;
    _sweepDirection = 0.0;
    _lastSweepTickAt = null;
  }

  void _startSweeping({required double direction}) {
    stopSweeping();
    if (_phase != AmsPhase.coarse && _phase != AmsPhase.fine && _phase != AmsPhase.validation) {
      return;
    }

    _sweepDirection = direction;
    _lastSweepTickAt = DateTime.now();

    // Immediate tiny ramp so the user hears feedback right away.
    _sweepTick();
    _sweepTimer = Timer.periodic(
      const Duration(milliseconds: _sweepTickMs),
      (_) => _sweepTick(),
    );
  }

  void _sweepTick() {
    if (_sweepDirection == 0.0) return;

    final DateTime now = DateTime.now();
    final DateTime? last = _lastSweepTickAt;
    _lastSweepTickAt = now;

    final double dtSec = last == null
        ? (_sweepTickMs / 1000.0)
        : now.difference(last).inMicroseconds / 1e6;
    // Defensive clamp: prevents large jumps after scheduling delays.
    final double safeDtSec = dtSec.clamp(0.0, _sweepTickMs / 1000.0 * 2.0);

    double stageStepHz = switch (_phase) {
      AmsPhase.coarse => coarseStepHz,
      AmsPhase.fine => fineStepHz,
      AmsPhase.validation => microStepHz,
      _ => coarseStepHz,
    };

    final double speedHzPerSec = stageStepHz * _sweepStepsPerSecond;
    final double deltaHz = _sweepDirection * speedHzPerSec * safeDtSec;

    final double low = switch (_phase) {
      AmsPhase.coarse => _globalMin(),
      AmsPhase.fine => _fineLow(),
      AmsPhase.validation => _validationLow(),
      _ => _globalMin(),
    };
    final double high = switch (_phase) {
      AmsPhase.coarse => _globalMax(),
      AmsPhase.fine => _fineHigh(),
      AmsPhase.validation => _validationHigh(),
      _ => _globalMax(),
    };

    final double next = (_currentHz + deltaHz).clamp(low, high);
    _emitFrequency(next);

    // If we hit a boundary, stop the ramp until the user changes direction
    // or releases/re-presses Hold.
    const double eps = 0.0001;
    if ((_sweepDirection < 0.0 && next <= low + eps) ||
        (_sweepDirection > 0.0 && next >= high - eps)) {
      stopSweeping();
    }
  }

  void resetPhase() {
    stopSweeping();
    stopPlaybackIfOwned();
    _coarseHz = null;
    _fineHz = null;
    _finalHz = null;
    _fineBandHalfWidthCurrentHz = fineBandHalfWidthHz;
    _validationBandHalfWidthCurrentHz = validationBandHalfWidthHz;
    _coarseVisitMinHz = null;
    _coarseVisitMaxHz = null;
    _fineVisitMinHz = null;
    _fineVisitMaxHz = null;
    // Restart should clear persisted AMS milestone values too.
    unawaited(AmsMatchingStorage.clearSession());
    _phase = AmsPhase.start;
    _lastUiNotifyAt = null;
    _lastNotifiedHz = null;
    _emitFrequency(initialFrequencyHz);
    notifyListeners();
  }

  /// Coarse OK → store coarse frequency, enter fine matching.
  Future<void> confirmCoarse() async {
    if (_phase != AmsPhase.coarse) return;
    _coarseHz = _currentHz;
    if (_coarseVisitMinHz != null && _coarseVisitMaxHz != null) {
      _fineBandHalfWidthCurrentHz = _computeAdaptiveHalfWidth(
        exploredMinHz: _coarseVisitMinHz!,
        exploredMaxHz: _coarseVisitMaxHz!,
        defaultMaxHalfWidthHz: fineBandHalfWidthHz,
        minHalfWidthHz: fineBandHalfWidthMinHz,
      );
    } else {
      _fineBandHalfWidthCurrentHz = fineBandHalfWidthHz;
    }
    await AmsMatchingStorage.saveCoarseFrequency(_coarseHz!);
    _phase = AmsPhase.fine;
    _fineVisitMinHz = _currentHz;
    _fineVisitMaxHz = _currentHz;
    _emitFrequency(_currentHz.clamp(_fineLow(), _fineHigh()));
  }

  /// Fine OK → store fine frequency, enter validation.
  Future<void> confirmFine() async {
    if (_phase != AmsPhase.fine) return;
    _fineHz = _currentHz;
    if (_fineVisitMinHz != null && _fineVisitMaxHz != null) {
      _validationBandHalfWidthCurrentHz = _computeAdaptiveHalfWidth(
        exploredMinHz: _fineVisitMinHz!,
        exploredMaxHz: _fineVisitMaxHz!,
        defaultMaxHalfWidthHz: validationBandHalfWidthHz,
        minHalfWidthHz: validationBandHalfWidthMinHz,
      );
    } else {
      _validationBandHalfWidthCurrentHz = validationBandHalfWidthHz;
    }
    await AmsMatchingStorage.saveFineFrequency(_fineHz!);
    _phase = AmsPhase.validation;
    _emitFrequency(_currentHz.clamp(_validationLow(), _validationHigh()));
  }

  /// Validation confirm → store final frequency, show result.
  Future<void> confirmValidation() async {
    if (_phase != AmsPhase.validation) return;
    _finalHz = _currentHz;
    await AmsMatchingStorage.saveFinalFrequency(_finalHz!);
    _phase = AmsPhase.result;
    stopPlaybackIfOwned();
    notifyListeners();
  }

  /// Writes the matched frequency to the app-wide detected frequency store.
  Future<bool> saveAndContinue() async {
    if (_finalHz == null) return false;
    final double hz = _finalHz!;
    final bool ok = await DetectedFrequencyStorage.saveDetectedFrequency(hz);
    if (!ok) return false;

    // Keep the schema-aligned profile in sync with the latest AMS match.
    const String userId = 'local_user';
    final profile = await TinnitXUserProfileStorage.getOrCreateMinimal(
      userId: userId,
    );
    await TinnitXUserProfileStorage.saveProfile(
      profile.copyWith(tinnitusFrequency: hz),
    );
    return true;
  }

  /// Stops AMS tone when leaving the flow (does not alter other modules).
  void stopPlaybackIfOwned() {
    if (_runtime.playing.value) {
      _runtime.stopPlayback();
    }
  }

  @override
  void dispose() {
    stopSweeping();
    super.dispose();
  }
}
