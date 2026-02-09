import 'package:flutter/material.dart';

class FrequencySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const FrequencySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: value,
          min: 110,
          max: 880,
          divisions: 77,
          onChanged: onChanged,
        ),
        Text('Frequency: ${value.toInt()} Hz'),
      ],
    );
  }
}
