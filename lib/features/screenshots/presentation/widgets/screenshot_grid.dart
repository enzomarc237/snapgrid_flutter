import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../../../../core/widgets/themed_icon.dart';

import '../providers/focus_providers.dart';
import '../providers/tag_providers.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/screenshot_providers.dart';
import 'screenshot_grid_item.dart';
import 'selection_toolbar.dart';
import 'tag_filter_bar.dart';

/// Widget that displays a grid of screenshots
class ScreenshotGrid extends ConsumerStatefulWidget {
  /// Creates a ScreenshotGrid widget
  const ScreenshotGrid({super.key});

  @override
  ConsumerState<ScreenshotGrid> createState() => _ScreenshotGridState();
}

class _ScreenshotGridState extends ConsumerState<ScreenshotGrid> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final screenshotsAsync = ref.watch(filteredScreenshotsProvider);
    final tagFilteredScreenshots = ref.watch(tagFilteredScreenshotsProvider);

    // Combine both filters
    final combinedScreenshotsAsync = screenshotsAsync.when(
      data: (searchFiltered) {
        return tagFilteredScreenshots.when(
          data: (tagFiltered) {
            // If both have data, find the intersection
            if (searchFiltered.isEmpty || tagFiltered.isEmpty) {
              // If either is empty, return the empty one
              return AsyncValue.data(
                searchFiltered.isEmpty ? searchFiltered : tagFiltered,
              );
            }

            // Find screenshots that are in both lists
            final filePaths = searchFiltered.map((s) => s.filePath).toSet();
            final result =
                tagFiltered
                    .where((s) => filePaths.contains(s.filePath))
                    .toList();
            return AsyncValue.data(result);
          },
          loading: () => screenshotsAsync,
          error: (error, stackTrace) => screenshotsAsync,
        );
      },
      loading: () => screenshotsAsync,
      error: (error, stackTrace) => screenshotsAsync,
    );

    return DropTarget(
      onDragDone: (details) async {
        // Handle the dropped files
        if (details.files.isNotEmpty) {
          final paths = details.files.map((file) => file.path).toList();
          await ref
              .read(screenshotActionsProvider)
              .importDroppedFiles(paths, context);
        }
      },
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      child: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: MacosSearchField(
                  focusNode: ref.watch(searchFocusNodeProvider),
                  placeholder:
                      'Search screenshots by content, elements, colors... (⌘F)',
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                ),
              ),

              // Tag filter bar
              const TagFilterBar(),

              // Selection toolbar
              const SelectionToolbar(),

              // Screenshots grid
              Expanded(
                child: combinedScreenshotsAsync.when(
                  data: (screenshots) {
                    if (screenshots.isEmpty) {
                      return _buildEmptyState(context, ref);
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio:
                                16 / 10, // Common screenshot aspect ratio
                          ),
                      itemCount: screenshots.length,
                      itemBuilder: (context, index) {
                        final screenshot = screenshots[index];
                        return ScreenshotGridItem(screenshot: screenshot);
                      },
                    );
                  },
                  loading: () => const LoadingView(),
                  error:
                      (error, stackTrace) => ErrorView(
                        message: 'Error loading screenshots: $error',
                        actionButton: PushButton(
                          controlSize: ControlSize.large,
                          child: const Text('Retry'),
                          onPressed: () {
                            ref.invalidate(screenshotsProvider);
                          },
                        ),
                      ),
                ),
              ),
            ],
          ),
          // Overlay when dragging
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: MacosTheme.of(context).canvasColor.withAlpha(230),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ThemedIcon(
                        CupertinoIcons.arrow_down_circle,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Drop screenshots here',
                        style: MacosTheme.of(context).typography.title1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    // Check if it's empty due to search filter
    final searchQuery = ref.watch(searchQueryProvider);
    if (searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MacosIcon(
              CupertinoIcons.search,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No matching screenshots found',
              style: MacosTheme.of(
                context,
              ).typography.title3.copyWith(color: MacosColors.systemGrayColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: MacosTheme.of(
                context,
              ).typography.body.copyWith(color: MacosColors.systemGrayColor),
            ),
          ],
        ),
      );
    }

    // Otherwise show the default empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MacosIcon(
            CupertinoIcons.photo_on_rectangle,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No screenshots yet',
            style: MacosTheme.of(
              context,
            ).typography.title3.copyWith(color: MacosColors.systemGrayColor),
          ),
          const SizedBox(height: 8),
          PushButton(
            controlSize: ControlSize.large,
            child: const Text('Add Screenshot'),
            onPressed: () {
              ref.read(screenshotActionsProvider).pickScreenshots(context);
            },
          ),
        ],
      ),
    );
  }
}
