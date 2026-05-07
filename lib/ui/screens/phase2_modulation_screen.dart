import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';
import '../../session/phase2_demo_controller.dart';

class Phase2ModulationScreen extends StatefulWidget {
  const Phase2ModulationScreen({super.key, required this.runtime});
  final AudioRuntimeController runtime;

  @override
  State<Phase2ModulationScreen> createState() => _Phase2ModulationScreenState();
}

class _Phase2ModulationScreenState extends State<Phase2ModulationScreen> {
  late final Phase2DemoController _demo;

  bool _running = false;

  // Modulation
  int _modulationType = 0; // 0 bypass, 1 AM, 2 FM, 3 NBN
  double _depth = 0.3;
  double _rateHz = 4.0;
  double _bandwidthHz = 500.0; // for NBN (optional; 0 disables)

  // Filter
  int _filterType = 0; // 0 bypass, 1 LP, 2 HP, 3 BP
  double _filterFreqHz = 6000.0;
  double _q = 1.0;

  // Master
  double _intensity = 0.5;
  double _transitionMs = 100.0;

  @override
  void initState() {
    super.initState();
    widget.runtime.prepareForEngineExperiments();
    _demo = Phase2DemoController(widget.runtime);
  }

  Future<void> _toggle() async {
    if (!widget.runtime.hasEngine) return;
    if (_running) {
      setState(() => _running = false);
      await _demo.stop(
        modulationType: _modulationType,
        filterType: _filterType,
        intensity: _intensity,
        baseFreq: widget.runtime.frequency.value,
        baseAmp: widget.runtime.amplitude.value,
        depth: _depth,
        rateHz: _rateHz,
        bandwidthHz: _bandwidthHz,
        filterFreqHz: _filterFreqHz,
        q: _q,
        transitionMs: _transitionMs,
      );
    } else {
      setState(() => _running = true);
      await _demo.start(
        modulationType: _modulationType,
        filterType: _filterType,
        intensity: _intensity,
        baseFreq: widget.runtime.frequency.value,
        baseAmp: widget.runtime.amplitude.value,
        depth: _depth,
        rateHz: _rateHz,
        bandwidthHz: _bandwidthHz,
        filterFreqHz: _filterFreqHz,
        q: _q,
        transitionMs: _transitionMs,
      );
    }
  }

  Future<void> _update({
    required int oldModulationType,
    required int oldFilterType,
    required double oldIntensity,
    required double oldBaseFreq,
    required double oldBaseAmp,
    required double oldDepth,
    required double oldRateHz,
    required double oldBandwidthHz,
    required double oldFilterFreqHz,
    required double oldQ,
    required double oldTransitionMs,
  }) async {
    if (!_running) return;
    await _demo.update(
      oldModulationType: oldModulationType,
      oldFilterType: oldFilterType,
      oldIntensity: oldIntensity,
      oldBaseFreq: oldBaseFreq,
      oldBaseAmp: oldBaseAmp,
      oldDepth: oldDepth,
      oldRateHz: oldRateHz,
      oldBandwidthHz: oldBandwidthHz,
      oldFilterFreqHz: oldFilterFreqHz,
      oldQ: oldQ,
      oldTransitionMs: oldTransitionMs,
      modulationType: _modulationType,
      filterType: _filterType,
      intensity: _intensity,
      baseFreq: widget.runtime.frequency.value,
      baseAmp: widget.runtime.amplitude.value,
      depth: _depth,
      rateHz: _rateHz,
      bandwidthHz: _bandwidthHz,
      filterFreqHz: _filterFreqHz,
      q: _q,
      transitionMs: _transitionMs,
    );
  }

