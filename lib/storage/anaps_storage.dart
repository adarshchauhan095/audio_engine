import 'package:shared_preferences/shared_preferences.dart';

class AnapsStorage {
  static const String _keyMaxIntensity = 'anaps_max_intensity';
  static const String _keyFreqOffset = 'anaps_freq_offset';

  static Future<double> loadMaxIntensity() async {
    final prefs = await SharedPreferences.getInstance();
    final double val = prefs.getDouble(_keyMaxIntensity) ?? 0.20; // Default 20%
    return val.clamp(0.20, 0.50);
  }

  static Future<double> loadFrequencyOffset() async {
    final prefs = await SharedPreferences.getInstance();
    final double val = prefs.getDouble(_keyFreqOffset) ?? 0.0; // Default 0 Hz
    return val.clamp(-50.0, 50.0);
  }

  static Future<void> saveParams(double maxIntensity, double freqOffset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMaxIntensity, maxIntensity);
    await prefs.setDouble(_keyFreqOffset, freqOffset);
  }
}
