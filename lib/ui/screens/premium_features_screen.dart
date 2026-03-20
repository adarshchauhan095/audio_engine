import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';
import '../widgets/therapy_modules_meters_panel.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key, required this.runtime});
  final AudioRuntimeController runtime;

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  // Binaural Beats Controls
  bool _enableBinaural = false;
  double _binauralOffset = 10.0; // Default to Alpha/Low Beta

  // Focus & Relaxation Modes
  String? _activeProgram;

  // Custom Parameters
  double _intensity = 0.5;

  bool _isDemoRunning = false;
  DateTime? _demoStartedAt;

  void _updateEngine() {
    if (!_isDemoRunning) return;
    
    // Safety check just in case engine is null
    if (!widget.runtime.hasEngine) return;
    
    widget.runtime.engine?.therapyUpdate(
      binaural: _enableBinaural,
      intensity: _intensity,
      baseFreq: widget.runtime.frequency.value,
      baseAmp: widget.runtime.amplitude.value,
      binauralOffset: _binauralOffset,
      // Pass defaults for everything else
      subthreshold: false,
      rmp: false,
      pip: false,
      sidebands: false,
      rmpDepth: 0.1,
      rmpRate: 5.0,
      pipInterval: 0.2,
      pipDuration: 0.02,
      sidebandOffset: 100.0,
      sidebandIntensity: 0.33,
    );
  }

  void _toggleDemo() {
    if (!widget.runtime.hasEngine) return;
    
    final bool nextRunning = !_isDemoRunning;
    setState(() {
      _isDemoRunning = nextRunning;
      _demoStartedAt = nextRunning ? DateTime.now() : null;
    });

    if (_isDemoRunning) {
      widget.runtime.engine?.therapyStart(
        binaural: _enableBinaural,
        intensity: _intensity,
        baseFreq: widget.runtime.frequency.value,
        baseAmp: widget.runtime.amplitude.value,
        binauralOffset: _binauralOffset,
        subthreshold: false,
        rmp: false,
        pip: false,
        sidebands: false,
        rmpDepth: 0.1,
        rmpRate: 5.0,
        pipInterval: 0.2,
        pipDuration: 0.02,
        sidebandOffset: 100.0,
        sidebandIntensity: 0.33,
      );
      if (!widget.runtime.playing.value) {
        widget.runtime.togglePlay();
      }
    } else {
      widget.runtime.engine?.therapyStop();
    }
  }

  void _setProgram(String programName, double targetBinauralOffset, double targetBaseFreq) {
    setState(() {
      _activeProgram = programName;
      _enableBinaural = true;
      _binauralOffset = targetBinauralOffset;
    });
    widget.runtime.setFrequency(targetBaseFreq);
    if (_isDemoRunning) {
      _updateEngine();
    }
  }

  @override
  void deactivate() {
    if (_isDemoRunning) {
      widget.runtime.engine?.therapyStop();
    }
    _demoStartedAt = null;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Test advanced premium therapy modes safely isolated from default profiles.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Master controls
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _toggleDemo,
                      icon: Icon(_isDemoRunning ? Icons.stop : Icons.play_arrow),
                      label: Text(_isDemoRunning ? 'Stop Audio' : 'Start Audio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDemoRunning ? Colors.red.shade100 : Theme.of(context).primaryColorLight,
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
                              setState(() => _intensity = v);
                              _updateEngine();
                            },
                          ),
                        ),
                        Text(_intensity.toStringAsFixed(2)),
                      ],
                    ),
                    ValueListenableBuilder<double>(
                      valueListenable: widget.runtime.frequency,
                      builder: (context, freq, _) {
                        final double safeFreq = freq.clamp(
                          AudioRuntimeController.freqMin,
                          1000.0,
                        );
                        return Row(
                          children: [
                            const Text('Base Frequency'),
                            Expanded(
                              child: Slider(
                                value: safeFreq,
                                min: AudioRuntimeController.freqMin,
                                max: 1000.0, // Limit for better binaural effect demo
                                onChanged: (v) {
                                  widget.runtime.setFrequency(v);
                                  _updateEngine();
                                },
                              ),
                            ),
                            Text('${freq.toStringAsFixed(0)} Hz'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Binaural Beats Testing Module
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Binaural Beats', style: Theme.of(context).textTheme.titleLarge),
                        Switch(
                          value: _enableBinaural,
                          onChanged: (v) {
                            setState(() {
                              _enableBinaural = v;
                              if (!v) _activeProgram = null; // Clear preset if turned off
                            });
                            _updateEngine();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Listen manually to different brainwave frequency offsets.'),
                    if (_enableBinaural) ...[
                      const SizedBox(height: 16),
                      Text('Binaural Offset: ${_binauralOffset.toStringAsFixed(1)} Hz'),
                      Slider(
                        value: _binauralOffset,
                        min: 0.5,
                        max: 40.0,
                        divisions: 400,
                        onChanged: (v) {
                          setState(() {
                            _binauralOffset = v;
                            _activeProgram = null; // Manual override
                          });
                          _updateEngine();
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Delta', style: TextStyle(fontSize: 10)),
                          Text('Theta', style: TextStyle(fontSize: 10)),
                          Text('Alpha', style: TextStyle(fontSize: 10)),
                          Text('Beta', style: TextStyle(fontSize: 10)),
                          Text('Gamma', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: widget.runtime.playing,
              builder: (context, playing, _) {
                return TherapyModulesMetersPanel(
                  runtime: widget.runtime,
                  isRunning: _isDemoRunning && playing,
                  intensityProvider: () => _intensity,
                  elapsedSecondsProvider: () {
                    final started = _demoStartedAt;
                    if (started == null) return 0.0;
                    final ms = DateTime.now().difference(started).inMilliseconds;
                    return ms / 1000.0;
                  },
                  subthresholdEnabled: false,
                  rmpEnabled: false,
                  pipEnabled: false,
                  sssEnabled: false,
                  binauralEnabled: _enableBinaural,
                  rmpDepth: 0.1,
                  rmpRate: 5.0,
                  pipIntervalSeconds: 0.2,
                  pipDurationSeconds: 0.02,
                  sidebandOffset: 100.0,
                  sidebandIntensity: 0.33,
                  binauralOffset: _binauralOffset,
                );
              },
            ),
            const SizedBox(height: 24),

            // Focus Programs
            Text('Focus Programs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _ProgramChip(
                  label: 'Deep Work (15Hz Beta)',
                  isActive: _activeProgram == 'Deep Work',
                  onTap: () => _setProgram('Deep Work', 15.0, 300.0),
                ),
                _ProgramChip(
                  label: 'Creative Flow (10Hz Alpha)',
                  isActive: _activeProgram == 'Creative Flow',
                  onTap: () => _setProgram('Creative Flow', 10.0, 432.0),
                ),
                _ProgramChip(
                  label: 'Peak Focus (40Hz Gamma)',
                  isActive: _activeProgram == 'Peak Focus',
                  onTap: () => _setProgram('Peak Focus', 40.0, 250.0),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Relaxation Programs
            Text('Relaxation Programs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _ProgramChip(
                  label: 'Deep Sleep (2Hz Delta)',
                  isActive: _activeProgram == 'Deep Sleep',
                  onTap: () => _setProgram('Deep Sleep', 2.0, 150.0),
                ),
                _ProgramChip(
                  label: 'Meditation (6Hz Theta)',
                  isActive: _activeProgram == 'Meditation',
                  onTap: () => _setProgram('Meditation', 6.0, 200.0),
                ),
                _ProgramChip(
                  label: 'Light Relax (8Hz Alpha)',
                  isActive: _activeProgram == 'Light Relax',
                  onTap: () => _setProgram('Light Relax', 8.0, 396.0),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _ProgramChip extends StatelessWidget {
  const _ProgramChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
      side: isActive ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : null,
      onPressed: onTap,
    );
  }
}
