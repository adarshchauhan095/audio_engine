import 'package:flutter/material.dart';

/// A customizable slider widget for controlling audio amplitude.
///
/// This widget provides a visual slider that allows users to adjust
/// an amplitude value within a specified range. It uses a [ValueNotifier]
/// to reactively update and display the current amplitude.
class AmplitudeSlider extends StatelessWidget {
  /// The [ValueNotifier] that holds and notifies listeners of changes
  /// to the current amplitude value.
  final ValueNotifier<double> valueNotifier;

  /// The minimum amplitude value selectable on the slider. Defaults to 0.
  final double min;

  /// The maximum amplitude value selectable on the slider. Defaults to 1.
  final double max;

  /// The number of discrete divisions in the slider. If null, the slider is continuous.
  final int? divisions;

  /// A callback function that is invoked when the slider's value changes.
  final ValueChanged<double>? onChanged;

  /// Creates an [AmplitudeSlider] widget.
  const AmplitudeSlider({
    super.key,
    required this.valueNotifier,
    this.min = 0,
    this.max = 1,
    this.divisions,
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
            /// Displays the current amplitude value.
            Text(
              'Amplitude: ${value.toStringAsFixed(1)}',
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
