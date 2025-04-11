import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

/// A progress circle that uses the theme's accent color
class ThemedProgressCircle extends StatelessWidget {
  /// The value of the progress indicator
  /// If null, the progress circle will be indeterminate
  final double? value;

  /// The radius of the progress circle
  final double radius;

  /// Creates a ThemedProgressCircle
  const ThemedProgressCircle({super.key, this.value, this.radius = 12.0});

  @override
  Widget build(BuildContext context) {
    return ProgressCircle(value: value, radius: radius);
  }
}
