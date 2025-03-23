import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  // Initialize with at least English to avoid empty supportedLocales
  Map<String, String> _availableLanguages = {'en': 'English'};
  bool _isLoading = true;

  Locale get currentLocale => _currentLocale;
  Map<String, String> get availableLanguages => _availableLanguages;
  bool get isLoading => _isLoading;

  // Add this getter as an alias for availableLanguages
  Map<String, String> get supportedLanguages => availableLanguages;

  // All potentially supported languages
  final Map<String, String> _allSupportedLanguages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'hi': 'हिन्दी',
  };

  LanguageProvider() {
    _loadAvailableLanguages();
  }

  // Check which language files are actually available in assets
  Future<void> _loadAvailableLanguages() async {
    _isLoading = true;
    notifyListeners();

    final Map<String, String> available = {
      'en': 'English',
    }; // Always include English as fallback

    // For each potentially supported language, check if its JSON file exists
    for (final entry in _allSupportedLanguages.entries) {
      final languageCode = entry.key;
      final languageName = entry.value;

      if (languageCode == 'en') continue; // Skip English as we already added it

      try {
        // Try to load the language file
        await rootBundle.loadString('assets/translations/$languageCode.json');
        // If no exception is thrown, the file exists
        available[languageCode] = languageName;
      } catch (e) {
        // File doesn't exist, skip this language
        print('Language file for $languageCode not found');
      }
    }

    _availableLanguages = available;
    _isLoading = false;

    // Load saved language preference after we know what's available
    await _loadSavedLanguage();

    notifyListeners();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language_code');

    if (savedLanguage != null &&
        _availableLanguages.containsKey(savedLanguage)) {
      _currentLocale = Locale(savedLanguage);
    } else {
      // Default to English or first available language
      final defaultLanguage =
          _availableLanguages.containsKey('en')
              ? 'en'
              : _availableLanguages.keys.first;
      _currentLocale = Locale(defaultLanguage);
    }
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_availableLanguages.containsKey(languageCode)) {
      _currentLocale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
      notifyListeners();
    }
  }
}
