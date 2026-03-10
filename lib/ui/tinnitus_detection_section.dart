import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/audio_engine.dart';
import '../storage/detected_frequency_storage.dart';

/// Sweep speed presets (Hz per second).
enum SweepSpeed {
  slow(50),
  medium(200),
  fast(500);

  const SweepSpeed(this.hzPerSecond);
  final double hzPerSecond;
}

/// Milestone 03: Tinnitus frequency detection section.
///
/// Provides coarse and fine frequency search, sweep mode (up/down, adjustable
/// speed, interruptible), and persistent save/load of detected frequency.
/// All control goes through [engine]; does not modify native/FFI directly.
class TinnitusDetectionSection extends StatefulWidget {
  const TinnitusDetectionSection({super.key, required this.engine});

  final AudioEngine? engine;

  @override
  State<TinnitusDetectionSection> createState() =>
      _TinnitusDetectionSectionState();
}

class _TinnitusDetectionSectionState extends State<TinnitusDetectionSection> {
  /// Current frequency used for detection (coarse/fine/sweep). Clamped to valid range.
  final ValueNotifier<double> _detectionFrequency = ValueNotifier(440.0);

  /// Amplitude setting for the detection playback volume.
  final ValueNotifier<double> _amplitude = ValueNotifier(0.3);

  /// Saved frequency loaded from storage; null until first load or if never saved.
  double? _savedFrequency;

  bool _sweepActive = false;
  final ValueNotifier<double> _sweepProgress = ValueNotifier(0.0);
  Timer? _sweepTimer;
  static const int _sweepIntervalMs = 50;

  @override
  void initState() {
    super.initState();
    _detectionFrequency.addListener(_onDetectionFrequencyChanged);
    _loadSavedFrequency();
  }

  @override
  void dispose() {
    _sweepTimer?.cancel();
    _sweepTimer = null;
    _detectionFrequency.removeListener(_onDetectionFrequencyChanged);
    _detectionFrequency.dispose();
    _amplitude.dispose();
    _sweepProgress.dispose();
    super.dispose();
  }

  void _onDetectionFrequencyChanged() {
    final hz = _clamp(_detectionFrequency.value);
    widget.engine?.setFrequency(hz);
  }

  Future<void> _loadSavedFrequency() async {
    final saved = await DetectedFrequencyStorage.loadDetectedFrequency();
    if (saved != null && mounted) {
      setState(() => _savedFrequency = saved);
      // Do not auto-apply to engine here; user taps "Load saved" to apply.
    }
  }

  static double _clamp(double v) {
    if (v < kMinFrequencyHz) return kMinFrequencyHz;
    if (v > kMaxFrequencyHz) return kMaxFrequencyHz;
    return v;
  }

  void _applyFrequency(double hz) {
    final clamped = _clamp(hz);
    _detectionFrequency.value = clamped;
  }

  void _startSweep(bool upward, SweepSpeed speed) {
    if (widget.engine == null || _sweepActive) return;
    _sweepActive = true;
    _sweepProgress.value = 0.0;
    setState(() {});
    final speedValue = speed.hzPerSecond;
    final step = speedValue * (_sweepIntervalMs / 1000.0) * (upward ? 1 : -1);
    final targetHz = upward ? kMaxFrequencyHz : kMinFrequencyHz;
    final startHz = _detectionFrequency.value;
    final totalDiff = (targetHz - startHz).abs();

    _sweepTimer = Timer.periodic(
      const Duration(milliseconds: _sweepIntervalMs),
      (_) {
        if (!mounted) return;
        double next = _detectionFrequency.value + step;
        next = _clamp(next);
        _detectionFrequency.value = next;
        
        if (totalDiff > 0) {
          _sweepProgress.value = ((next - startHz).abs() / totalDiff).clamp(0.0, 1.0);
        }

        if (next <= kMinFrequencyHz || next >= kMaxFrequencyHz) {
          _stopSweep();
          widget.engine?.stop(); // Auto stop playback when detection sweep is completed
        }
      },
    );
  }

  void _stopSweep() {
    _sweepTimer?.cancel();
    _sweepTimer = null;
    _sweepActive = false;
    if (mounted) setState(() {});
  }

