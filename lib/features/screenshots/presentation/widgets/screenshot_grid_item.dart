import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/widgets/themed_icon.dart';

import 'package:path/path.dart';
import '../../domain/models/screenshot.dart';
import '../providers/screenshot_providers.dart';

/// Widget that displays a single screenshot in the grid
class ScreenshotGridItem extends ConsumerWidget {
  /// The screenshot to display
  final Screenshot screenshot;

  /// Creates a ScreenshotGridItem widget
  const ScreenshotGridItem({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPath = ref.watch(selectedScreenshotProvider);
    final selectedPaths = ref.watch(selectedScreenshotsProvider);

    // Check if this screenshot is selected in either the detail view or multi-selection
    final isDetailSelected = selectedPath == screenshot.filePath;
    final isMultiSelected = selectedPaths.contains(screenshot.filePath);
    final isSelected = isDetailSelected || isMultiSelected;

    return GestureDetector(
      onTap: () {
        // Check if Shift key is pressed for range selection
        final isShiftPressed =
            RawKeyboard.instance.keysPressed.contains(
              LogicalKeyboardKey.shiftLeft,
            ) ||
            RawKeyboard.instance.keysPressed.contains(
              LogicalKeyboardKey.shiftRight,
            );

        // Check if we're in multi-select mode (items already selected)
        final isMultiSelectMode = selectedPaths.isNotEmpty;

        if (isMultiSelectMode) {
          if (isShiftPressed) {
            // Get all screenshots for range selection
            final screenshotsAsync = ref.read(screenshotsProvider);
            final screenshots = screenshotsAsync.value ?? [];
            final paths = screenshots.map((s) => s.filePath).toList();

            // Select range
            ref
                .read(selectedScreenshotsProvider.notifier)
                .selectRange(screenshot.filePath, paths);
          } else {
            // Toggle multi-selection
            ref
                .read(selectedScreenshotsProvider.notifier)
                .toggle(screenshot.filePath);
          }
        } else {
          // Toggle detail view selection
          if (isDetailSelected) {
            ref.read(selectedScreenshotProvider.notifier).state = null;
          } else {
            ref.read(selectedScreenshotProvider.notifier).state =
                screenshot.filePath;
          }
        }
      },
      onLongPress: () {
        debugPrint('Long press detected on ${basename(screenshot.filePath)}');
        // Start multi-select mode with this item
        ref
            .read(selectedScreenshotsProvider.notifier)
            .toggle(screenshot.filePath);

        // Show a snackbar to inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Multi-select mode activated. Tap to select more items.',
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      },
      child: MacosTooltip(
        message:
            '${basename(screenshot.filePath)}\nLong-press to select multiple screenshots',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border:
                isSelected
                    ? Border.all(
                      color: MacosTheme.of(context).primaryColor,
                      width: 2.5,
                    )
                    : Border.all(
                      color: MacosTheme.of(context).dividerColor,
                      width: 0.5,
                    ),
            boxShadow: [
              BoxShadow(
                color:
                    MacosTheme.of(context).brightness == Brightness.dark
                        ? MacosColors.black.withAlpha(76) // ~0.3 opacity
                        : MacosColors.black.withAlpha(25), // ~0.1 opacity
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            color:
                isSelected
                    ? MacosTheme.of(context).primaryColor.withAlpha(
                      25,
                    ) // ~0.1 opacity
                    : null,
          ),
          child: Stack(
            children: [
              // Screenshot image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(screenshot.filePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      'Error loading image ${basename(screenshot.filePath)}: $error',
                    );
                    return Container(
                      color: MacosTheme.of(context).canvasColor,
                      child: const Center(
                        child: ThemedIcon(
                          CupertinoIcons.exclamationmark_triangle,
                          size: 24,
                          color: MacosColors.systemRedColor,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Selection indicator
              if (isMultiSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: MacosColors.systemBlueColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const MacosIcon(
                      CupertinoIcons.checkmark,
                      color: MacosColors.white,
                      size: 16,
                    ),
                  ),
                ),

              // Analysis indicator
              // if (screenshot.analysisComplete && !isMultiSelected)
              //   Positioned(
              //     top: 8,
              //     right: 8,
              //     child: Container(
              //       padding: const EdgeInsets.all(4),
              //       decoration: BoxDecoration(
              //         color: MacosTheme.of(
              //           context,
              //         ).canvasColor.withAlpha(204), // ~0.8 opacity
              //         borderRadius: BorderRadius.circular(4),
              //       ),
              //       child: ThemedIcon(CupertinoIcons.wand_stars, size: 16),
              //     ),
              //   ),

              // Favorite indicator
              if (screenshot.isFavorite)
                Positioned(
                  top: 8,
                  right: isMultiSelected /*|| screenshot.analysisComplete*/ ? 36 : 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: MacosTheme.of(
                        context,
                      ).canvasColor.withAlpha(204), // ~0.8 opacity
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const ThemedIcon(
                      CupertinoIcons.heart_fill,
                      color: MacosColors.systemPinkColor,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
