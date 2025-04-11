import 'package:flutter/foundation.dart';
import 'dart:io';

/// Utility class for platform-specific operations
class PlatformUtils {
  /// Returns true if the app is running on macOS
  static bool get isMacOS => Platform.isMacOS;
  
  /// Returns true if the app is running on Windows
  static bool get isWindows => Platform.isWindows;
  
  /// Returns true if the app is running on Linux
  static bool get isLinux => Platform.isLinux;
  
  /// Returns true if the app is running on desktop (macOS, Windows, or Linux)
  static bool get isDesktop => isMacOS || isWindows || isLinux;
  
  /// Executes a function only if running on macOS
  static void runOnMacOS(Function() callback) {
    if (isMacOS) {
      callback();
    }
  }
  
  /// Executes a function with error handling
  static Future<void> runWithErrorHandling(
    Future<void> Function() callback, {
    Function(Object error)? onError,
  }) async {
    try {
      await callback();
    } catch (e) {
      debugPrint('Error: $e');
      if (onError != null) {
        onError(e);
      }
    }
  }
}
