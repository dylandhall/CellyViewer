import 'package:flutter_test/flutter_test.dart';
import 'package:celly_viewer/pattern_utils.dart';
import 'package:celly_viewer/settings_model.dart';

List<List<bool>> _generateLines(
  int rule,
  int pow,
  int cols,
  int rows,
  List<SeedPoint> seeds,
) {
  final ruleBits =
      List<bool>.generate(1 << pow, (i) => ((rule >> i) & 1) == 1);
  List<bool> line = List<bool>.filled(cols, false);
  for (final sp in seeds) {
    final base = (sp.fraction * cols).floor();
    if (base >= 0 && base < cols) {
      line[base] = true;
    }
    for (int i = 1; i < sp.pixels; i++) {
      final offset = ((i - 1) ~/ 2) + 1;
      final after = i % 2 == 1;
      final idx = after ? base + offset : base - offset;
      if (idx >= 0 && idx < cols) {
        line[idx] = true;
      }
    }
  }

  final lines = <List<bool>>[];
  for (int l = 0; l < rows; l++) {
    lines.add(List<bool>.from(line));
    final newLine = List<bool>.from(line);
    for (int i = 0; i < line.length - pow; i++) {
      int val = 0;
      for (int j = 0; j < pow; j++) {
        if (line[i + j]) {
          val |= 1 << j;
        }
      }
      newLine[i + (pow ~/ 2)] = ruleBits[val];
    }
    line = newLine;
  }
  return lines;
}

void main() {
  final seeds = [
    SeedPoint(fraction: 0.25, pixels: 1),
    SeedPoint(fraction: 1 / 3, pixels: 1),
    SeedPoint(fraction: 2 / 3, pixels: 1),
  ];
  const cols = 1500;
  const rows = 3000;

  test('3-bit rule 2 is measured as too simple', () {
    final lines = _generateLines(2, 3, cols, rows, seeds);
    final counts = getSortedPatternCounts(lines);
    final grad = calculateGradient(counts);
    expect(passesGradientFilter(grad), isFalse);
  });

  test('3-bit rule 30 passes gradient filter', () {
    final lines = _generateLines(30, 3, cols, rows, seeds);
    final counts = getSortedPatternCounts(lines);
    final grad = calculateGradient(counts);
    expect(passesGradientFilter(grad), isTrue);
  });
}

