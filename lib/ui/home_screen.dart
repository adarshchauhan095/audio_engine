/// Main screen and UI bindings for the audio engine.
///
/// Connects [FrequencySlider] and [AmplitudeSlider] and play/stop to
/// [AudioEngine]. All control flows through the engine API; no direct
/// native or FFI access. Manages engine lifecycle and playback state.
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';

import '../engine/audio_engine.dart';
import '../engine/bindings.dart';
import 'widgets/amplitude_slider.dart';
import 'widgets/frequency_slider.dart';

class HomeScreen extends StatefulWidget {
  /// Creates the home screen widget.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// The state for the [HomeScreen] widget.
///
/// Manages the audio engine instance, playback state, frequency,
/// amplitude, and error handling for platform-specific audio setup.
class _HomeScreenState extends State<HomeScreen> {
  /// The audio engine instance responsible for native audio playback.
  AudioEngine? _engine;

  /// Notifier for tracking the audio playback state (playing or stopped).
  final ValueNotifier<bool> _playing = ValueNotifier(false);

  /// Notifier for tracking and updating the audio frequency.
  final ValueNotifier<double> _frequency = ValueNotifier(440.0);

  /// Notifier for tracking and updating the audio amplitude.
  final ValueNotifier<double> _amplitude = ValueNotifier(0.3);

  /// Stores any error messages encountered during engine initialization.
  String? _error;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  /// Initializes the native audio engine.
  ///
  /// This method checks if the platform is Android, and if so,
  /// opens the native library, creates [NativeBindings], and
  /// initializes the [AudioEngine]. It also sets the initial
  /// frequency and amplitude. If not on Android, it sets an error message.
  void _initEngine() {
    if (!Platform.isAndroid) {
      setState(() => _error = 'Native audio only on Android');
      return;
    }

    // Open the native audio library.
    final lib = DynamicLibrary.open('libnative_audio.so');
    // Create bindings to the native functions.
    final bindings = NativeBindings(lib);

    // Initialize the audio engine and set default values.
    _engine = AudioEngine(bindings)..init();
    _engine!.setFrequency(_frequency.value);
    _engine!.setAmplitude(_amplitude.value);
  }

  @override
  void dispose() {
    // Dispose of the audio engine when the widget is removed from the tree.
    _engine?.dispose();
    super.dispose();
  }

  /// Toggles the audio playback state (play/stop).
  ///
  /// If the engine is currently playing, it stops playback.
  /// If not playing, it starts playback.
  void _togglePlay() {
    if (_engine == null) return;

    setState(() {
      if (_playing.value) {
        _engine!.stop();
        _playing.value = false;
      } else {
        _engine!.start();
        _playing.value = true;
      }
    });
  }

  /// Slider range for frequency (must match FrequencySlider min/max to avoid assertion).
  static const double _freqMin = 110, _freqMax = 880;

  /// Milestone 02: Rapid parameter changes for stability testing.
  Future<void> _runRapidParams() async {
    if (_engine == null) return;
    if (!_playing.value) {
      _engine!.start();
      _playing.value = true;
    }
    const duration = Duration(milliseconds: 2000);
    const interval = Duration(milliseconds: 50);
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      final f = 110.0 + (8000 - 110) * (DateTime.now().millisecond % 1000 / 1000);
      final a = (DateTime.now().millisecond % 1000) / 1000.0;
      _engine!.setFrequency(f);
      _engine!.setAmplitude(a);
      _frequency.value = f.clamp(_freqMin, _freqMax);
      _amplitude.value = a.clamp(0.0, 1.0);
      if (mounted) setState(() {});
      await Future<void>.delayed(interval);
    }
  }

