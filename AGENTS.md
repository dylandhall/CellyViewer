# Agent Notes

This repository contains a Flutter app for browsing cellular automata images.
Key components:
- `main.dart` – home of `CellularAutomataPage`, which renders images for rules.
  - `_generateRawPixelData` computes each image line by line.
  - It uses `_getSortedPatternCounts`, `_calculateGradient`, and `_passesGradientFilter`
    to filter out rules that appear too simple. If a rule fails the filter, a
    1x1 white image is stored instead.
  - Image generation occurs synchronously on the main thread; the final scaling
    to an image is done using Canvas.
- `settings_model.dart`, `settings_service.dart`, `settings_page.dart` – manage
  app settings (bit number, width, height, seed points). Settings are stored via
  `shared_preferences`.
- Tests in `test/` verify the main page and settings page load and ensure corrupt
  settings are handled.

Image filtering is based on the 3×3 pattern frequency distribution in the output
lines. The frequencies are sorted and linear regression is performed on the
sorted counts to get a gradient. The gradient is normalized with `atan` and
rejected if the normalized value is below 0.1 or above 0.9.

To debug image filtering, `_generateRawPixelData` prints a summary line with the
rule index, number of patterns counted, the top counts, and the gradient.
