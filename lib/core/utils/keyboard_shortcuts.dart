import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/screenshots/domain/models/screenshot.dart';
import '../../features/screenshots/presentation/providers/focus_providers.dart';
import '../../features/screenshots/presentation/providers/screenshot_providers.dart';

/// A class that manages keyboard shortcuts for the application
class KeyboardShortcuts {
  /// Handles keyboard shortcuts for the main screen
  static Widget buildMainScreenShortcuts({
    required Widget child,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Import shortcuts
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyI):
            const ImportScreenshotsIntent(),

        // Filter shortcuts
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF):
            const FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyT):
            const ClearFiltersIntent(),

        // Selection shortcuts
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA):
            const SelectAllIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const ClearSelectionIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.backspace):
            const DeleteSelectedIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ImportScreenshotsIntent: CallbackAction<ImportScreenshotsIntent>(
            onInvoke: (intent) => _importScreenshots(context, ref),
          ),
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(
            onInvoke: (intent) => _focusSearch(ref),
          ),
          ClearFiltersIntent: CallbackAction<ClearFiltersIntent>(
            onInvoke: (intent) => _clearFilters(ref),
          ),
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (intent) => _selectAllScreenshots(ref),
          ),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (intent) => _clearSelection(ref),
          ),
          DeleteSelectedIntent: CallbackAction<DeleteSelectedIntent>(
            onInvoke: (intent) => _deleteSelectedScreenshots(context, ref),
          ),
        },
        child: child,
      ),
    );
  }

  /// Handles keyboard shortcuts for the detail screen
  static Widget buildDetailScreenShortcuts({
    required Widget child,
    required BuildContext context,
    required WidgetRef ref,
    required Screenshot screenshot,
  }) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Navigation shortcuts
        LogicalKeySet(LogicalKeyboardKey.escape): const BackToGridIntent(),

        // Screenshot actions
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA):
            const AnalyzeScreenshotIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyD):
            const DeleteScreenshotIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BackToGridIntent: CallbackAction<BackToGridIntent>(
            onInvoke: (intent) => _backToGrid(ref),
          ),
          AnalyzeScreenshotIntent: CallbackAction<AnalyzeScreenshotIntent>(
            onInvoke: (intent) => _analyzeScreenshot(context, ref, screenshot),
          ),
          DeleteScreenshotIntent: CallbackAction<DeleteScreenshotIntent>(
            onInvoke: (intent) => _deleteScreenshot(context, ref, screenshot),
          ),
        },
        child: child,
      ),
    );
  }

  // Action implementations

  static Future<void> _importScreenshots(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref.read(screenshotActionsProvider).pickScreenshots(context);
  }

  static void _focusSearch(WidgetRef ref) {
    final focusNode = ref.read(searchFocusNodeProvider);
    // Request focus in the next frame to avoid focus overlay issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  static void _clearFilters(WidgetRef ref) {
    ref.read(searchQueryProvider.notifier).state = '';
  }

  static void _selectAllScreenshots(WidgetRef ref) {
    final screenshotsAsync = ref.read(screenshotsProvider);
    final screenshots = screenshotsAsync.value ?? [];
    if (screenshots.isEmpty) return;

    final paths = screenshots.map((s) => s.filePath).toList();
    ref.read(selectedScreenshotsProvider.notifier).selectAll(paths);
  }

  static void _clearSelection(WidgetRef ref) {
    ref.read(selectedScreenshotsProvider.notifier).deselectAll();
  }

  static Future<void> _deleteSelectedScreenshots(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedPaths = ref.read(selectedScreenshotsProvider);
    if (selectedPaths.isEmpty) return;

    await ref
        .read(screenshotActionsProvider)
        .deleteSelectedScreenshots(context);
  }

  static void _backToGrid(WidgetRef ref) {
    ref.read(selectedScreenshotProvider.notifier).state = null;
  }

  static Future<void> _analyzeScreenshot(
    BuildContext context,
    WidgetRef ref,
    Screenshot screenshot,
  ) async {
    await ref
        .read(screenshotActionsProvider)
        .analyzeScreenshot(screenshot, context);
  }

  static Future<void> _deleteScreenshot(
    BuildContext context,
    WidgetRef ref,
    Screenshot screenshot,
  ) async {
    await ref
        .read(screenshotActionsProvider)
        .deleteScreenshot(screenshot, context);
  }
}

// Intents

/// Intent to import screenshots
class ImportScreenshotsIntent extends Intent {
  /// Creates an ImportScreenshotsIntent
  const ImportScreenshotsIntent();
}

/// Intent to focus the search field
class FocusSearchIntent extends Intent {
  /// Creates a FocusSearchIntent
  const FocusSearchIntent();
}

/// Intent to clear all filters
class ClearFiltersIntent extends Intent {
  /// Creates a ClearFiltersIntent
  const ClearFiltersIntent();
}

/// Intent to go back to the grid view
class BackToGridIntent extends Intent {
  /// Creates a BackToGridIntent
  const BackToGridIntent();
}

/// Intent to analyze a screenshot
class AnalyzeScreenshotIntent extends Intent {
  /// Creates an AnalyzeScreenshotIntent
  const AnalyzeScreenshotIntent();
}

/// Intent to delete a screenshot
class DeleteScreenshotIntent extends Intent {
  /// Creates a DeleteScreenshotIntent
  const DeleteScreenshotIntent();
}

/// Intent to select all screenshots
class SelectAllIntent extends Intent {
  /// Creates a SelectAllIntent
  const SelectAllIntent();
}

/// Intent to clear selection
class ClearSelectionIntent extends Intent {
  /// Creates a ClearSelectionIntent
  const ClearSelectionIntent();
}

/// Intent to delete selected screenshots
class DeleteSelectedIntent extends Intent {
  /// Creates a DeleteSelectedIntent
  const DeleteSelectedIntent();
}
