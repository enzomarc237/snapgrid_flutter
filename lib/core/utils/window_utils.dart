import 'package:flutter/foundation.dart';
import 'package:macos_ui/macos_ui.dart';


/// Utility class for window configuration
class WindowUtils {
  /// Configures the macOS window with the specified settings
  static Future<void> configureMacosWindow() async {
    try {
      var config = MacosWindowUtilsConfig(
        toolbarStyle: NSWindowToolbarStyle.expanded,
      );
      await config.apply();
    } catch (e) {
      // Handle or ignore the error if not running on macOS
      debugPrint('Failed to configure macOS window: $e');
    }
  }
}
