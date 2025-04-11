import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

/// A MacosIcon that uses the theme's accent color by default
class ThemedIcon extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// The size of the icon
  final double size;
  
  /// The color of the icon
  /// If null, the theme's primary color will be used
  final Color? color;
  
  /// Creates a ThemedIcon
  const ThemedIcon(
    this.icon, {
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? MacosTheme.of(context).primaryColor;
    
    return MacosIcon(
      icon,
      size: size,
      color: themeColor,
    );
  }
}
