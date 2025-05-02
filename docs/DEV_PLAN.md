# SnapGrid Flutter + Gemini Rebuild: Development Plan

This document outlines the steps to rebuild the SnapGrid application using Flutter for the cross-platform UI (initially targeting macOS) and Google Gemini for AI-powered UI element detection. The `macos_ui` package will be used for a native macOS look and feel.

## Phase 1: Project Setup & Core UI Shell

1.  **Initialize Flutter Project:**
    *   Create a new Flutter project configured for macOS desktop support.
    *   Command: `flutter create --platforms=macos snapgrid_flutter`
    *   Navigate into the project directory: `cd snapgrid_flutter`

2.  **Add Core Dependencies:**
    *   Add required packages to `pubspec.yaml`:
        *   `macos_ui`: For native macOS UI components.
        *   `flutter_gemini`: For interacting with the Gemini API.
        *   `path_provider`: To locate standard file system directories (like Documents).
        *   `file_picker`: To allow users to select screenshots.
        *   `flutter_riverpod` or `provider`: For state management (choose one).
        *   `flutter_secure_storage`: To store the Gemini API key securely.
        *   (Optional) `isar` or `sqflite`: For more robust metadata storage instead of plain JSON files.
    *   Run `flutter pub get`.

3.  **Implement Basic `macos_ui` Structure:**
    *   Set up the main application window using `MacosWindow`.
    *   Implement the primary layout using `ContentArea` and potentially a `Sidebar` for filters or navigation.
    *   Integrate a `TitleBar` for window controls and potentially search functionality later.
    *   Establish basic navigation if multiple views (e.g., grid, settings) are planned.

## Phase 2: Screenshot Management & Display

1.  **Implement File Storage Logic:**
    *   Use `path_provider` to get the application documents directory. Create a dedicated `SnapGridFlutter` subfolder (e.g., `~/Documents/SnapGridFlutter/` on macOS).
    *   Inside this folder, create `images/`, `metadata/`, and `.trash/` subdirectories.
    *   Implement functionality to add screenshots:
        *   Use `file_picker` to allow users to select image files.
        *   Copy selected images into the `images/` directory.
        *   Consider adding drag-and-drop support for adding images.

2.  **Create Screenshot Grid View:**
    *   Utilize Flutter's `GridView.builder` within the main `ContentArea` to display screenshots.
    *   Load image files from the `images/` directory.
    *   Display image thumbnails efficiently (consider generating/caching thumbnails if performance becomes an issue).
    *   Make grid items selectable.

3.  **Implement Basic Metadata Handling:**
    *   Define a Dart model class for screenshot metadata (e.g., `ScreenshotMetadata` containing file name, timestamp, detected elements list).
    *   When an image is added, create a corresponding JSON file (using the image filename + `.json`) in the `metadata/` directory with initial data (e.g., filename, timestamp).
    *   Implement deletion: Move the image file from `images/` to `.trash/images/` and the metadata file from `metadata/` to `.trash/metadata/`.

## Phase 3: Gemini Integration & AI Analysis

1.  **Configure `flutter_gemini`:**
    *   Implement the initialization of the `FlutterGemini` instance, requiring an API key.
    *   Retrieve the API key from secure storage (see Phase 4 - Settings). Handle cases where the key is missing or invalid.

2.  **Implement AI Analysis Service:**
    *   Create a dedicated Dart service/class for handling Gemini API calls.
    *   Develop a function that accepts image data (e.g., `Uint8List` or file path).
    *   Construct the multimodal prompt for Gemini Vision: Include the image data and a text prompt instructing the AI to identify UI components, patterns, text, colors, etc. within the screenshot. Define the desired output format (e.g., structured JSON).
    *   Use `flutter_gemini`'s `generateContent` method with the multimodal input.
    *   Implement robust error handling for API calls (network issues, invalid key, rate limits, content filtering).

3.  **Process and Store Gemini Response:**
    *   Parse the structured response received from Gemini.
    *   Update the corresponding screenshot's metadata file in `metadata/` with the detected UI elements and other relevant information returned by the AI.
    *   Handle cases where the analysis fails or returns unexpected results.

4.  **Integrate Analysis into Workflow:**
    *   Trigger the AI analysis automatically when a new screenshot is added (if an API key is present).
    *   Provide a manual option (e.g., context menu on a grid item) to re-run analysis for a specific screenshot.
    *   Display the analysis status visually on the grid items (e.g., pending, analyzing, complete, error).

## Phase 4: Smart Organization & Settings

1.  **Implement Search and Filtering:**
    *   Add a `MacosSearchField` (likely in the `TitleBar` or `Sidebar`).
    *   Implement logic to read all metadata files from the `metadata/` directory.
    *   Filter the displayed grid based on user search queries matching text found in the screenshot metadata (detected elements, etc.).
    *   (Optional) Implement advanced filtering based on specific UI element types if the Gemini output allows.

2.  **Build Settings Screen/View:**
    *   Create a dedicated settings area (e.g., a separate `MacosWindow` or a view within the main window).
    *   Use `macos_ui` components (`MacosTextField` for API key, `MacosCheckbox` for toggles, `PushButton` for actions).
    *   Implement input for the Google Gemini API key.
    *   Use `flutter_secure_storage` to save and load the API key securely.
    *   Add information about where files are stored.
    *   (Optional) Implement anonymous usage data collection opt-out (requires adding a package like `usage` or integrating with a service like Firebase Analytics).

## Phase 5: Refinements & Packaging

1.  **Improve Error Handling & User Feedback:**
    *   Ensure comprehensive error handling for file operations, API calls, and UI interactions.
    *   Use `MacosAlertDialog` or other indicators to provide clear feedback to the user.

2.  **Performance Optimization:**
    *   Profile the app, focusing on image loading, grid scrolling, and state management.
    *   Optimize file I/O operations.

3.  **Testing:**
    *   Write unit tests for business logic (metadata handling, API service).
    *   Write widget tests for UI components.
    *   Conduct thorough manual testing on macOS.

4.  **macOS Build & Distribution:**
    *   Configure macOS build settings in `macos/Runner/Configs/AppInfo.xcconfig` and `macos/Runner.xcodeproj` (app icon, bundle identifier, version).
    *   Implement code signing for distribution.
    *   Build the release application (`flutter build macos`).
    *   Consider creating a `.dmg` installer package.

## Technology Stack Summary

*   **Framework:** Flutter (targeting macOS initially)
*   **UI:** `macos_ui` package
*   **AI:** Google Gemini (via `flutter_gemini` package)
*   **Language:** Dart
*   **State Management:** Riverpod / Provider (TBD)
*   **File System Access:** `dart:io`, `path_provider`
*   **User File Selection:** `file_picker`
*   **Secure Storage:** `flutter_secure_storage`
*   **Metadata Storage:** JSON files (or potentially `isar`/`sqflite`)
