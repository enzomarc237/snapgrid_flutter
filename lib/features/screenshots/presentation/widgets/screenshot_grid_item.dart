import 'dart:async'; // Import for Completer
import 'dart:io';
import 'dart:ui' as ui; // Needed for ui.Image

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Keep for RawKeyboard, maybe TextStyle
import 'package:flutter/services.dart'
    show HardwareKeyboard, LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart';

import '../../../../core/widgets/themed_icon.dart';
import '../../../../core/widgets/themed_progress_circle.dart'; // For placeholder
import '../../domain/models/screenshot.dart';
import '../providers/screenshot_providers.dart';

/// Widget that displays a single screenshot in the grid, adapting to image aspect ratio.
class ScreenshotGridItem extends ConsumerStatefulWidget {
  final Screenshot screenshot;

  const ScreenshotGridItem({super.key, required this.screenshot});

  @override
  ConsumerState<ScreenshotGridItem> createState() => _ScreenshotGridItemState();
}

class _ScreenshotGridItemState extends ConsumerState<ScreenshotGridItem> {
  Size? _imageSize; // Store the loaded size

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure context is available if needed later,
    // although not strictly necessary for this async operation.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadImageSize());
  }

  // Function to load image dimensions
  Future<void> _loadImageSize() async {
    // Prevent unnecessary work if the widget is disposed before completion
    if (!mounted) return;

    final completer = Completer<ui.Image>();
    final file = File(widget.screenshot.filePath);

    try {
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        // Use decodeImageFromList for potential compatibility
        ui.decodeImageFromList(bytes, (ui.Image img) {
          if (!completer.isCompleted) completer.complete(img);
        });

        final image = await completer.future.timeout(
          const Duration(seconds: 5),
        ); // Add timeout

        if (mounted) {
          setState(() {
            _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          });
        }
      } else {
        debugPrint(
          "File not found for size calculation: ${widget.screenshot.filePath}",
        );
        if (mounted) {
          setState(() {
            _imageSize = null;
          }); // Indicate file not found
        }
      }
    } catch (e) {
      debugPrint(
        "Error decoding image dimensions for ${widget.screenshot.filePath}: $e",
      );
      if (mounted) {
        setState(() {
          _imageSize = null;
        }); // Indicate error or use default aspect ratio
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read providers needed for selection state
    final selectedPath = ref.watch(selectedScreenshotProvider);
    final selectedPaths = ref.watch(selectedScreenshotsProvider);

    // Check if this screenshot is selected
    final isDetailSelected = selectedPath == widget.screenshot.filePath;
    final isMultiSelected = selectedPaths.contains(widget.screenshot.filePath);
    final isSelected = isDetailSelected || isMultiSelected;

    final fileSize =
        File(widget.screenshot.filePath).statSync().size / 1024 / 1024;

    // Determine aspect ratio for the AspectRatio widget
    final double aspectRatio =
        (_imageSize != null && _imageSize!.height > 0)
            ? _imageSize!.width / _imageSize!.height
            : 16 / 10; // Default aspect ratio

    return GestureDetector(
      onTap: () {
        // Read ref inside the callback where needed
        final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
        final currentSelectedPaths = ref.read(
          selectedScreenshotsProvider,
        ); // Read current state
        final isMultiSelectMode = currentSelectedPaths.isNotEmpty;

        if (isMultiSelectMode) {
          if (isShiftPressed) {
            final screenshotsAsync = ref.read(
              screenshotsProvider,
            ); // Read for paths
            final screenshots = screenshotsAsync.value ?? [];
            final paths = screenshots.map((s) => s.filePath).toList();
            ref
                .read(selectedScreenshotsProvider.notifier)
                .selectRange(widget.screenshot.filePath, paths);
          } else {
            ref
                .read(selectedScreenshotsProvider.notifier)
                .toggle(widget.screenshot.filePath);
          }
        } else {
          if (isDetailSelected) {
            ref.read(selectedScreenshotProvider.notifier).state = null;
          } else {
            ref.read(selectedScreenshotProvider.notifier).state =
                widget.screenshot.filePath;
          }
        }
      },
      onLongPress: () {
        debugPrint(
          'Long press detected on ${basename(widget.screenshot.filePath)}',
        );
        // Start multi-select mode with this item
        ref
            .read(selectedScreenshotsProvider.notifier)
            .toggle(widget.screenshot.filePath);

        // Show a macOS dialog instead of SnackBar
        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const MacosIcon(CupertinoIcons.selection_pin_in_out),
                title: const Text('Multi-Select Activated'),
                message: const Text(
                  'Tap other screenshots to add them to the selection.',
                ),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );
      },
      child: MacosTooltip(
        message:
            '${basename(widget.screenshot.filePath)}\nLong-press to select multiple screenshots\n\nSize: ${fileSize.toStringAsFixed(2)} MB',
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
                    ? MacosTheme.of(context).primaryColor.withAlpha(25)
                    : null,
          ),
          child: Stack(
            children: [
              // Screenshot image wrapped in AspectRatio
              AspectRatio(
                aspectRatio: aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  // Show placeholder until size is loaded, then show image
                  child:
                      _imageSize == null
                          ? Container(
                            // Placeholder
                            color: MacosTheme.of(
                              context,
                            ).dividerColor.withOpacity(0.1),
                            child: const Center(
                              child: ThemedProgressCircle(),
                            ), // Use themed progress
                          )
                          : Image.file(
                            // Actual image
                            File(widget.screenshot.filePath),
                            fit: BoxFit.cover, // Cover the aspect ratio box
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                'Error loading image ${basename(widget.screenshot.filePath)}: $error',
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

              // Favorite indicator
              if (widget.screenshot.isFavorite)
                Positioned(
                  top: 8,
                  // Adjust position based on selection checkmark visibility
                  right: isMultiSelected ? 36 : 8,
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
