import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_service.dart';
import 'theme_settings.dart';

/// Provider for the theme service
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

/// Provider for theme settings
final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeSettingsNotifier(themeService);
});

/// Provider for the current theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final themeSettings = ref.watch(themeSettingsProvider);
  return themeSettings.themeMode;
});

/// Provider for the current accent color
final accentColorProvider = Provider<Color>((ref) {
  final themeSettings = ref.watch(themeSettingsProvider);
  return themeSettings.accentColor;
});

/// Provider for high contrast mode
final highContrastProvider = Provider<bool>((ref) {
  final themeSettings = ref.watch(themeSettingsProvider);
  return themeSettings.highContrast;
});

/// Notifier for theme settings
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  final ThemeService _themeService;
  
  ThemeSettingsNotifier(this._themeService) : super(ThemeSettings.defaults) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settings = await _themeService.loadThemeSettings();
    state = settings;
  }
  
  /// Updates the theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final newSettings = state.copyWith(themeMode: themeMode);
    state = newSettings;
    await _themeService.saveThemeSettings(newSettings);
  }
  
  /// Updates the accent color
  Future<void> setAccentColor(Color accentColor) async {
    final newSettings = state.copyWith(accentColor: accentColor);
    state = newSettings;
    await _themeService.saveThemeSettings(newSettings);
  }
  
  /// Updates the high contrast mode
  Future<void> setHighContrast(bool highContrast) async {
    final newSettings = state.copyWith(highContrast: highContrast);
    state = newSettings;
    await _themeService.saveThemeSettings(newSettings);
  }
  
  /// Applies a theme preset
  Future<void> applyPreset(ThemeSettings preset) async {
    state = preset;
    await _themeService.saveThemeSettings(preset);
  }
}
