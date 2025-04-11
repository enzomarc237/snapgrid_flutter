import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import 'batch_tag_dialog.dart';

import '../providers/screenshot_providers.dart';

/// A toolbar that appears when screenshots are selected
class SelectionToolbar extends ConsumerWidget {
  /// Creates a SelectionToolbar widget
  const SelectionToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPaths = ref.watch(selectedScreenshotsProvider);
    final count = selectedPaths.length;

    // Don't show the toolbar if no screenshots are selected
    if (count == 0) {
      return const SizedBox.shrink();
    }

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
      child: Row(
        children: [
          // Selection count
          Text(
            '$count selected',
            style: MacosTheme.of(context).typography.title3,
          ),
          const Spacer(),

          // Manage Tags button
          PushButton(
            controlSize: ControlSize.regular,
            secondary: true,
            onPressed: () {
              BatchTagDialog.show(context, selectedPaths);
            },
            child: Row(
              children: const [
                MacosIcon(CupertinoIcons.tag, size: 16),
                SizedBox(width: 4),
                Text('Manage Tags'),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Analyze button
          PushButton(
            controlSize: ControlSize.regular,
            secondary: true,
            onPressed: () {
              ref
                  .read(screenshotActionsProvider)
                  .analyzeSelectedScreenshots(context);
            },
            child: Row(
              children: const [
                MacosIcon(CupertinoIcons.wand_stars, size: 16),
                SizedBox(width: 4),
                Text('Analyze All'),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Delete button
          PushButton(
            controlSize: ControlSize.regular,
            secondary: true,
            onPressed: () {
              ref
                  .read(screenshotActionsProvider)
                  .deleteSelectedScreenshots(context);
            },
            child: Row(
              children: const [
                MacosIcon(CupertinoIcons.trash, size: 16),
                SizedBox(width: 4),
                Text('Delete'),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Clear selection button
          PushButton(
            controlSize: ControlSize.regular,
            secondary: true,
            onPressed: () {
              ref.read(selectedScreenshotsProvider.notifier).deselectAll();
            },
            child: const Text('Clear Selection'),
          ),
        ],
      ),
    );
  }
}
