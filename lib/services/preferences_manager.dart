import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  static const String _sysPromptKey = 'sysPrompt';
  static const String _selectedLanguageKey = 'selectedLang';

  /// Gets the stored system prompt or returns `null` if not set.
  Future<String?> getSystemPrompt() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sysPromptKey);
  }

  /// Stores the system prompt.
  Future<void> setSystemPrompt(String prompt) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sysPromptKey, prompt);
  }

  /// Gets the selected language or returns `null` if not set.
  Future<String?> getSelectedLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageKey);
  }

  /// Stores the selected language.
  Future<void> setSelectedLanguage(String language) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, language);
  }

  /// Clears all stored preferences.
  Future<void> clearPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}