  @override
  void deactivate() {
    if (_running) {
      _demo.dispose();
      widget.runtime.engine?.phase2Stop();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = widget.runtime;
    final double baseFreq = runtime.frequency.value;
    final double baseAmp = runtime.amplitude.value;
    final double derivedQ =
        _bandwidthHz <= 0 ? _q : (baseFreq / _bandwidthHz).clamp(0.3, 40.0);
    final double derivedBw =
        _q <= 0 ? 0.0 : (baseFreq / _q).clamp(1.0, 20000.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Phase 2 — Modulation Lab')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Isolated AM/FM/NBN + filters playground. Uses the current engine base frequency/amplitude as carrier/center.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: runtime.hasEngine ? _toggle : null,
                      icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                      label: Text(_running ? 'Stop Phase 2' : 'Start Phase 2'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _running ? Colors.red.shade100 : null,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Carrier/Center: ${baseFreq.toStringAsFixed(1)} Hz   Base amp: ${baseAmp.toStringAsFixed(3)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _sectionTitle(context, 'Modulation'),
            _dropdown(
              context,
              label: 'Type',
              value: _modulationType,
              items: const [
                (0, 'Pure (Bypass)'),
                (1, 'AM (Amplitude Modulation)'),
                (2, 'FM (Frequency Modulation)'),
                (3, 'NBN (Narrow Band Noise)'),
              ],
              onChanged: (v) async {
                final oldMod = _modulationType;
                setState(() => _modulationType = v);
                await _update(
                  oldModulationType: oldMod,
                  oldFilterType: _filterType,
                  oldIntensity: _intensity,
                  oldBaseFreq: baseFreq,
                  oldBaseAmp: baseAmp,
                  oldDepth: _depth,
                  oldRateHz: _rateHz,
                  oldBandwidthHz: _bandwidthHz,
                  oldFilterFreqHz: _filterFreqHz,
                  oldQ: _q,
                  oldTransitionMs: _transitionMs,
                );
              },
            ),
            _slider(
              context,
              label: 'Depth',
              value: _depth,
              min: 0.0,
              max: 1.0,
              valueLabel: _depth.toStringAsFixed(2),
              onChanged: (v) async {
                final old = _depth;
                setState(() => _depth = v);
                await _update(
                  oldModulationType: _modulationType,
                  oldFilterType: _filterType,
                  oldIntensity: _intensity,
                  oldBaseFreq: baseFreq,
                  oldBaseAmp: baseAmp,
                  oldDepth: old,
                  oldRateHz: _rateHz,
                  oldBandwidthHz: _bandwidthHz,
                  oldFilterFreqHz: _filterFreqHz,
                  oldQ: _q,
                  oldTransitionMs: _transitionMs,
                );
              },
            ),
            _slider(
              context,
              label: 'Rate (Hz)',
              value: _rateHz,
              min: 0.1,
              max: 20.0,
              valueLabel: _rateHz.toStringAsFixed(1),
              onChanged: (v) async {
                final old = _rateHz;
                setState(() => _rateHz = v);
                await _update(
                  oldModulationType: _modulationType,
                  oldFilterType: _filterType,
                  oldIntensity: _intensity,
                  oldBaseFreq: baseFreq,
                  oldBaseAmp: baseAmp,
                  oldDepth: _depth,
                  oldRateHz: old,
                  oldBandwidthHz: _bandwidthHz,
                  oldFilterFreqHz: _filterFreqHz,
                  oldQ: _q,
                  oldTransitionMs: _transitionMs,
                );
              },
            ),
            if (_modulationType == 3) ...[
              _slider(
                context,
                label: 'NBN bandwidth (Hz)',
                value: _bandwidthHz,
                min: 50.0,
                max: 4000.0,
                valueLabel: _bandwidthHz.toStringAsFixed(0),
                onChanged: (v) async {
                  final old = _bandwidthHz;
                  setState(() => _bandwidthHz = v);
                  await _update(
                    oldModulationType: _modulationType,
                    oldFilterType: _filterType,
                    oldIntensity: _intensity,
                    oldBaseFreq: baseFreq,
                    oldBaseAmp: baseAmp,
                    oldDepth: _depth,
                    oldRateHz: _rateHz,
                    oldBandwidthHz: old,
                    oldFilterFreqHz: _filterFreqHz,
                    oldQ: _q,
                    oldTransitionMs: _transitionMs,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Derived Q (center/bandwidth): ${derivedQ.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'FM deviation mapping: depth × min(500 Hz, 5% of carrier).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],

            const SizedBox(height: 12),
            _sectionTitle(context, 'Filter (post stage)'),
            _dropdown(
              context,
              label: 'Type',
              value: _filterType,
              items: const [
                (0, 'Bypass'),
                (1, 'LP (Low-pass)'),
                (2, 'HP (High-pass)'),
                (3, 'BP (Band-pass)'),
              ],
              onChanged: (v) async {
                final oldFilter = _filterType;
                setState(() => _filterType = v);
                await _update(
                  oldModulationType: _modulationType,
                  oldFilterType: oldFilter,
                  oldIntensity: _intensity,
                  oldBaseFreq: baseFreq,
                  oldBaseAmp: baseAmp,
                  oldDepth: _depth,
                  oldRateHz: _rateHz,
                  oldBandwidthHz: _bandwidthHz,
                  oldFilterFreqHz: _filterFreqHz,
                  oldQ: _q,
                  oldTransitionMs: _transitionMs,
                );
              },
            ),
            _slider(
              context,
              label: _filterType == 3 ? 'BP center (Hz)' : 'Cutoff (Hz)',
              value: _filterFreqHz,
              min: 50.0,
              max: 16000.0,
              valueLabel: _filterFreqHz.toStringAsFixed(0),
              onChanged: (v) async {
                final old = _filterFreqHz;
                setState(() => _filterFreqHz = v);
                await _update(
                  oldModulationType: _modulationType,
                  oldFilterType: _filterType,
                  oldIntensity: _intensity,
                  oldBaseFreq: baseFreq,
                  oldBaseAmp: baseAmp,
                  oldDepth: _depth,
                  oldRateHz: _rateHz,
                  oldBandwidthHz: _bandwidthHz,
                  oldFilterFreqHz: old,
                  oldQ: _q,
                  oldTransitionMs: _transitionMs,
                );
              },
            ),
            _slider(
              context,
              label: 'Q',
              value: _q,
              min: 0.3,
              max: 20.0,
              valueLabel: _q.toStringAsFixed(2),
              onChanged: (v) async {
                final old = _q;
                setState(() => _q = v);
                await _update(
                  oldModulationType: _modulationType,
                  oldFilterType: _filterType,
                  oldIntensity: _intensity,
                  oldBaseFreq: baseFreq,
                  oldBaseAmp: baseAmp,
                  oldDepth: _depth,
                  oldRateHz: _rateHz,
                  oldBandwidthHz: _bandwidthHz,
                  oldFilterFreqHz: _filterFreqHz,
                  oldQ: old,
                  oldTransitionMs: _transitionMs,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'If you want a specific bandwidth, use BW ≈ center/Q. Current BW ≈ ${derivedBw.toStringAsFixed(0)} Hz.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: 12),
            _sectionTitle(context, 'Master'),
            _slider(
              context,
              label: 'Intensity',
              value: _intensity,
              min: 0.0,
              max: 1.0,
              valueLabel: _intensity.toStringAsFixed(2),
              onChanged: (v) async {
                final old = _intensity;
                setState(() => _intensity = v);
                await _update(
                  oldModulationType: _modulationType,
                  oldFilterType: _filterType,
                  oldIntensity: old,
                  oldBaseFreq: baseFreq,
                  oldBaseAmp: baseAmp,
                  oldDepth: _depth,
                  oldRateHz: _rateHz,
                  oldBandwidthHz: _bandwidthHz,
                  oldFilterFreqHz: _filterFreqHz,
                  oldQ: _q,
                  oldTransitionMs: _transitionMs,
                );
              },
            ),
            _slider(
              context,
              label: 'Deterministic transition (ms)',
              value: _transitionMs,
              min: 50.0,
              max: 200.0,
              valueLabel: _transitionMs.toStringAsFixed(0),
              onChanged: (v) async {
                final old = _transitionMs;
                setState(() => _transitionMs = v);
                await _update(
                  oldModulationType: _modulationType,
                  oldFilterType: _filterType,
                  oldIntensity: _intensity,
                  oldBaseFreq: baseFreq,
                  oldBaseAmp: baseAmp,
                  oldDepth: _depth,
                  oldRateHz: _rateHz,
                  oldBandwidthHz: _bandwidthHz,
                  oldFilterFreqHz: _filterFreqHz,
                  oldQ: _q,
                  oldTransitionMs: old,
                );
              },
            ),

            const SizedBox(height: 88),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _dropdown(
    BuildContext context, {
    required String label,
    required int value,
    required List<(int, String)> items,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(label)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<int>(
                value: value,
                isExpanded: true,
                items: items
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e.$1,
                        child: Text(e.$2),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  onChanged(v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label)),
                Text(valueLabel),
              ],
            ),
            Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: (v) => onChanged(v),
            ),
          ],
        ),
      ),
    );
  }
}

