class AppSettings {
  int bitNumber;
  int width;
  int height;
  int minLines;

  AppSettings({
    this.bitNumber = 4, // Default for pow
    this.width = 400,
    this.height = 1000,
    this.minLines = 25,
  });

  // For storing as a single JSON string in shared_preferences
  Map<String, dynamic> toMap() {
    return {
      'bitNumber': bitNumber,
      'width': width,
      'height': height,
      'minLines': minLines,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      bitNumber: map['bitNumber'] ?? 4,
      width: map['width'] ?? 400,
      height: map['height'] ?? 1000,
      minLines: map['minLines'] ?? 25,
    );
  }
}
