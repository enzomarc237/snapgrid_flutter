// test/core/theme/app_theme_test.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:snapgrid_flutter/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme should return a light theme', () {
      final theme = AppTheme.lightTheme();
      expect(theme.brightness, Brightness.light);
      expect(theme.primaryColor, MacosColors.systemBlueColor.color);
    });

    test('darkTheme should return a dark theme', () {
      final theme = AppTheme.darkTheme();
      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, MacosColors.systemBlueColor.color);
    });
  });
}