  Future<void> _saveDetectedFrequency() async {
    final hz = _clamp(_detectionFrequency.value);
    await DetectedFrequencyStorage.saveDetectedFrequency(hz);
    if (mounted) {
      setState(() => _savedFrequency = hz);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${hz.toStringAsFixed(1)} Hz')),
      );
    }
  }

  void _loadAndApplySaved() async {
    final saved = await DetectedFrequencyStorage.loadDetectedFrequency();
    if (saved != null) {
      _applyFrequency(saved);
      if (mounted) setState(() => _savedFrequency = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text('Tinnitus frequency detection'),
      subtitle: const Text(
        'Coarse / fine search, sweep, save detected frequency',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_savedFrequency != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Saved frequency: ${_savedFrequency!.toStringAsFixed(1)} Hz',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ValueListenableBuilder<double>(
                valueListenable: _detectionFrequency,
                builder: (context, value, _) {
                  return Text(
                    'Current: ${value.toStringAsFixed(1)} Hz',
                    style: Theme.of(context).textTheme.titleMedium,
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Coarse (100 Hz steps)',
                style: TextStyle(fontSize: 12),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _detectionFrequency,
                builder: (context, value, _) {
                  return Slider(
                    value: value.clamp(kMinFrequencyHz, kMaxFrequencyHz),
                    min: kMinFrequencyHz,
                    max: kMaxFrequencyHz,
                    divisions: ((kMaxFrequencyHz - kMinFrequencyHz) / 100)
                        .round()
                        .clamp(1, 500),
                    label: value.toStringAsFixed(0),
                    onChanged: engine == null
                        ? null
                        : (v) => _applyFrequency(v),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text('Volume / Amplitude', style: TextStyle(fontSize: 12)),
              ValueListenableBuilder<double>(
                valueListenable: _amplitude,
                builder: (context, value, _) {
                  return Slider(
                    value: value,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: value.toStringAsFixed(2),
                    onChanged: engine == null
                        ? null
                        : (v) {
                            _amplitude.value = v;
                            engine.setAmplitude(v);
                          },
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text('Fine adjustment & Sweep (Tap: step, Hold: sweep)', style: TextStyle(fontSize: 12)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _SweepButton(
                    icon: const Icon(Icons.keyboard_double_arrow_left, size: 18),
                    label: const Text('-5 Hz'),
                    onTap: engine == null || _sweepActive ? null : () => _applyFrequency(_detectionFrequency.value - 5),
                    onLongPressStart: engine == null || _sweepActive ? null : () => _startSweep(false, SweepSpeed.medium),
                    onLongPressEnd: engine == null ? null : _stopSweep,
                  ),
                  _SweepButton(
                    icon: const Icon(Icons.keyboard_arrow_left, size: 18),
                    label: const Text('-1 Hz'),
                    onTap: engine == null || _sweepActive ? null : () => _applyFrequency(_detectionFrequency.value - 1),
                    onLongPressStart: engine == null || _sweepActive ? null : () => _startSweep(false, SweepSpeed.slow),
                    onLongPressEnd: engine == null ? null : _stopSweep,
                  ),
                  _SweepButton(
                    icon: const Icon(Icons.keyboard_arrow_right, size: 18),
                    label: const Text('+1 Hz'),
                    onTap: engine == null || _sweepActive ? null : () => _applyFrequency(_detectionFrequency.value + 1),
                    onLongPressStart: engine == null || _sweepActive ? null : () => _startSweep(true, SweepSpeed.slow),
                    onLongPressEnd: engine == null ? null : _stopSweep,
                  ),
                  _SweepButton(
                    icon: const Icon(Icons.keyboard_double_arrow_right, size: 18),
                    label: const Text('+5 Hz'),
                    onTap: engine == null || _sweepActive ? null : () => _applyFrequency(_detectionFrequency.value + 5),
                    onLongPressStart: engine == null || _sweepActive ? null : () => _startSweep(true, SweepSpeed.medium),
                    onLongPressEnd: engine == null ? null : _stopSweep,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Auto Sweep', style: TextStyle(fontSize: 12)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: engine == null || _sweepActive ? null : () => _startSweep(false, SweepSpeed.medium),
                    icon: const Icon(Icons.keyboard_double_arrow_left, size: 18),
                    label: const Text('Auto -5 Hz'),
                  ),
                  OutlinedButton.icon(
                    onPressed: engine == null || _sweepActive ? null : () => _startSweep(false, SweepSpeed.slow),
                    icon: const Icon(Icons.keyboard_arrow_left, size: 18),
                    label: const Text('Auto -1 Hz'),
                  ),
                  if (_sweepActive)
                    FilledButton.icon(
                      onPressed: _stopSweep,
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('Stop Auto Sweep'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: engine == null || _sweepActive ? null : () => _startSweep(true, SweepSpeed.slow),
                    icon: const Icon(Icons.keyboard_arrow_right, size: 18),
                    label: const Text('Auto +1 Hz'),
                  ),
                  OutlinedButton.icon(
                    onPressed: engine == null || _sweepActive ? null : () => _startSweep(true, SweepSpeed.medium),
                    icon: const Icon(Icons.keyboard_double_arrow_right, size: 18),
                    label: const Text('Auto +5 Hz'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_sweepActive)
                ValueListenableBuilder<double>(
                  valueListenable: _sweepProgress,
                  builder: (context, progress, _) => LinearProgressIndicator(value: progress, minHeight: 4),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: engine == null ? null : _saveDetectedFrequency,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save as my frequency'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _savedFrequency == null
                        ? null
                        : _loadAndApplySaved,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Load saved'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SweepButton extends StatelessWidget {
  const _SweepButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  final Widget icon;
  final Widget label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPressStart == null ? null : (_) => onLongPressStart!(),
      onLongPressEnd: onLongPressEnd == null ? null : (_) => onLongPressEnd!(),
      onLongPressCancel: onLongPressEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: onTap == null
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(
                color: onTap == null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              child: icon,
            ),
            const SizedBox(width: 8),
            DefaultTextStyle(
              style: TextStyle(
                color: onTap == null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
              child: label,
            ),
          ],
        ),
      ),
    );
  }
}
