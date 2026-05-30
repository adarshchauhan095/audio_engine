import 'dart:async';

import 'package:flutter/foundation.dart';

/// DateTime-based countdown for flow and step boundaries (no drift).
class FlowTimer {
  FlowTimer({
    required this.onTick,
  });

  final void Function() onTick;

  final ValueNotifier<int> globalRemainingSeconds = ValueNotifier<int>(0);
  final ValueNotifier<int> stepRemainingSeconds = ValueNotifier<int>(0);

  DateTime? _globalEndsAt;
  DateTime? _stepEndsAt;
  Timer? _ticker;
  bool _disposed = false;

  void start({
    required DateTime globalEndsAt,
    required DateTime stepEndsAt,
  }) {
    _globalEndsAt = globalEndsAt;
    _stepEndsAt = stepEndsAt;
    _ticker?.cancel();
    _publish();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _publish());
  }

  void setStepEndsAt(DateTime stepEndsAt) {
    _stepEndsAt = stepEndsAt;
    _publish();
  }

  void _publish() {
    if (_disposed) return;
    final DateTime now = DateTime.now();
    globalRemainingSeconds.value = _remainingSeconds(now, _globalEndsAt);
    stepRemainingSeconds.value = _remainingSeconds(now, _stepEndsAt);
    onTick();
  }

  int _remainingSeconds(DateTime now, DateTime? endsAt) {
    if (endsAt == null) return 0;
    final int ms = endsAt.difference(now).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / 1000).ceil();
  }

  bool get isStepElapsed {
    final DateTime? ends = _stepEndsAt;
    if (ends == null) return false;
    return !DateTime.now().isBefore(ends);
  }

  bool get isGlobalElapsed {
    final DateTime? ends = _globalEndsAt;
    if (ends == null) return false;
    return !DateTime.now().isBefore(ends);
  }

  void stop() {
    _ticker?.cancel();
    _globalEndsAt = null;
    _stepEndsAt = null;
    globalRemainingSeconds.value = 0;
    stepRemainingSeconds.value = 0;
  }

  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    globalRemainingSeconds.dispose();
    stepRemainingSeconds.dispose();
  }
}
