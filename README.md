# SnapGrid Flutter

SnapGrid is an open-source desktop app for collecting, organizing, and analyzing UI screenshots. It uses AI to automatically detect UI components and patterns, making it a powerful tool for designers and developers.

![SnapGrid Pre view](assets/preview.png)

This is the Flutter version of SnapGrid, rebuilt from the ground up with a clean architecture and enhanced features.

## Features

- **Screenshot Management** – Collect and organize your UI screenshots in a visual grid layout
- **AI-Powered Pattern Detection** – Identify UI components and patterns using Google Gemini Vision API
- **Smart Organization** – Search and filter your screenshots based on detected UI elements
- **Fast Local Storage** – All screenshots and metadata are stored locally
- **Cross-Platform** – Built with Flutter for macOS, Windows, and Linux support
- **Accessibility Analysis** – Detect potential accessibility issues in UI designs
- **Design System Detection** – Identify design systems used in screenshots

## Installation

Download the latest release for your platform from the [releases](https://github.com/gustavscirulis/snapgrid/releases) page.

## Requirements

To use the AI pattern detection feature, you'll need to add your Google Gemini API key in the settings. The app uses Gemini Vision for analysis. You can still use the app without this feature — it just won't detect patterns.

## Privacy

SnapGrid Flutter does not collect any usage data. All screenshots and analysis are stored locally on your device. The only external communication is with the Google Gemini API when you analyze screenshots, and this is only done with your explicit permission.

## File storage

SnapGrid stores files in the following locations:

- **macOS**: `~/Documents/SnapGridFlutter/`
- **Windows**: `%USERPROFILE%\Documents\SnapGridFlutter\`
- **Linux**: `~/Documents/SnapGridFlutter/`

Inside that folder:

- `images/` – All screenshot image files (PNG, JPG, JPEG)
- `metadata/` – JSON metadata for each media item
- `.trash/` – Deleted items are moved here (same structure as above)

## Development

SnapGrid Flutter is built with:

- Flutter
- Dart
- Riverpod (state management)
- macos_ui (native macOS UI components)
- Google Gemini API (AI analysis)

### Setting Up Development Environment

```sh
# Clone the repository
git clone https://github.com/yourusername/snapgrid_flutter.git

# Navigate to the project directory
cd snapgrid_flutter

# Install dependencies
flutter pub get

# Run the app (macOS)
flutter run -d macos
```

### Building for Production

```sh
# Build for macOS
flutter build macos

# Build for Windows
flutter build windows

# Build for Linux
flutter build linux
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the LICENSE file for details. This license ensures that all modifications to this code remain open source.

## Project Structure

The project follows a clean architecture approach with the following structure:

```
lib/
  ├── core/                 # Core utilities and widgets
  │   ├── theme/            # App theme configuration
  │   ├── utils/            # Utility functions
  │   └── widgets/          # Reusable widgets
  │
  ├── features/             # Feature modules
  │   ├── screenshots/      # Screenshot management feature
  │   │   ├── data/         # Data layer (repositories impl)
  │   │   ├── domain/       # Domain layer (models, repositories)
  │   │   └── presentation/ # UI layer (screens, widgets, providers)
  │   │
  │   └── settings/         # Settings feature
  │       ├── data/         # Data layer
  │       ├── domain/       # Domain layer
  │       └── presentation/ # UI layer
  │
  └── main.dart            # Application entry point
```

## Acknowledgments

- Thanks to the Flutter team for the amazing framework
- Thanks to Google for the Gemini API that powers the pattern detection
- UI components from [macos_ui](https://pub.dev/packages/macos_ui)
