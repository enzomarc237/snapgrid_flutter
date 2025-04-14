import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/widgets/themed_icon.dart';
import '../../../../core/widgets/themed_progress_circle.dart';
import '../../../../features/settings/presentation/providers/settings_providers.dart';
import 'package:path/path.dart';

import '../../../categories/presentation/providers/category_providers.dart'; // Needed for selectedCategoryIdProvider import? No, it's in main_screen.dart
import '../../domain/models/screenshot.dart';
import '../../domain/repositories/screenshot_repository.dart';
import '../../data/repositories/screenshot_repository_impl.dart';
// Import the provider defined in main_screen.dart - THIS IS NOT IDEAL
// It's better to move selectedCategoryIdProvider to a shared location or this file.
// For now, we assume it's accessible, but this might need refactoring.
import '../screens/main_screen.dart'; // Temporary import for selectedCategoryIdProvider

/// Provider for the screenshot repository
final screenshotRepositoryProvider = Provider<ScreenshotRepository>((ref) {
  // Pass the ref to the repository implementation
  return ScreenshotRepositoryImpl(ref: ref);
  // No need to cast if ScreenshotRepositoryImpl implements ScreenshotRepository
});

/// Provider for all screenshots
final screenshotsProvider = FutureProvider<List<Screenshot>>((ref) async {
  final repository = ref.watch(screenshotRepositoryProvider);
  return repository.getAllScreenshots();
});

/// Provider for the current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for the selected tag filter
final selectedTagProvider = StateProvider<String?>((ref) => null);

/// Provider for the favorites filter
final showFavoritesOnlyProvider = StateProvider<bool>((ref) => false);

/// Provider for all available tags
final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(screenshotRepositoryProvider);
  return repository.getAllTags();
});

/// Provider for screenshot sort order
final screenshotSortByProvider = StateProvider<String>((ref) => 'date');
final screenshotSortAscendingProvider = StateProvider<bool>((ref) => false);

/// Provider for filtered and sorted screenshots based on search, tag, favorite, and sort order
final filteredScreenshotsProvider = Provider<AsyncValue<List<Screenshot>>>((
  ref,
) {
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final selectedTag = ref.watch(selectedTagProvider);
  final showFavoritesOnly = ref.watch(showFavoritesOnlyProvider);
  final sortBy = ref.watch(screenshotSortByProvider);
  final ascending = ref.watch(screenshotSortAscendingProvider);
  final screenshotsAsync = ref.watch(screenshotsProvider);

  return screenshotsAsync.when(
    data: (screenshots) {
      var filtered = screenshots;

      // Filter by tag
      if (selectedTag != null && selectedTag.isNotEmpty) {
        filtered = filtered.where((s) => s.tags.contains(selectedTag)).toList();
      }

      // Filter by favorites
      if (showFavoritesOnly) {
        filtered = filtered.where((s) => s.isFavorite).toList();
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        filtered =
            filtered.where((screenshot) {
              if (screenshot.filePath.toLowerCase().contains(searchQuery)) {
                return true;
              }
              if (screenshot.tags.any(
                (tag) => tag.toLowerCase().contains(searchQuery),
              )) {
                return true;
              }
              // Check UI type in analysis results
              if (screenshot.analysisResults != null &&
                  screenshot.analysisResults!['uiType'] != null &&
                  screenshot.analysisResults!['uiType']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery)) {
                return true;
              }
              return false;
            }).toList();
      }

      // Sort
      filtered.sort((a, b) {
        int cmp;
        switch (sortBy) {
          case 'name':
            cmp = a.filePath.compareTo(b.filePath);
            break;
          case 'type':
            // Compare UI types from analysis results
            final aType = a.analysisResults?['uiType']?.toString() ?? '';
            final bType = b.analysisResults?['uiType']?.toString() ?? '';
            cmp = aType.compareTo(bType);
            break;
          case 'date':
          default:
            cmp = a.importDate.compareTo(b.importDate);
        }
        return ascending ? cmp : -cmp;
      });

      return AsyncValue.data(filtered);
    },
    loading: () => screenshotsAsync,
    error: (error, stackTrace) => screenshotsAsync,
  );
});

/// Provider that further filters screenshots based on the selected category.
final categoryFilteredScreenshotsProvider =
    Provider<AsyncValue<List<Screenshot>>>((ref) {
      // Watch the previously filtered list (search, tag, favorite, sort)
      final baseFilteredAsync = ref.watch(filteredScreenshotsProvider);
      // Watch the selected category ID from the sidebar
      final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

      // If no category is selected, return the base filtered list
      if (selectedCategoryId == null) {
        return baseFilteredAsync;
      }

      // If a category is selected, filter the base list further
      return baseFilteredAsync.when(
        data: (screenshots) {
          final categoryFiltered =
              screenshots
                  .where((s) => s.categoryId == selectedCategoryId)
                  .toList();
          return AsyncValue.data(categoryFiltered);
        },
        // Pass through loading and error states
        loading: () => baseFilteredAsync,
        error: (error, stackTrace) => baseFilteredAsync,
      );
    });

