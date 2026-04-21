import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';
import '../../session/therapy_demo_controller.dart';

class ModuleDemoScreen extends StatefulWidget {
  const ModuleDemoScreen({super.key, required this.runtime});
  final AudioRuntimeController runtime;

  @override
  State<ModuleDemoScreen> createState() => _ModuleDemoScreenState();
}

class _ModuleDemoScreenState extends State<ModuleDemoScreen> {
  late final TherapyDemoController _demo;

  @override
  void initState() {
    super.initState();
    widget.runtime.prepareForEngineExperiments();
    _demo = TherapyDemoController(widget.runtime);
  }

  // Module Toggles
  final bool _enableSubthreshold = true;
  bool _enableRmp = false;
  bool _enablePip = false;
  bool _enableSidebands = false;
  
  // Custom Parameters
  double _rmpDepth = 0.1;
  double _rmpRate = 5.0;
  double _pipInterval = 0.2;
  double _pipDuration = 0.02;
  double _sidebandOffset = 100.0;
  double _sidebandIntensity = 0.33;
  double _intensity = 0.5;

  bool _isDemoRunning = false;

  Future<void> _updateEngine({
    required bool oldSubthreshold,
    required bool oldRmp,
    required bool oldPip,
    required bool oldSidebands,
    required bool oldBinaural,
    required double oldIntensity,
    required double oldBaseFreq,
    required double oldBaseAmp,
    required double oldRmpDepth,
    required double oldRmpRate,
    required double oldPipInterval,
    required double oldPipDuration,
    required double oldSidebandOffset,
    required double oldSidebandIntensity,
    required double oldBinauralOffset,
  }) async {
    if (!_isDemoRunning) return;
    if (!widget.runtime.hasEngine) return;

    await _demo.update(
      oldSubthreshold: oldSubthreshold,
      oldRmp: oldRmp,
      oldPip: oldPip,
      oldSidebands: oldSidebands,
      oldBinaural: oldBinaural,
      oldIntensity: oldIntensity,
      oldBaseFreq: oldBaseFreq,
      oldBaseAmp: oldBaseAmp,
      oldRmpDepth: oldRmpDepth,
      oldRmpRate: oldRmpRate,
      oldPipInterval: oldPipInterval,
      oldPipDuration: oldPipDuration,
      oldSidebandOffset: oldSidebandOffset,
      oldSidebandIntensity: oldSidebandIntensity,
      oldBinauralOffset: oldBinauralOffset,
      subthreshold: _enableSubthreshold,
      rmp: _enableRmp,
      pip: _enablePip,
      sidebands: _enableSidebands,
      binaural: false,
      intensity: _intensity,
      baseFreq: widget.runtime.frequency.value,
      baseAmp: widget.runtime.amplitude.value,
      rmpDepth: _rmpDepth,
      rmpRate: _rmpRate,
      pipInterval: _pipInterval,
      pipDuration: _pipDuration,
      sidebandOffset: _sidebandOffset,
      sidebandIntensity: _sidebandIntensity,
      binauralOffset: 5.0,
    );
  }

  Future<void> _toggleDemo() async {
    if (!widget.runtime.hasEngine) return;

    if (_isDemoRunning) {
      setState(() => _isDemoRunning = false);
      await _demo.stop(
        subthreshold: _enableSubthreshold,
        rmp: _enableRmp,
        pip: _enablePip,
        sidebands: _enableSidebands,
        binaural: false,
        intensity: _intensity,
        baseFreq: widget.runtime.frequency.value,
        baseAmp: widget.runtime.amplitude.value,
        rmpDepth: _rmpDepth,
        rmpRate: _rmpRate,
        pipInterval: _pipInterval,
        pipDuration: _pipDuration,
        sidebandOffset: _sidebandOffset,
        sidebandIntensity: _sidebandIntensity,
        binauralOffset: 5.0,
      );
    } else {
      setState(() => _isDemoRunning = true);
      await _demo.start(
        subthreshold: _enableSubthreshold,
        rmp: _enableRmp,
        pip: _enablePip,
        sidebands: _enableSidebands,
        binaural: false,
        intensity: _intensity,
        baseFreq: widget.runtime.frequency.value,
        baseAmp: widget.runtime.amplitude.value,
        rmpDepth: _rmpDepth,
        rmpRate: _rmpRate,
        pipInterval: _pipInterval,
        pipDuration: _pipDuration,
        sidebandOffset: _sidebandOffset,
        sidebandIntensity: _sidebandIntensity,
        binauralOffset: 5.0,
      );
    }
  }

