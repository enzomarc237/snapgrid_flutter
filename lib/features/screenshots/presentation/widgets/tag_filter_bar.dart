import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/widgets/themed_progress_circle.dart';

import '../providers/screenshot_providers.dart';
import 'tag_chip.dart';

/// A widget that displays a horizontal list of tags for filtering
class TagFilterBar extends ConsumerWidget {
  /// Creates a TagFilterBar widget
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final showFavoritesOnly = ref.watch(showFavoritesOnlyProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        border: Border(
          bottom: BorderSide(
            color: MacosTheme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MacosIcon(CupertinoIcons.tag, size: 16),
              const SizedBox(width: 8),
              Text(
                'Filter by:',
                style: MacosTheme.of(context).typography.subheadline,
              ),
              const SizedBox(width: 16),

              // Favorites filter
              GestureDetector(
                onTap: () {
                  ref.read(showFavoritesOnlyProvider.notifier).state =
                      !showFavoritesOnly;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        showFavoritesOnly
                            ? MacosColors.systemPinkColor
                            : MacosTheme.of(context).canvasColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          showFavoritesOnly
                              ? MacosColors.systemPinkColor
                              : MacosTheme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MacosIcon(
                        CupertinoIcons.heart_fill,
                        size: 14,
                        color:
                            showFavoritesOnly
                                ? MacosColors.white
                                : MacosColors.systemPinkColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Favorites',
                        style: MacosTheme.of(context).typography.body.copyWith(
                          color:
                              showFavoritesOnly
                                  ? MacosColors.white
                                  : MacosTheme.of(
                                    context,
                                  ).typography.body.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Multi-select button
              PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: () {
                  // Get all screenshots and select them
                  final screenshotsAsync = ref.read(screenshotsProvider);
                  final screenshots = screenshotsAsync.value ?? [];
                  if (screenshots.isEmpty) return;

                  final paths = screenshots.map((s) => s.filePath).toList();
                  ref
                      .read(selectedScreenshotsProvider.notifier)
                      .selectAll(paths);
                },
                child: Row(
                  children: const [
                    MacosIcon(CupertinoIcons.checkmark_circle, size: 14),
                    SizedBox(width: 4),
                    Text('Select All'),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Clear filters button
              if (selectedTag != null || showFavoritesOnly)
                PushButton(
                  controlSize: ControlSize.small,
                  secondary: true,
                  onPressed: () {
                    ref.read(selectedTagProvider.notifier).state = null;
                    ref.read(showFavoritesOnlyProvider.notifier).state = false;
                  },
                  child: const Text('Clear Filters'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Tags list
          tagsAsync.when(
            data: (tags) {
              if (tags.isEmpty) {
                return const SizedBox.shrink();
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...tags.map(
                      (tag) => TagChip(
                        tag: tag,
                        isSelected: tag == selectedTag,
                        onTap: () {
                          // Toggle selection
                          if (tag == selectedTag) {
                            ref.read(selectedTagProvider.notifier).state = null;
                          } else {
                            ref.read(selectedTagProvider.notifier).state = tag;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading:
                () => const SizedBox(
                  height: 24,
                  child: ThemedProgressCircle(value: null, radius: 8),
                ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