/// Provider for the currently selected screenshot (for detail view)
final selectedScreenshotProvider = StateProvider<String?>((ref) => null);

/// Provider for multi-selected screenshots
final selectedScreenshotsProvider =
    StateNotifierProvider<SelectedScreenshotsNotifier, Set<String>>((ref) {
      return SelectedScreenshotsNotifier();
    });

/// Notifier for managing multi-selected screenshots
class SelectedScreenshotsNotifier extends StateNotifier<Set<String>> {
  SelectedScreenshotsNotifier() : super({});

  // Keep track of the last selected item for range selection
  String? _lastSelectedPath;

  /// Toggles selection of a screenshot
  void toggle(String path) {
    if (state.contains(path)) {
      state = Set.from(state)..remove(path);
    } else {
      state = Set.from(state)..add(path);
    }
    _lastSelectedPath = path;
  }

  /// Selects a screenshot
  void select(String path) {
    if (!state.contains(path)) {
      state = Set.from(state)..add(path);
    }
    _lastSelectedPath = path;
  }

  /// Deselects a screenshot
  void deselect(String path) {
    if (state.contains(path)) {
      state = Set.from(state)..remove(path);
    }
  }

  /// Selects all screenshots
  void selectAll(List<String> paths) {
    state = Set.from(paths);
    _lastSelectedPath = paths.isNotEmpty ? paths.last : null;
  }

  /// Deselects all screenshots
  void deselectAll() {
    state = {};
    _lastSelectedPath = null;
  }

  /// Selects a range of screenshots
  void selectRange(String path, List<String> allPaths) {
    // If no previous selection, just select this item
    if (_lastSelectedPath == null || state.isEmpty) {
      select(path);
      return;
    }

    // Find indices of the last selected and current items
    final lastIndex = allPaths.indexOf(_lastSelectedPath!);
    final currentIndex = allPaths.indexOf(path);

    // If either item is not found, just select the current item
    if (lastIndex == -1 || currentIndex == -1) {
      select(path);
      return;
    }

    // Determine the range (inclusive)
    final startIndex = lastIndex < currentIndex ? lastIndex : currentIndex;
    final endIndex = lastIndex < currentIndex ? currentIndex : lastIndex;

    // Select all items in the range
    final newState = Set<String>.from(state);
    for (int i = startIndex; i <= endIndex; i++) {
      newState.add(allPaths[i]);
    }

    state = newState;
    _lastSelectedPath = path;
  }

  /// Checks if a screenshot is selected
  bool isSelected(String path) {
    return state.contains(path);
  }

  /// Gets the number of selected screenshots
  int get count => state.length;
}

/// Provider for screenshot actions
final screenshotActionsProvider = Provider<ScreenshotActions>((ref) {
  return ScreenshotActions(ref);
});

/// Class for screenshot-related actions
class ScreenshotActions {
  final Ref _ref;

  ScreenshotActions(this._ref);

