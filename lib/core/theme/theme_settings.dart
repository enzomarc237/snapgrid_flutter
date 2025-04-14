import 'package:flutter/material.dart';

/// Represents the theme settings for the application
class ThemeSettings {
  /// The theme mode (system, light, dark)
  final ThemeMode themeMode;
  
  /// The accent color for the application
  final Color accentColor;
  
  /// Whether to use high contrast mode
  final bool highContrast;
  
  /// Creates a new ThemeSettings instance
  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.accentColor = const Color(0xFF007AFF), // Default macOS blue
    this.highContrast = false,
  });
  
  /// Creates a copy of this ThemeSettings with the given fields replaced
  ThemeSettings copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    bool? highContrast,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      highContrast: highContrast ?? this.highContrast,
    );
  }
  
  /// Creates a ThemeSettings instance from JSON
  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.toString() == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      accentColor: Color(json['accentColor'] as int? ?? 0xFF007AFF),
      highContrast: json['highContrast'] as bool? ?? false,
    );
  }
  
  /// Converts this ThemeSettings to JSON
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.toString(),
      'accentColor': accentColor.toARGB32(),
      'highContrast': highContrast,
    };
  }
  
  /// Default theme settings
  static const ThemeSettings defaults = ThemeSettings();
  
  /// High contrast theme settings
  static ThemeSettings highContrastPreset() {
    return const ThemeSettings(
      themeMode: ThemeMode.system,
      accentColor: Color(0xFF007AFF),
      highContrast: true,
    );
  }
  
  /// Colorful theme settings with a purple accent
  static ThemeSettings colorfulPreset() {
    return const ThemeSettings(
      themeMode: ThemeMode.system,
      accentColor: Color(0xFF9C27B0), // Purple
      highContrast: false,
    );
  }
}
