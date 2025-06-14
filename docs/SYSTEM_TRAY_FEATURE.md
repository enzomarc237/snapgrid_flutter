# System Tray Feature

This document describes the system tray functionality implemented in SnapGrid Flutter.

## Overview

The system tray feature allows SnapGrid to run in the background and be accessible from the system tray (Windows), menu bar (macOS), or notification area (Linux). This provides a convenient way for users to access the application without keeping the main window open.

## Features

- **Cross-platform support**: Works on Windows, macOS, and Linux
- **App icon in system tray**: Shows the SnapGrid icon in the system tray
- **Context menu**: Right-click menu with common actions
- **Window management**: Show/hide the main window from the tray
- **Graceful shutdown**: Proper cleanup when quitting the application

## Implementation Details

### Dependencies

- `system_tray: ^2.0.3` - Provides system tray functionality
- `window_manager: ^0.4.3` - Handles window management operations

### Key Components

1. **SystemTrayService** (`lib/services/system_tray_service.dart`)
   - Singleton service that manages system tray operations
   - Handles initialization, context menu creation, and event handling
   - Provides methods for updating tray icon and tooltip

2. **System Tray Provider** (`lib/providers/system_tray_provider.dart`)
   - Riverpod providers for accessing the system tray service
   - State management for initialization status

3. **Window Management Integration**
   - Uses `window_manager` for cross-platform window operations
   - Prevents window closing, hiding it instead
   - Proper focus and show/hide functionality

### Context Menu Actions

- **Show SnapGrid**: Brings the main window to the front
- **Hide SnapGrid**: Hides the main window
- **About SnapGrid**: Shows application information (placeholder)
- **Quit SnapGrid**: Properly closes the application

### Event Handling

- **Single Click**: 
  - Windows: Shows the main window
  - macOS: Shows the context menu
- **Right Click**: Shows the context menu (Windows)
- **Double Click**: Shows the main window

## Usage

The system tray is automatically initialized when the application starts. Users can:

1. **Minimize to tray**: Close the main window to hide it (it won't quit the app)
2. **Access from tray**: Click the tray icon to show the window
3. **Use context menu**: Right-click for additional options
4. **Quit properly**: Use "Quit SnapGrid" from the context menu

## Platform-Specific Notes

### Windows
- Uses `.ico` format for the tray icon
- Single click shows the window
- Right click shows context menu

### macOS
- Uses `.png` format for the tray icon
- Single click shows context menu
- Integrates with macOS menu bar

### Linux
- Uses `.png` format for the tray icon
- Requires `libappindicator3-dev` or `libayatana-appindicator3-dev`
- May require additional setup depending on desktop environment

## Installation Requirements

### Linux
Before running the application on Linux, install the required dependencies:

```bash
# Ubuntu/Debian (older versions)
sudo apt-get install appindicator3-0.1 libappindicator3-dev

# Ubuntu 22.04 or greater
sudo apt-get install libayatana-appindicator3-dev
```

## Assets

The system tray uses the following icon assets:
- `assets/images/app_icon.ico` - Windows tray icon
- `assets/images/app_icon.png` - macOS/Linux tray icon

These are automatically copied from the platform-specific app icons during the build process.

## Future Enhancements

Potential improvements for the system tray feature:

1. **Notification support**: Show notifications for important events
2. **Quick actions**: Add more context menu items for common tasks
3. **Settings integration**: Allow users to configure tray behavior
4. **Badge support**: Show status indicators on the tray icon
5. **Hotkey support**: Global hotkeys to show/hide the window