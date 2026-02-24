import 'package:flutter/material.dart';

/// A customizable slider widget for controlling audio frequency.
///
/// Part of the UI bindings; drives [AudioEngine.setFrequency]. Uses a
/// [ValueNotifier] to reactively update and display the current frequency.
class FrequencySlider extends StatelessWidget {
  /// The [ValueNotifier] that holds and notifies listeners of changes
  /// to the current frequency value.
  final ValueNotifier<double> valueNotifier;

  /// The minimum frequency value selectable on the slider. Defaults to 110 Hz.
  final double min;

  /// The maximum frequency value selectable on the slider. Defaults to 880 Hz.
  final double max;

  /// The number of discrete divisions in the slider. Defaults to 77.
  final int? divisions;

  /// A callback function that is invoked when the slider's value changes.
  final ValueChanged<double>? onChanged;

  /// Creates a [FrequencySlider] widget.
  const FrequencySlider({
    super.key,
    required this.valueNotifier,
    this.min = 110,
    this.max = 880,
    this.divisions = 77,
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
            /// Displays the current frequency value.
            Text(
              'Frequency: ${value.toStringAsFixed(1)}Hz',
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
                label: value.toStringAsFixed(1),
                onChanged: (newValue) {
                  // Update the ValueNotifier and call the external onChanged callback.
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
