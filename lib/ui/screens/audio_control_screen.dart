import 'package:flutter/material.dart';

import '../../session/audio_runtime_controller.dart';
import '../widgets/amplitude_slider.dart';
import '../widgets/frequency_slider.dart';

class AudioControlScreen extends StatelessWidget {
  const AudioControlScreen({super.key, required this.runtime});

  final AudioRuntimeController runtime;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _AudioStatusIndicator(playing: runtime.playing),
            const SizedBox(height: 24),
            _AudioVisualizer(playing: runtime.playing),
            const SizedBox(height: 32),
            FrequencySlider(
              valueNotifier: runtime.frequency,
              min: AudioRuntimeController.freqMin,
              max: AudioRuntimeController.freqMax,
              divisions: 77,
              onChanged: runtime.setFrequency,
            ),
            const SizedBox(height: 24),
            AmplitudeSlider(
              valueNotifier: runtime.amplitude,
              min: 0,
              max: 1,
              onChanged: runtime.setAmplitude,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Audio Controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This page controls live tone playback only. '
                      'Testing, tinnitus detection, and patient sessions are independent screens.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 88),
          ],
        ),
      ),
    );
  }
}

class _AudioStatusIndicator extends StatelessWidget {
  const _AudioStatusIndicator({required this.playing});

  final ValueNotifier<bool> playing;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: playing,
      builder: (BuildContext context, bool isPlaying, Widget? child) {
        return Column(
          children: <Widget>[
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
}

class _AudioVisualizer extends StatelessWidget {
  const _AudioVisualizer({required this.playing});

  final ValueNotifier<bool> playing;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: playing,
      builder: (BuildContext context, bool isPlaying, Widget? child) {
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
                ? <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).primaryColor.withAlpha((0.5 * 255).round()),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : const <BoxShadow>[],
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
}
