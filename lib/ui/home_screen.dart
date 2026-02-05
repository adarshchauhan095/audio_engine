import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';

// import '../engine/audio_engine.dart';
// import '../engine/bindings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //   AudioEngine? _engine;

  final ValueNotifier<bool> _playing = ValueNotifier(false);
  final ValueNotifier<double> _frequency = ValueNotifier(440.0);
  final ValueNotifier<double> _amplitude = ValueNotifier(0.3);
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(context, _error!);
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildAudioStatusIndicator(),
              const SizedBox(height: 24),
              _buildAudioVisualizer(),
              const SizedBox(height: 32),
              _CustomSlider(
                label: 'Frequency',
                valueNotifier: _frequency,
                min: 110,
                max: 880,
                divisions: 77,
                suffix: 'Hz',
                onChanged: (v) {
                  //   _engine?.setFrequency(v);
                },
              ),
              const SizedBox(height: 24),
              _CustomSlider(
                label: 'Amplitude',
                valueNotifier: _amplitude,
                min: 0,
                max: 1,
                suffix: '',
                onChanged: (v) {
                  //   _engine?.setAmplitude(v);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _playing,
        builder: (context, isPlaying, child) {
          return FloatingActionButton.extended(
            // onPressed: _togglePlay,
            onPressed: () {},
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

class _CustomSlider extends StatelessWidget {
  final String label;
  final ValueNotifier<double> valueNotifier;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final ValueChanged<double>? onChanged;

  const _CustomSlider({
    required this.label,
    required this.valueNotifier,
    required this.min,
    required this.max,
    this.divisions,
    this.suffix = '',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ${value.toStringAsFixed(value is int ? 0 : 1)}$suffix',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                showValueIndicator: ShowValueIndicator.onDrag,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: value.toStringAsFixed(value is int ? 0 : 1),
                onChanged: (newValue) {
                  valueNotifier.value = newValue;
                  onChanged?.call(newValue);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
