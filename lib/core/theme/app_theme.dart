import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import 'theme_settings.dart';

/// Provides theme configuration for the application
class AppTheme {
  /// Returns the light theme for the application with the given accent color
  static MacosThemeData lightTheme({
    Color accentColor = const Color(0xFF007AFF),
    bool highContrast = false,
  }) {
    final baseTheme = MacosThemeData.light();

    return baseTheme.copyWith(
      primaryColor: accentColor,
      dividerColor:
          highContrast ? const Color(0xFF8E8E93) : baseTheme.dividerColor,
      canvasColor:
          highContrast ? const Color(0xFFF2F2F7) : baseTheme.canvasColor,
      iconTheme: MacosIconThemeData(
        color: highContrast ? Colors.black : Colors.black54,
      ),
    );
  }

  /// Returns the dark theme for the application with the given accent color
  static MacosThemeData darkTheme({
    Color accentColor = const Color(0xFF007AFF),
    bool highContrast = false,
  }) {
    final baseTheme = MacosThemeData.dark();

    return baseTheme.copyWith(
      primaryColor: accentColor,
      dividerColor:
          highContrast ? const Color(0xFF636366) : baseTheme.dividerColor,
      canvasColor:
          highContrast ? const Color(0xFF1C1C1E) : baseTheme.canvasColor,
      iconTheme: MacosIconThemeData(
        color: highContrast ? Colors.white : Colors.white60,
      ),
    );
  }

  /// Returns the appropriate theme based on the brightness and settings
  static MacosThemeData themeFor({
    required Brightness brightness,
    Color accentColor = const Color(0xFF007AFF),
    bool highContrast = false,
  }) {
    return brightness == Brightness.dark
        ? darkTheme(accentColor: accentColor, highContrast: highContrast)
        : lightTheme(accentColor: accentColor, highContrast: highContrast);
  }

  /// Returns the appropriate theme based on the theme settings
  static MacosThemeData fromSettings(
    ThemeSettings settings,
    Brightness platformBrightness,
  ) {
    // Determine the actual brightness based on theme mode
    final Brightness effectiveBrightness =
        settings.themeMode == ThemeMode.system
            ? platformBrightness
            : settings.themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;

    return themeFor(
      brightness: effectiveBrightness,
      accentColor: settings.accentColor,
      highContrast: settings.highContrast,
    );
  }

  /// Predefined accent colors
  static const List<Color> accentColors = [
    Color(0xFF007AFF), // Blue (Default)
    Color(0xFF34C759), // Green
    Color(0xFFFF9500), // Orange
    Color(0xFFFF2D55), // Red
    Color(0xFF5856D6), // Purple
    Color(0xFFAF52DE), // Pink
    Color(0xFF00C7BE), // Teal
    Color(0xFFFFD60A), // Yellow
  ];
}