  /// Picks screenshots from the file system
  Future<void> pickScreenshots(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final paths =
            result.files
                .where((file) => file.path != null)
                .map((file) => file.path!)
                .toList();

        if (context.mounted) {
          await importDroppedFiles(paths, context);
        }
      }
    } catch (e) {
      debugPrint('Error picking screenshot: $e');
      if (context.mounted) {
        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const MacosIcon(
                  CupertinoIcons.exclamationmark_triangle,
                ),
                title: const Text('Error'),
                message: Text('Failed to pick screenshot: $e'),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );
      }
    }
  }

  /// Deletes a screenshot
  Future<void> deleteScreenshot(
    Screenshot screenshot,
    BuildContext context,
  ) async {
    try {
      // Show confirmation dialog
      final shouldDelete =
          await showMacosAlertDialog<bool>(
            context: context,
            builder:
                (_) => MacosAlertDialog(
                  appIcon: const MacosIcon(CupertinoIcons.trash),
                  title: const Text('Delete Screenshot'),
                  message: Text(
                    'Are you sure you want to delete "${basename(screenshot.filePath)}"?',
                  ),
                  primaryButton: PushButton(
                    controlSize: ControlSize.large,
                    child: const Text('Delete'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  secondaryButton: PushButton(
                    controlSize: ControlSize.large,
                    secondary: true,
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
          ) ??
          false;

      if (shouldDelete) {
        final repository = _ref.read(screenshotRepositoryProvider);
        await repository.deleteScreenshot(screenshot);

        // Clear selection if the deleted screenshot was selected
        final selectedPath = _ref.read(selectedScreenshotProvider);
        if (selectedPath == screenshot.filePath) {
          _ref.read(selectedScreenshotProvider.notifier).state = null;
        }

        // Remove from multi-selection if selected
        _ref
            .read(selectedScreenshotsProvider.notifier)
            .deselect(screenshot.filePath);

        // Refresh the list after deleting
        _ref.invalidate(screenshotsProvider);
      }
    } catch (e) {
      debugPrint('Error deleting screenshot: $e');
      if (context.mounted) {
        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const MacosIcon(
                  CupertinoIcons.exclamationmark_triangle,
                ),
                title: const Text('Error'),
                message: Text('Failed to delete screenshot: $e'),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );
      }
    }
  }

  /// Analyzes a screenshot
  /// Imports files that were dropped onto the app
  Future<void> importDroppedFiles(
    List<String> paths,
    BuildContext context,
  ) async {
    try {
      final repository = _ref.read(screenshotRepositoryProvider);
      final importedScreenshots = await repository.importScreenshots(paths);

      // Refresh the list after importing (already done in importScreenshots)
      _ref.invalidate(
        screenshotsProvider,
      ); // Not needed, invalidate is in repository impl

      // Trigger analysis for each imported screenshot
      // for (final screenshot in importedScreenshots) {
      // analyzeScreenshot(screenshot, context); // Call analyze for each
      // }

      // Show success message
      if (context.mounted && paths.isNotEmpty) {
        final message =
            paths.length == 1
                ? 'Screenshot imported successfully'
                : '${paths.length} screenshots imported successfully';

        final tooltip = OverlayEntry(
          builder:
              (context) => Positioned(
                right: 16,
                bottom: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: MacosColors.controlBackgroundColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: MacosColors.black.withAlpha(
                            51,
                          ), // ~0.2 opacity
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ThemedIcon(
                          CupertinoIcons.checkmark_circle,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message,
                          style: MacosTheme.of(context).typography.body,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        );

        // Add the tooltip to the overlay
        Overlay.of(context).insert(tooltip);

        // Remove the tooltip after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          tooltip.remove();
        });
      }
    } catch (e) {
      debugPrint('Error importing dropped files: $e');
      if (context.mounted) {
        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const MacosIcon(
                  CupertinoIcons.exclamationmark_triangle,
                ),
                title: const Text('Error'),
                message: Text('Failed to import screenshots: $e'),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );
      }
    }
  }

  /// Deletes multiple screenshots
  Future<void> deleteSelectedScreenshots(BuildContext context) async {
    final selectedPaths = _ref.read(selectedScreenshotsProvider);
    if (selectedPaths.isEmpty) return;

    // Get screenshots from paths
    final screenshotsAsync = _ref.read(screenshotsProvider);
    final screenshots = screenshotsAsync.value ?? [];
    final selectedScreenshots =
        screenshots.where((s) => selectedPaths.contains(s.filePath)).toList();

    if (selectedScreenshots.isEmpty) return;

    // Show confirmation dialog
    final shouldDelete =
        await showMacosAlertDialog<bool>(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const MacosIcon(CupertinoIcons.trash),
                title: const Text('Delete Screenshots'),
                message: Text(
                  'Are you sure you want to delete ${selectedScreenshots.length} screenshots? This action cannot be undone.',
                ),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () => Navigator.of(context).pop(true),
                  color: MacosColors.systemRedColor,
                  child: const Text('Delete'),
                ),
                secondaryButton: PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
        ) ??
        false;

    if (shouldDelete) {
      try {
        final repository = _ref.read(screenshotRepositoryProvider);
        int successCount = 0;

        // Show progress dialog
        if (context.mounted) {
          showMacosAlertDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (_) => MacosAlertDialog(
                  appIcon: const MacosIcon(CupertinoIcons.trash),
                  title: const Text('Deleting Screenshots'),
                  message: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Please wait while the screenshots are being deleted...',
                      ),
                      const SizedBox(height: 16),
                      const ThemedProgressCircle(),
                    ],
                  ),
                  primaryButton: PushButton(
                    controlSize: ControlSize.large,
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
          );
        }

        // Delete each screenshot
        for (final screenshot in selectedScreenshots) {
          try {
            await repository.deleteScreenshot(screenshot);
            successCount++;
          } catch (e) {
            debugPrint(
              'Error deleting screenshot ${basename(screenshot.filePath)}: $e',
            );
          }
        }

        // Clear selection
        _ref.read(selectedScreenshotsProvider.notifier).deselectAll();

        // Clear detail view if selected screenshot was deleted
        final selectedScreenshot = _ref.read(selectedScreenshotProvider);
        if (selectedScreenshot != null &&
            selectedPaths.contains(selectedScreenshot)) {
          _ref.read(selectedScreenshotProvider.notifier).state = null;
        }

        // Refresh the list after deleting
        _ref.invalidate(screenshotsProvider);

        // Close progress dialog and show result
        if (context.mounted) {
          Navigator.of(context).pop(); // Close progress dialog

          showMacosAlertDialog(
            context: context,
            builder:
                (_) => MacosAlertDialog(
                  appIcon: const MacosIcon(
                    CupertinoIcons.checkmark_circle,
                    color: MacosColors.systemGreenColor,
                  ),
                  title: const Text('Success'),
                  message: Text(
                    successCount == selectedScreenshots.length
                        ? '$successCount screenshots deleted successfully.'
                        : '$successCount of ${selectedScreenshots.length} screenshots deleted successfully.',
                  ),
                  primaryButton: PushButton(
                    controlSize: ControlSize.large,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
          );
        }
      } catch (e) {
        debugPrint('Error in batch delete: $e');
        if (context.mounted) {
          Navigator.of(context).pop(); // Close progress dialog if open

          showMacosAlertDialog(
            context: context,
            builder:
                (_) => MacosAlertDialog(
                  appIcon: const ThemedIcon(
                    CupertinoIcons.exclamationmark_triangle,
                  ),
                  title: const Text('Error'),
                  message: Text('Failed to delete screenshots: $e'),
                  primaryButton: PushButton(
                    controlSize: ControlSize.large,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
          );
        }
      }
    }
  }

  Future<void> analyzeScreenshot(
    Screenshot screenshot,
    BuildContext context,
  ) async {
    try {
      // Show loading dialog
      if (context.mounted) {
        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const ThemedIcon(CupertinoIcons.wand_stars),
                title: const Text('Analyzing Screenshot'),
                message: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please wait while the AI analyzes your screenshot...',
                    ),
                    const SizedBox(height: 16),
                    const ThemedProgressCircle(),
                  ],
                ),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                ),
              ),
        );
      }

      final repository = _ref.read(screenshotRepositoryProvider);
      await repository.analyzeScreenshot(screenshot);

      // Refresh the list after analyzing
      _ref.invalidate(screenshotsProvider);

      // Close the dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close the dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop();

        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const ThemedIcon(
                  CupertinoIcons.exclamationmark_triangle,
                ),
                title: const Text('Analysis Failed'),
                message: Text('Error: $e'),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );
      }
    }
  }

  /// Analyzes multiple screenshots
  Future<void> analyzeSelectedScreenshots(BuildContext context) async {
    final selectedPaths = _ref.read(selectedScreenshotsProvider);
    if (selectedPaths.isEmpty) return;

    // Get screenshots from paths
    final screenshotsAsync = _ref.read(screenshotsProvider);
    final screenshots = screenshotsAsync.value ?? [];
    final selectedScreenshots =
        screenshots.where((s) => selectedPaths.contains(s.filePath)).toList();

    if (selectedScreenshots.isEmpty) return;

    try {
      // Show progress dialog
      if (context.mounted) {
        showMacosAlertDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const ThemedIcon(CupertinoIcons.wand_stars),
                title: const Text('Analyzing Screenshots'),
                message: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Please wait while the AI analyzes ${selectedScreenshots.length} screenshots...',
                    ),
                    const SizedBox(height: 16),
                    const ThemedProgressCircle(),
                  ],
                ),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );
      }

      final repository = _ref.read(screenshotRepositoryProvider);
      int successCount = 0;
      int failCount = 0;

      // Analyze each screenshot
      for (final screenshot in selectedScreenshots) {
        try {
          await repository.analyzeScreenshot(screenshot);
          successCount++;
        } catch (e) {
          debugPrint(
            'Error analyzing screenshot ${basename(screenshot.filePath)}: $e',
          );
          failCount++;
        }
      }

      // Refresh the list after analyzing
      _ref.invalidate(screenshotsProvider);

      // Close progress dialog and show result
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog

        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const MacosIcon(
                  CupertinoIcons.checkmark_circle,
                  color: MacosColors.systemGreenColor,
                ),
                title: const Text('Analysis Complete'),
                message: Text(
                  failCount == 0
                      ? '$successCount screenshots analyzed successfully.'
                      : '$successCount of ${selectedScreenshots.length} screenshots analyzed successfully. $failCount failed.',
                ),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );
      }
    } catch (e) {
      debugPrint('Error in batch analysis: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog if open

        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const ThemedIcon(
                  CupertinoIcons.exclamationmark_triangle,
                ),
                title: const Text('Error'),
                message: Text('Failed to analyze screenshots: $e'),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );
      }
    }
  }
}
