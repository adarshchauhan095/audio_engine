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
  const TinnitusDetectionSection({
    super.key,
    required this.engine,
  });

  final AudioEngine? engine;

  @override
  State<TinnitusDetectionSection> createState() =>
      _TinnitusDetectionSectionState();
}

class _TinnitusDetectionSectionState extends State<TinnitusDetectionSection> {
  /// Current frequency used for detection (coarse/fine/sweep). Clamped to valid range.
  final ValueNotifier<double> _detectionFrequency = ValueNotifier(440.0);

  /// Saved frequency loaded from storage; null until first load or if never saved.
  double? _savedFrequency;

  bool _sweepActive = false;
  SweepSpeed _sweepSpeed = SweepSpeed.medium;
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

  void _startSweep(bool upward) {
    if (widget.engine == null || _sweepActive) return;
    _sweepActive = true;
    setState(() {});
    final speed = _sweepSpeed.hzPerSecond;
    final step = speed * (_sweepIntervalMs / 1000.0) * (upward ? 1 : -1);
    _sweepTimer = Timer.periodic(
      const Duration(milliseconds: _sweepIntervalMs),
      (_) {
        if (!mounted) return;
        double next = _detectionFrequency.value + step;
        next = _clamp(next);
        _detectionFrequency.value = next;
        if (next <= kMinFrequencyHz || next >= kMaxFrequencyHz) {
          _stopSweep();
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
              const Text('Coarse (100 Hz steps)', style: TextStyle(fontSize: 12)),
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
              const SizedBox(height: 8),
              const Text('Fine adjustment', style: TextStyle(fontSize: 12)),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FineButton(
                    label: '-5',
                    onPressed: engine == null
                        ? null
                        : () => _applyFrequency(
                            _detectionFrequency.value - 5),
                  ),
                  _FineButton(
                    label: '-1',
                    onPressed: engine == null
                        ? null
                        : () => _applyFrequency(
                            _detectionFrequency.value - 1),
                  ),
                  _FineButton(
                    label: '+1',
                    onPressed: engine == null
                        ? null
                        : () => _applyFrequency(
                            _detectionFrequency.value + 1),
                  ),
                  _FineButton(
                    label: '+5',
                    onPressed: engine == null
                        ? null
                        : () => _applyFrequency(
                            _detectionFrequency.value + 5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Sweep', style: TextStyle(fontSize: 12)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DropdownButton<SweepSpeed>(
                    value: _sweepSpeed,
                    isExpanded: false,
                    items: SweepSpeed.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            ))
                        .toList(),
                    onChanged: _sweepActive
                        ? null
                        : (v) {
                            if (v != null) setState(() => _sweepSpeed = v);
                          },
                  ),
                  FilledButton.icon(
                    onPressed: engine == null || _sweepActive
                        ? null
                        : () => _startSweep(true),
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    label: const Text('Sweep up'),
                  ),
                  FilledButton.icon(
                    onPressed: engine == null || _sweepActive
                        ? null
                        : () => _startSweep(false),
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    label: const Text('Sweep down'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _sweepActive ? _stopSweep : null,
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('Stop'),
                  ),
                ],
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
                    onPressed: _savedFrequency == null ? null : _loadAndApplySaved,
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

class _FineButton extends StatelessWidget {
  const _FineButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
