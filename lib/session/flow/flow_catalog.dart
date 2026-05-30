import '../phase3_module_type.dart';
import 'flow_definition.dart';
import 'flow_step.dart';

/// Predefined Phase-4 flows (fixed; no editor in Phase 4).
class FlowCatalog {
  FlowCatalog._();

  static const List<FlowDefinition> predefined = <FlowDefinition>[
    FlowDefinition(
      id: 'basic_therapy',
      name: 'Basic Therapy',
      steps: <FlowStep>[
        FlowStep(
          module: Phase3ModuleType.binaural,
          durationMinutes: 5,
          maxIntensityPercent: 40,
        ),
        FlowStep(
          module: Phase3ModuleType.rmp,
          durationMinutes: 5,
          maxIntensityPercent: 35,
        ),
      ],
    ),
    FlowDefinition(
      id: 'deep_modulation',
      name: 'Deep Modulation',
      steps: <FlowStep>[
        FlowStep(
          module: Phase3ModuleType.rmp,
          durationMinutes: 10,
          maxIntensityPercent: 40,
        ),
        FlowStep(
          module: Phase3ModuleType.pip,
          durationMinutes: 5,
          maxIntensityPercent: 30,
        ),
      ],
    ),
    FlowDefinition(
      id: 'full_session',
      name: 'Full Session',
      steps: <FlowStep>[
        FlowStep(
          module: Phase3ModuleType.binaural,
          durationMinutes: 5,
          maxIntensityPercent: 40,
        ),
        FlowStep(
          module: Phase3ModuleType.rmp,
          durationMinutes: 10,
          maxIntensityPercent: 35,
        ),
        FlowStep(
          module: Phase3ModuleType.pip,
          durationMinutes: 5,
          maxIntensityPercent: 30,
        ),
      ],
    ),
  ];

  static FlowDefinition? byId(String id) {
    for (final FlowDefinition flow in predefined) {
      if (flow.id == id) return flow;
    }
    return null;
  }
}
