import 'phase3_module_type.dart';

/// Default Phase-3 module parameters (shared by Phase 3 UI and Flow Engine).
class Phase3ModuleParams {
  const Phase3ModuleParams({
    required this.module,
    this.rmpMinDepthPercent = 20,
    this.rmpMaxDepthPercent = 60,
    this.rmpChangeRateHz = 1.0,
    this.pipPulseMs = 500,
    this.pipPauseMs = 300,
    this.pipShape = PipPulseShape.sine,
    this.binauralBeatOffsetHz = 10,
    this.binauralCarrierHz = 440,
    this.binauralStereoSpreadPercent = 100,
  });

  final Phase3ModuleType module;
  final int rmpMinDepthPercent;
  final int rmpMaxDepthPercent;
  final double rmpChangeRateHz;
  final int pipPulseMs;
  final int pipPauseMs;
  final PipPulseShape pipShape;
  final int binauralBeatOffsetHz;
  final int binauralCarrierHz;
  final int binauralStereoSpreadPercent;

  static Phase3ModuleParams defaultsFor(Phase3ModuleType module) {
    return Phase3ModuleParams(module: module);
  }

  double engineRmpDepth() => (rmpMaxDepthPercent / 100.0).clamp(0.0, 1.0);

  double enginePipPulseSec() => pipPulseMs / 1000.0;

  double enginePipPauseSec() => pipPauseMs / 1000.0;

  double engineBinauralOffset() => binauralBeatOffsetHz.toDouble();

  double engineBaseFreq(double tinnitusFrequencyHz) {
    if (module == Phase3ModuleType.binaural) {
      return binauralCarrierHz.toDouble();
    }
    return tinnitusFrequencyHz;
  }

  String summaryLine({
    required double liveRmpRate,
    required double liveBinauralOffset,
    required double liveBaseFreqHz,
  }) {
    switch (module) {
      case Phase3ModuleType.rmp:
        return 'min=$rmpMinDepthPercent%, max=$rmpMaxDepthPercent%, '
            'rate=${liveRmpRate.toStringAsFixed(1)} Hz';
      case Phase3ModuleType.pip:
        final String shape = switch (pipShape) {
          PipPulseShape.sine => 'Sine',
          PipPulseShape.square => 'Square',
          PipPulseShape.ramp => 'Ramp',
        };
        return 'pulse=${pipPulseMs}ms, pause=${pipPauseMs}ms, shape=$shape';
      case Phase3ModuleType.binaural:
        return 'offset=${liveBinauralOffset.toStringAsFixed(0)} Hz, '
            'carrier=${liveBaseFreqHz.round()} Hz, '
            'spread=$binauralStereoSpreadPercent%';
    }
  }
}