  /// Milestone 02: Repeated start/stop cycles for stability testing.
  Future<void> _runStartStop10() async {
    if (_engine == null) return;
    for (int i = 0; i < 10 && mounted; i++) {
      _engine!.start();
      _playing.value = true;
      if (mounted) setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _engine!.stop();
      _playing.value = false;
      if (mounted) setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Milestone 02: Extreme values for stability testing.
  void _runExtremeValues() {
    if (_engine == null) return;
    _engine!.setFrequency(110);
    _engine!.setFrequency(8000);
    _engine!.setAmplitude(0);
    _engine!.setAmplitude(1);
    _frequency.value = _freqMax;
    _amplitude.value = 1;
    setState(() {});
  }

  /// Builds the Milestone 02 test panel (rapid params, start/stop x10, extreme values).
  Widget _buildM2TestSection() {
    return ExpansionTile(
      title: const Text('Milestone 02 tests'),
      subtitle: const Text('Rapid params, start/stop x10, extreme values'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _engine == null ? null : () => _runRapidParams(),
                icon: const Icon(Icons.speed),
                label: const Text('Rapid params'),
              ),
              FilledButton.icon(
                onPressed: _engine == null ? null : () => _runStartStop10(),
                icon: const Icon(Icons.replay_10),
                label: const Text('Start/stop x10'),
              ),
              FilledButton.icon(
                onPressed: _engine == null ? null : _runExtremeValues,
                icon: const Icon(Icons.warning_amber),
                label: const Text('Extreme values'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // If an error occurred during engine initialization, display an error widget.
    if (_error != null) {
      return _buildErrorWidget(context, _error!);
    }
    // Otherwise, build the main UI with sliders, indicators, and controls.
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildAudioStatusIndicator(),
                const SizedBox(height: 24),
                _buildAudioVisualizer(),
                const SizedBox(height: 32),
                FrequencySlider(
                  valueNotifier: _frequency,
                  min: 110,
                  max: 880,
                  divisions: 77,
                  onChanged: (v) {
                    _engine?.setFrequency(v);
                  },
                ),
                const SizedBox(height: 24),
                AmplitudeSlider(
                  valueNotifier: _amplitude,
                  min: 0,
                  max: 1,
                  onChanged: (v) {
                    _engine?.setAmplitude(v);
                  },
                ),
                const SizedBox(height: 32),
                _buildM2TestSection(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _playing,
        builder: (context, isPlaying, child) {
          return FloatingActionButton.extended(
            onPressed: _togglePlay,
            label: Text(isPlaying ? 'Stop' : 'Play'),
            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
            backgroundColor: isPlaying
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).primaryColor,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Builds the widget that indicates the current audio playback status.
  ///
  /// Displays text indicating whether the audio is 'Playing' or 'Stopped'.
  Widget _buildAudioStatusIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: _playing,
      builder: (context, isPlaying, child) {
        return Column(
          children: [
            // Icon(
            //   isPlaying ? Icons.graphic_eq : Icons.volume_off,
            //   size: 80,
            //   color: isPlaying ? Theme.of(context).primaryColor : Colors.grey,
            // ),
            const SizedBox(height: 16),
            Text(
              isPlaying ? 'Playing Audio' : 'Audio Stopped',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        );
      },
    );
  }

  /// Builds an animated visualizer for the audio playback.
  ///
  /// The visualizer (a pulsing circle with an audio icon) changes size
  /// and color based on whether the audio is currently playing.
  Widget _buildAudioVisualizer() {
    return ValueListenableBuilder<bool>(
      valueListenable: _playing,
      builder: (context, isPlaying, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isPlaying ? 100 : 80,
          height: isPlaying ? 100 : 80,
          decoration: BoxDecoration(
            color: isPlaying
                ? Theme.of(context).primaryColor.withAlpha((0.3 * 255).round())
                : Colors.grey.withAlpha((0.2 * 255).round()),
            shape: BoxShape.circle,
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).primaryColor.withAlpha((0.5 * 255).round()),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.audiotrack,
            size: 40,
            color: isPlaying ? Theme.of(context).primaryColor : Colors.grey,
          ),
        );
      },
    );
  }

  /// Builds and returns an error message widget.
  ///
  /// This is displayed when an error prevents the audio engine from initializing.
  ///
  /// [context] The build context.
  /// [message] The error message to display.
  Widget _buildErrorWidget(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error:',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
