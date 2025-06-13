class SeedPoint {
  double fraction; // 0.0 - 1.0
  int pixels; // number of pixels to activate

  SeedPoint({this.fraction = 0.5, this.pixels = 1});

  Map<String, dynamic> toMap() => {'fraction': fraction, 'pixels': pixels};

  factory SeedPoint.fromMap(Map<String, dynamic> map) => SeedPoint(
    fraction: (map['fraction'] as num?)?.toDouble() ?? 0.5,
    pixels: map['pixels'] ?? 1,
  );
}

class AppSettings {
  int bitNumber;
  int width;
  int height;
  List<SeedPoint> seedPoints;
  double minGradient;
  double maxGradient;

  AppSettings({
    this.bitNumber = 4, // Default for pow
    this.width = 400,
    this.height = 1000,
    List<SeedPoint>? seedPoints,
    this.minGradient = 0.1,
    this.maxGradient = 0.8,
  }) : seedPoints =
           seedPoints ??
           [
             SeedPoint(fraction: 0.25, pixels: 1),
             SeedPoint(fraction: 1 / 3, pixels: 1),
              SeedPoint(fraction: 2 / 3, pixels: 1),
           ];

  // For storing as a single JSON string in shared_preferences
  Map<String, dynamic> toMap() {
    return {
      'bitNumber': bitNumber,
      'width': width,
      'height': height,
      'seedPoints': seedPoints.map((e) => e.toMap()).toList(),
      'minGradient': minGradient,
      'maxGradient': maxGradient,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    List<dynamic>? rawSeeds = map['seedPoints'];
    List<SeedPoint>? seeds;
    if (rawSeeds is List) {
      seeds = rawSeeds
          .map((e) => SeedPoint.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return AppSettings(
      bitNumber: map['bitNumber'] ?? 4,
      width: map['width'] ?? 400,
      height: map['height'] ?? 1000,
      seedPoints: seeds,
      minGradient: (map['minGradient'] as num?)?.toDouble() ?? 0.1,
      maxGradient: (map['maxGradient'] as num?)?.toDouble() ?? 0.8,
    );
  }
}
