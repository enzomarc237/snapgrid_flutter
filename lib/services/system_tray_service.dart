import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

/// Service for managing system tray functionality
class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  bool _isInitialized = false;

  /// Initialize the system tray
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Determine the correct icon path based on platform
      String iconPath;
      if (Platform.isWindows) {
        iconPath = 'assets/images/app_icon.ico';
      } else {
        iconPath = 'assets/images/app_icon.png';
      }

      // Initialize the system tray
      await _systemTray.initSystemTray(
        title: "SnapGrid",
        iconPath: iconPath,
        toolTip: "SnapGrid - Screenshot Management Tool",
      );

      // Create and set the context menu
      await _createContextMenu();

      // Register event handlers
      _registerEventHandlers();

      _isInitialized = true;
      debugPrint('System tray initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize system tray: $e');
    }
  }

  /// Create the context menu for the system tray
  Future<void> _createContextMenu() async {
    final Menu menu = Menu();
    
    await menu.buildFrom([
      MenuItemLabel(
        label: 'Show SnapGrid',
        onClicked: (menuItem) => _showWindow(),
      ),
      MenuItemLabel(
        label: 'Hide SnapGrid',
        onClicked: (menuItem) => _hideWindow(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'About SnapGrid',
        onClicked: (menuItem) => _showAbout(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Quit SnapGrid',
        onClicked: (menuItem) => _quitApp(),
      ),
    ]);

    await _systemTray.setContextMenu(menu);
  }

  /// Register system tray event handlers
  void _registerEventHandlers() {
    _systemTray.registerSystemTrayEventHandler((eventName) {
      debugPrint("System tray event: $eventName");
      
      if (eventName == kSystemTrayEventClick) {
        // On Windows, single click shows the window
        // On macOS, single click shows the context menu
        if (Platform.isWindows) {
          _showWindow();
        } else {
          _systemTray.popUpContextMenu();
        }
      } else if (eventName == kSystemTrayEventRightClick) {
        // Right click shows context menu on Windows
        if (Platform.isWindows) {
          _systemTray.popUpContextMenu();
        }
      } else if (eventName == kSystemTrayEventDoubleClick) {
        // Double click shows the window
        _showWindow();
      }
    });
  }

  /// Show the application window
  void _showWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('Failed to show window: $e');
    }
  }

  /// Hide the application window
  void _hideWindow() async {
    try {
      await windowManager.hide();
    } catch (e) {
      debugPrint('Failed to hide window: $e');
    }
  }

  /// Show about dialog
  void _showAbout() {
    // This will be implemented to show an about dialog
    debugPrint('About dialog requested');
  }

  /// Quit the application
  void _quitApp() async {
    try {
      await destroy();
      await windowManager.close();
    } catch (e) {
      debugPrint('Failed to quit app: $e');
      exit(0);
    }
  }

  /// Update the system tray tooltip
  Future<void> updateTooltip(String tooltip) async {
    if (!_isInitialized) return;
    
    try {
      await _systemTray.setTooltip(tooltip);
    } catch (e) {
      debugPrint('Failed to update tooltip: $e');
    }
  }

  /// Update the system tray icon
  Future<void> updateIcon(String iconPath) async {
    if (!_isInitialized) return;
    
    try {
      await _systemTray.setImage(iconPath);
    } catch (e) {
      debugPrint('Failed to update icon: $e');
    }
  }

  /// Destroy the system tray
  Future<void> destroy() async {
    if (!_isInitialized) return;
    
    try {
      await _systemTray.destroy();
      _isInitialized = false;
      debugPrint('System tray destroyed');
    } catch (e) {
      debugPrint('Failed to destroy system tray: $e');
    }
  }

  /// Check if the system tray is initialized
  bool get isInitialized => _isInitialized;
}