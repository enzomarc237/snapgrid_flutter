import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // Added

import '../../../../core/widgets/themed_icon.dart';
import '../../../categories/presentation/providers/category_providers.dart'; // Added for category info
import '../providers/focus_providers.dart';
// import '../providers/tag_providers.dart'; // Tag filtering is now handled within filteredScreenshotsProvider

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/screenshot_providers.dart';
import '../screens/main_screen.dart'; // Added for selectedCategoryIdProvider
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
    // Watch the final filtered provider which includes category filtering
    final finalScreenshotsAsync = ref.watch(categoryFilteredScreenshotsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider); // Needed for empty state context

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
                // Use the final provider here
                child: finalScreenshotsAsync.when(
                  data: (screenshots) {
                    if (screenshots.isEmpty) {
                      return _buildEmptyState(context, ref, selectedCategoryId);
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount;
                        if (constraints.maxWidth < 600) {
                          crossAxisCount = 2;
                        } else if (constraints.maxWidth < 900) {
                          crossAxisCount = 3;
                        } else {
                          crossAxisCount = 4;
                        }

                        return MasonryGridView.count(
                          padding: const EdgeInsets.all(16),
                          crossAxisCount: crossAxisCount, // Dynamic number of columns
                          mainAxisSpacing: 24, // Spacing between items vertically
                          crossAxisSpacing: 24, // Spacing between items horizontally
                          itemCount: screenshots.length,
                          itemBuilder: (context, index) {
                            final screenshot = screenshots[index];
                            // ScreenshotGridItem will determine its own height based on the image
                            return ScreenshotGridItem(screenshot: screenshot);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (error, stackTrace) => ErrorView(
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

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String? selectedCategoryId) {
    // Check filters to provide context for the empty state
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final showFavoritesOnly = ref.watch(showFavoritesOnlyProvider);
    // final selectedCategoryId = ref.watch(selectedCategoryIdProvider); // Already passed as argument

    String title = 'No screenshots yet';
    String subtitle = 'Drop images here or click Add';
    IconData icon = CupertinoIcons.photo_on_rectangle;
    Widget? actionButton = PushButton(
      controlSize: ControlSize.large,
      child: const Text('Add Screenshot'),
      onPressed: () {
        ref.read(screenshotActionsProvider).pickScreenshots(context);
      },
    );

    if (selectedCategoryId != null) {
       // Get category name for the message
       final categoryAsync = ref.watch(categoryListProvider);
       final categoryName = categoryAsync.whenData((categories) {
         try {
           return categories.firstWhere((c) => c.id == selectedCategoryId).title;
         } catch (_) {
           return 'Selected Category'; // Fallback if category not found
         }
       }).valueOrNull ?? 'Selected Category';

       title = 'No screenshots in "$categoryName"';
       subtitle = 'Drag and drop screenshots here or use the "Import" option in the category menu.';
       icon = CupertinoIcons.folder_badge_plus;
       actionButton = null; // No primary add button when category is selected
    } else if (searchQuery.isNotEmpty || selectedTag != null || showFavoritesOnly) {
      title = 'No matching screenshots found';
      subtitle = 'Try adjusting your search or filters';
      icon = CupertinoIcons.search;
      actionButton = PushButton(
        controlSize: ControlSize.regular, // Smaller button
        secondary: true,
        child: const Text('Clear Filters'),
        onPressed: () {
          ref.read(searchQueryProvider.notifier).state = '';
          ref.read(selectedTagProvider.notifier).state = null;
          ref.read(showFavoritesOnlyProvider.notifier).state = false;
          // Optionally clear category filter too?
          // ref.read(selectedCategoryIdProvider.notifier).state = null;
        },
      );
    }

    // Build the empty state UI
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MacosIcon(
            icon,
            size: 64,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: MacosTheme.of(context).typography.largeTitle.copyWith(color: MacosColors.systemGrayColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: MacosTheme.of(context).typography.headline.copyWith(color: MacosColors.systemGrayColor),
            textAlign: TextAlign.center,
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 16),
            actionButton,
          ],
        ],
      ),
    );
  }
}
