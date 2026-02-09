import 'package:flutter/material.dart';

class AmplitudeSlider extends StatelessWidget {
  final ValueNotifier<double> valueNotifier;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

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
