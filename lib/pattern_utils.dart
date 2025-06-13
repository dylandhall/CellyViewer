import 'dart:math' as math;

/// Counts all 3x3 patterns within [lines] and returns the non-zero counts
/// sorted from most to least frequent.
List<int> getSortedPatternCounts(List<List<bool>> lines) {
  if (lines.length < 3 || lines[0].length < 3) {
    return [];
  }
  final counts = List<int>.filled(512, 0);
  final rows = lines.length;
  final cols = lines[0].length;
  for (int r = 0; r < rows - 2; r++) {
    for (int c = 0; c < cols - 2; c++) {
      int val = 0;
      for (int dr = 0; dr < 3; dr++) {
        for (int dc = 0; dc < 3; dc++) {
          if (lines[r + dr][c + dc]) {
            val |= 1 << (dr * 3 + dc);
          }
        }
      }
      counts[val]++;
    }
  }
  final sorted = counts.where((c) => c > 0).toList()
    ..sort((a, b) => b.compareTo(a));
  return sorted;
}

/// Performs a simple linear regression on [sortedCounts], using the
/// logarithm of each count value to keep large counts from dominating.
double calculateGradient(List<int> sortedCounts) {
  if (sortedCounts.isEmpty) return 0;
  final logs = sortedCounts.map((c) => math.log(c.toDouble())).toList();
  final ranks =
      List<double>.generate(sortedCounts.length, (i) => math.log((i + 1).toDouble()));
  final n = logs.length;
  double sumX = 0;
  double sumY = 0;
  double sumXY = 0;
  double sumX2 = 0;
  for (int i = 0; i < n; i++) {
    final x = ranks[i];
    final y = logs[i];
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumX2 += x * x;
  }
  final numerator = n * sumXY - sumX * sumY;
  final denominator = n * sumX2 - sumX * sumX;
  if (denominator == 0) return 0;
  return numerator / denominator;
}

/// Maps [gradient] to a value between 0 and 1. Values near 0 represent
/// flat gradients (random), while values near 1 represent very steep slopes
/// (highly ordered).
double normalizedGradient(double gradient) {
  return (2 / math.pi) * math.atan(gradient.abs());
}

/// Returns true if [gradient] falls within the middle 80% of the possible range.
bool passesGradientFilter(
  double gradient,
  double minNormalized,
  double maxNormalized,
) {
  final normalized = normalizedGradient(gradient);
  return normalized > minNormalized && normalized < maxNormalized;
}
