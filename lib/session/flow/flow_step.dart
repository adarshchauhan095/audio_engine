import '../phase3_module_params.dart';
import '../phase3_module_type.dart';

/// One module instance inside a flow sequence.
class FlowStep {
  const FlowStep({
    required this.module,
    required this.durationMinutes,
    required this.maxIntensityPercent,
    this.moduleParams,
  });

  final Phase3ModuleType module;
  final int durationMinutes;
  final int maxIntensityPercent;
  final Phase3ModuleParams? moduleParams;

  Phase3ModuleParams resolvedParams() =>
      moduleParams ?? Phase3ModuleParams.defaultsFor(module);

  int get durationSeconds => durationMinutes * 60;

  double maxIntensity01() => (maxIntensityPercent / 100.0).clamp(0.0, 0.5);

  String get moduleLabel {
    switch (module) {
      case Phase3ModuleType.rmp:
        return 'RMP';
      case Phase3ModuleType.pip:
        return 'PIP';
      case Phase3ModuleType.binaural:
        return 'Binaural';
    }
  }
}
