import 'package:flutter/material.dart';

class FrequencySlider extends StatelessWidget {
  final ValueNotifier<double> valueNotifier;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

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