  @override
  void deactivate() {
    if (_isDemoRunning) {
      _demo.dispose();
      widget.runtime.engine?.therapyStop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapy Engine Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Test the isolated module parameters without affecting saved user profiles.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            // Therapy master controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _toggleDemo();
                      },
                      icon: Icon(_isDemoRunning ? Icons.stop : Icons.play_arrow),
                      label: Text(_isDemoRunning ? 'Stop Demo' : 'Start Demo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDemoRunning ? Colors.red.shade100 : null,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Master Intensity'),
                        Expanded(
                          child: Slider(
                            value: _intensity,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (v) {
                              final oldIntensity = _intensity;
                              setState(() => _intensity = v);
                              _updateEngine(
                                oldSubthreshold: _enableSubthreshold,
                                oldRmp: _enableRmp,
                                oldPip: _enablePip,
                                oldSidebands: _enableSidebands,
                                oldBinaural: false,
                                oldIntensity: oldIntensity,
                                oldBaseFreq: widget.runtime.frequency.value,
                                oldBaseAmp: widget.runtime.amplitude.value,
                                oldRmpDepth: _rmpDepth,
                                oldRmpRate: _rmpRate,
                                oldPipInterval: _pipInterval,
                                oldPipDuration: _pipDuration,
                                oldSidebandOffset: _sidebandOffset,
                                oldSidebandIntensity: _sidebandIntensity,
                                oldBinauralOffset: 5.0,
                              );
                            },
                          ),
                        ),
                        Text(_intensity.toStringAsFixed(2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // RMP Module
            SwitchListTile(
              title: const Text('RMP (Randomized Micro-Perturbation)'),
              value: _enableRmp,
              onChanged: (v) {
                final oldRmp = _enableRmp;
                setState(() => _enableRmp = v);
                _updateEngine(
                  oldSubthreshold: _enableSubthreshold,
                  oldRmp: oldRmp,
                  oldPip: _enablePip,
                  oldSidebands: _enableSidebands,
                  oldBinaural: false,
                  oldIntensity: _intensity,
                  oldBaseFreq: widget.runtime.frequency.value,
                  oldBaseAmp: widget.runtime.amplitude.value,
                  oldRmpDepth: _rmpDepth,
                  oldRmpRate: _rmpRate,
                  oldPipInterval: _pipInterval,
                  oldPipDuration: _pipDuration,
                  oldSidebandOffset: _sidebandOffset,
                  oldSidebandIntensity: _sidebandIntensity,
                  oldBinauralOffset: 5.0,
                );
              },
            ),
            if (_enableRmp) ...[
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('rmpDepth: Controls amplitude jitter amount'),
              ),
              Slider(
                value: _rmpDepth,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: _rmpDepth.toStringAsFixed(2),
                onChanged: (v) {
                  final old = _rmpDepth;
                  setState(() => _rmpDepth = v);
                  _updateEngine(
                    oldSubthreshold: _enableSubthreshold,
                    oldRmp: _enableRmp,
                    oldPip: _enablePip,
                    oldSidebands: _enableSidebands,
                    oldBinaural: false,
                    oldIntensity: _intensity,
                    oldBaseFreq: widget.runtime.frequency.value,
                    oldBaseAmp: widget.runtime.amplitude.value,
                    oldRmpDepth: old,
                    oldRmpRate: _rmpRate,
                    oldPipInterval: _pipInterval,
                    oldPipDuration: _pipDuration,
                    oldSidebandOffset: _sidebandOffset,
                    oldSidebandIntensity: _sidebandIntensity,
                    oldBinauralOffset: 5.0,
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('rmpRate: Controls speed of jitter (Hz)'),
              ),
              Slider(
                value: _rmpRate,
                min: 0.1,
                max: 20.0,
                divisions: 199,
                label: '${_rmpRate.toStringAsFixed(1)} Hz',
                onChanged: (v) {
                  final old = _rmpRate;
                  setState(() => _rmpRate = v);
                  _updateEngine(
                    oldSubthreshold: _enableSubthreshold,
                    oldRmp: _enableRmp,
                    oldPip: _enablePip,
                    oldSidebands: _enableSidebands,
                    oldBinaural: false,
                    oldIntensity: _intensity,
                    oldBaseFreq: widget.runtime.frequency.value,
                    oldBaseAmp: widget.runtime.amplitude.value,
                    oldRmpDepth: _rmpDepth,
                    oldRmpRate: old,
                    oldPipInterval: _pipInterval,
                    oldPipDuration: _pipDuration,
                    oldSidebandOffset: _sidebandOffset,
                    oldSidebandIntensity: _sidebandIntensity,
                    oldBinauralOffset: 5.0,
                  );
                },
              ),
            ],
            const Divider(),

            // PIP Module
            SwitchListTile(
              title: const Text('PIP (Phase-Interruption Patterning)'),
              value: _enablePip,
              onChanged: (v) {
                final oldPip = _enablePip;
                setState(() => _enablePip = v);
                _updateEngine(
                  oldSubthreshold: _enableSubthreshold,
                  oldRmp: _enableRmp,
                  oldPip: oldPip,
                  oldSidebands: _enableSidebands,
                  oldBinaural: false,
                  oldIntensity: _intensity,
                  oldBaseFreq: widget.runtime.frequency.value,
                  oldBaseAmp: widget.runtime.amplitude.value,
                  oldRmpDepth: _rmpDepth,
                  oldRmpRate: _rmpRate,
                  oldPipInterval: _pipInterval,
                  oldPipDuration: _pipDuration,
                  oldSidebandOffset: _sidebandOffset,
                  oldSidebandIntensity: _sidebandIntensity,
                  oldBinauralOffset: 5.0,
                );
              },
            ),
            if (_enablePip) ...[
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('pipInterval: Seconds between interruptions'),
              ),
              Slider(
                value: _pipInterval,
                min: 0.05,
                max: 1.0,
                divisions: 95,
                label: '${_pipInterval.toStringAsFixed(2)} s',
                onChanged: (v) {
                  final old = _pipInterval;
                  setState(() => _pipInterval = v);
                  _updateEngine(
                    oldSubthreshold: _enableSubthreshold,
                    oldRmp: _enableRmp,
                    oldPip: _enablePip,
                    oldSidebands: _enableSidebands,
                    oldBinaural: false,
                    oldIntensity: _intensity,
                    oldBaseFreq: widget.runtime.frequency.value,
                    oldBaseAmp: widget.runtime.amplitude.value,
                    oldRmpDepth: _rmpDepth,
                    oldRmpRate: _rmpRate,
                    oldPipInterval: old,
                    oldPipDuration: _pipDuration,
                    oldSidebandOffset: _sidebandOffset,
                    oldSidebandIntensity: _sidebandIntensity,
                    oldBinauralOffset: 5.0,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text('pipDuration: Tone burst length (${_pipDuration.toStringAsFixed(2)} s)'),
              ),
              Slider(
                value: _pipDuration,
                min: 0.01,
                max: 0.2,
                divisions: 19,
                label: '${_pipDuration.toStringAsFixed(2)} s',
                onChanged: (v) {
                  final old = _pipDuration;
                  setState(() => _pipDuration = v);
                  _updateEngine(
                    oldSubthreshold: _enableSubthreshold,
                    oldRmp: _enableRmp,
                    oldPip: _enablePip,
                    oldSidebands: _enableSidebands,
                    oldBinaural: false,
                    oldIntensity: _intensity,
                    oldBaseFreq: widget.runtime.frequency.value,
                    oldBaseAmp: widget.runtime.amplitude.value,
                    oldRmpDepth: _rmpDepth,
                    oldRmpRate: _rmpRate,
                    oldPipInterval: _pipInterval,
                    oldPipDuration: old,
                    oldSidebandOffset: _sidebandOffset,
                    oldSidebandIntensity: _sidebandIntensity,
                    oldBinauralOffset: 5.0,
                  );
                },
              ),
            ],
            const Divider(),

            // Sidebands Module
            SwitchListTile(
              title: const Text('SSS (Spectral Sideband Stimulation)'),
              value: _enableSidebands,
              onChanged: (v) {
                final old = _enableSidebands;
                setState(() => _enableSidebands = v);
                _updateEngine(
                  oldSubthreshold: _enableSubthreshold,
                  oldRmp: _enableRmp,
                  oldPip: _enablePip,
                  oldSidebands: old,
                  oldBinaural: false,
                  oldIntensity: _intensity,
                  oldBaseFreq: widget.runtime.frequency.value,
                  oldBaseAmp: widget.runtime.amplitude.value,
                  oldRmpDepth: _rmpDepth,
                  oldRmpRate: _rmpRate,
                  oldPipInterval: _pipInterval,
                  oldPipDuration: _pipDuration,
                  oldSidebandOffset: _sidebandOffset,
                  oldSidebandIntensity: _sidebandIntensity,
                  oldBinauralOffset: 5.0,
                );
              },
            ),
            if (_enableSidebands) ...[
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('sidebandOffset: Frequency offset from base (Hz)'),
              ),
              Slider(
                value: _sidebandOffset,
                min: 10.0,
                max: 500.0,
                divisions: 490,
                label: '${_sidebandOffset.toStringAsFixed(0)} Hz',
                onChanged: (v) {
                  final old = _sidebandOffset;
                  setState(() => _sidebandOffset = v);
                  _updateEngine(
                    oldSubthreshold: _enableSubthreshold,
                    oldRmp: _enableRmp,
                    oldPip: _enablePip,
                    oldSidebands: _enableSidebands,
                    oldBinaural: false,
                    oldIntensity: _intensity,
                    oldBaseFreq: widget.runtime.frequency.value,
                    oldBaseAmp: widget.runtime.amplitude.value,
                    oldRmpDepth: _rmpDepth,
                    oldRmpRate: _rmpRate,
                    oldPipInterval: _pipInterval,
                    oldPipDuration: _pipDuration,
                    oldSidebandOffset: old,
                    oldSidebandIntensity: _sidebandIntensity,
                    oldBinauralOffset: 5.0,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text('sidebandIntensity: Mix depth (${_sidebandIntensity.toStringAsFixed(2)})'),
              ),
              Slider(
                value: _sidebandIntensity,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: _sidebandIntensity.toStringAsFixed(2),
                onChanged: (v) {
                  final old = _sidebandIntensity;
                  setState(() => _sidebandIntensity = v);
                  _updateEngine(
                    oldSubthreshold: _enableSubthreshold,
                    oldRmp: _enableRmp,
                    oldPip: _enablePip,
                    oldSidebands: _enableSidebands,
                    oldBinaural: false,
                    oldIntensity: _intensity,
                    oldBaseFreq: widget.runtime.frequency.value,
                    oldBaseAmp: widget.runtime.amplitude.value,
                    oldRmpDepth: _rmpDepth,
                    oldRmpRate: _rmpRate,
                    oldPipInterval: _pipInterval,
                    oldPipDuration: _pipDuration,
                    oldSidebandOffset: _sidebandOffset,
                    oldSidebandIntensity: old,
                    oldBinauralOffset: 5.0,
                  );
                },
              ),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
