import 'package:audio_engine/session/flow/flow_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('predefined flows match Phase 4 spec', () {
    expect(FlowCatalog.predefined.length, 3);

    final basic = FlowCatalog.byId('basic_therapy')!;
    expect(basic.stepCount, 2);
    expect(basic.totalDurationMinutes, 10);

    final deep = FlowCatalog.byId('deep_modulation')!;
    expect(deep.stepCount, 2);
    expect(deep.totalDurationMinutes, 15);

    final full = FlowCatalog.byId('full_session')!;
    expect(full.stepCount, 3);
    expect(full.totalDurationMinutes, 20);
  });
}
