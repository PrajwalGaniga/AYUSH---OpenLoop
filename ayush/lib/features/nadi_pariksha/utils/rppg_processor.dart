import 'dart:math';

class RppgProcessor {
  final List<double> _greenChannel = [];
  final List<double> _timestamps = [];
  static const int _windowSize = 150; // ~5 seconds at 30fps
  static const int _minSamples = 90;  // need 3 sec minimum

  void addFrame(double greenAvg, double timestamp) {
    _greenChannel.add(greenAvg);
    _timestamps.add(timestamp);
    if (_greenChannel.length > _windowSize) {
      _greenChannel.removeAt(0);
      _timestamps.removeAt(0);
    }
  }

  bool get hasEnoughData => _greenChannel.length >= _minSamples;

  // Simple peak detection for BPM
  double? calculateBPM() {
    if (!hasEnoughData) return null;

    final signal = _normalize(_greenChannel);
    final peaks = _findPeaks(signal);

    if (peaks.length < 2) return null;

    // Calculate average interval between peaks
    double totalInterval = 0;
    for (int i = 1; i < peaks.length; i++) {
      totalInterval += _timestamps[peaks[i]] - _timestamps[peaks[i - 1]];
    }
    final avgInterval = totalInterval / (peaks.length - 1);
    if (avgInterval <= 0) return null;

    final bpm = 60.0 / avgInterval;
    // Clamp to physiological range
    if (bpm < 40 || bpm > 180) return null;
    return bpm;
  }

  List<double> _normalize(List<double> data) {
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / data.length;
    final std = sqrt(variance);
    if (std == 0) return data;
    return data.map((x) => (x - mean) / std).toList();
  }

  List<int> _findPeaks(List<double> signal) {
    final peaks = <int>[];
    const minDistance = 15; // min ~0.5s between peaks at 30fps
    const threshold = 0.3;

    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > threshold &&
          signal[i] > signal[i - 1] &&
          signal[i] > signal[i + 1]) {
        if (peaks.isEmpty || i - peaks.last >= minDistance) {
          peaks.add(i);
        }
      }
    }
    return peaks;
  }

  List<double> getRecentSignal() => List.from(_greenChannel);
  void reset() { _greenChannel.clear(); _timestamps.clear(); }
}
