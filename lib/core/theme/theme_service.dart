import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_settings.dart';

/// Service for managing theme settings persistence
class ThemeService {
  static const String _themeSettingsKey = 'theme_settings';
  
  /// Loads the theme settings from storage
  Future<ThemeSettings> loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeSettingsJson = prefs.getString(_themeSettingsKey);
      
      if (themeSettingsJson == null) {
        return ThemeSettings.defaults;
      }
      
      final Map<String, dynamic> themeSettingsMap = 
          jsonDecode(themeSettingsJson) as Map<String, dynamic>;
      
      return ThemeSettings.fromJson(themeSettingsMap);
    } catch (e) {
      debugPrint('Error loading theme settings: $e');
      return ThemeSettings.defaults;
    }
  }
  
  /// Saves the theme settings to storage
  Future<bool> saveThemeSettings(ThemeSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeSettingsJson = jsonEncode(settings.toJson());
      
      return await prefs.setString(_themeSettingsKey, themeSettingsJson);
    } catch (e) {
      debugPrint('Error saving theme settings: $e');
      return false;
    }
  }
}
