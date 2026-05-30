import 'flow_step.dart';

/// A named sequence of [FlowStep]s executed in strict order.
class FlowDefinition {
  const FlowDefinition({
    required this.id,
    required this.name,
    required this.steps,
  });

  final String id;
  final String name;
  final List<FlowStep> steps;

  int get stepCount => steps.length;

  int get totalDurationSeconds =>
      steps.fold<int>(0, (int sum, FlowStep s) => sum + s.durationSeconds);

  int get totalDurationMinutes => (totalDurationSeconds / 60).ceil();
}
