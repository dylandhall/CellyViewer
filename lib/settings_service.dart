import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonEncode/Decode
import 'settings_model.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings_v1'; // Added a version for future-proofing

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    String settingsJson = jsonEncode(settings.toMap());
    await prefs.setString(_settingsKey, settingsJson);
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        return AppSettings.fromMap(jsonDecode(settingsJson));
      } catch (e) {
        // Handle potential parsing errors, return defaults
        print("Error loading settings: $e");
        return AppSettings(); // Default if parsing fails
      }
    }
    return AppSettings(); // Default if nothing saved
  }
}
