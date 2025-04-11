import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/widgets/themed_progress_circle.dart';

import '../../../../main.dart';

import '../providers/screenshot_providers.dart' hide allTagsProvider;
import '../providers/tag_providers.dart'
    hide selectedTagProvider, showFavoritesOnlyProvider;

/// A dialog for adding or removing tags from multiple screenshots
class BatchTagDialog extends ConsumerStatefulWidget {
  /// The selected screenshot paths
  final Set<String> selectedPaths;

  /// Creates a BatchTagDialog
  const BatchTagDialog({super.key, required this.selectedPaths});

  /// Shows the batch tag dialog
  static Future<void> show(
    BuildContext context,
    Set<String> selectedPaths,
  ) async {
    // Use the global navigator key's context if available, otherwise use the provided context
    final effectiveContext = navigatorKey.currentContext ?? context;

    await showDialog(
      context: effectiveContext,
      builder:
          (_) => MacosWindow(
            child: ContentArea(
              builder: (context, scrollController) {
                return Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 600,
                      height: 500,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MacosTheme.of(context).canvasColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x33000000),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            children: [
                              const MacosIcon(CupertinoIcons.tag, size: 32),
                              const SizedBox(width: 8),
                              Text(
                                'Manage Tags for ${selectedPaths.length} Screenshots',
                                style: MacosTheme.of(context).typography.title1,
                              ),
                              const Spacer(),
                              MacosIconButton(
                                icon: const MacosIcon(
                                  CupertinoIcons.xmark_circle,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Dialog content
                          Expanded(
                            child: BatchTagDialog(selectedPaths: selectedPaths),
                          ),

                          // Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PushButton(
                                controlSize: ControlSize.large,
                                child: const Text('Close'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  @override
  ConsumerState<BatchTagDialog> createState() => _BatchTagDialogState();
}

class _BatchTagDialogState extends ConsumerState<BatchTagDialog> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  bool _isAddingTag = false;

  @override
  void dispose() {
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenshotsAsync = ref.watch(screenshotsProvider);
    final allTagsAsync = ref.watch(allTagsProvider);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add tag input
            Row(
              children: [
                Expanded(
                  child: MacosTextField(
                    controller: _tagController,
                    focusNode: _tagFocusNode,
                    placeholder: 'Add a tag to all selected screenshots...',
                    onSubmitted: (_) => _addTagToAll(),
                  ),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: _isAddingTag ? null : _addTagToAll,
                  child:
                      _isAddingTag
                          ? const ThemedProgressCircle(value: null, radius: 8)
                          : const Text('Add to All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Available tags section
            Text(
              'Available Tags',
              style: MacosTheme.of(context).typography.title3,
            ),
            const SizedBox(height: 8),

            // Tags list
            Expanded(
              child: allTagsAsync.when(
                data: (tags) {
                  if (tags.isEmpty) {
                    return Center(
                      child: Text(
                        'No tags available yet. Add some tags to help organize your screenshots.',
                        style: MacosTheme.of(context).typography.body.copyWith(
                          color: MacosColors.systemGrayColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return screenshotsAsync.when(
                    data: (screenshots) {
                      // Filter screenshots to only include selected ones
                      final selectedScreenshots =
                          screenshots
                              .where(
                                (s) =>
                                    widget.selectedPaths.contains(s.filePath),
                              )
                              .toList();

                      return ListView.builder(
                        itemCount: tags.length,
                        itemBuilder: (context, index) {
                          final tag = tags[index];

                          // Count how many selected screenshots have this tag
                          final screenshotsWithTag =
                              selectedScreenshots
                                  .where((s) => s.tags.contains(tag))
                                  .length;

                          // Determine if all, some, or none of the selected screenshots have this tag
                          final allHaveTag =
                              screenshotsWithTag == selectedScreenshots.length;
                          final someHaveTag =
                              screenshotsWithTag > 0 &&
                              screenshotsWithTag < selectedScreenshots.length;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: MacosIcon(
                                CupertinoIcons.tag,
                                color: MacosTheme.of(context).primaryColor,
                              ),
                              title: Text(tag),
                              subtitle: Text(
                                allHaveTag
                                    ? 'All selected screenshots have this tag'
                                    : someHaveTag
                                    ? '$screenshotsWithTag of ${selectedScreenshots.length} selected screenshots have this tag'
                                    : 'None of the selected screenshots have this tag',
                                style:
                                    MacosTheme.of(
                                      context,
                                    ).typography.subheadline,
                              ),
                              trailing: SizedBox(
                                width: 80,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Add to all button (only show if not all have the tag)
                                    if (!allHaveTag)
                                      MacosTooltip(
                                        message:
                                            'Add to all selected screenshots',
                                        child: MacosIconButton(
                                          icon: const MacosIcon(
                                            CupertinoIcons.plus_circle,
                                            color: MacosColors.systemGreenColor,
                                          ),
                                          onPressed:
                                              () =>
                                                  _addTagToAllScreenshots(tag),
                                        ),
                                      ),

                                    // Remove from all button (only show if any have the tag)
                                    if (allHaveTag || someHaveTag)
                                      MacosTooltip(
                                        message:
                                            'Remove from all selected screenshots',
                                        child: MacosIconButton(
                                          icon: const MacosIcon(
                                            CupertinoIcons.minus_circle,
                                            color: MacosColors.systemRedColor,
                                          ),
                                          onPressed:
                                              () =>
                                                  _removeTagFromAllScreenshots(
                                                    tag,
                                                  ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: ThemedProgressCircle()),
                    error:
                        (_, __) => const Center(
                          child: Text('Error loading screenshots'),
                        ),
                  );
                },
                loading: () => const Center(child: ThemedProgressCircle()),
                error:
                    (_, __) => const Center(child: Text('Error loading tags')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTagToAll() async {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;

    setState(() {
      _isAddingTag = true;
    });

    try {
      await _addTagToAllScreenshots(tag);
      _tagController.clear();
      _tagFocusNode.requestFocus();
    } finally {
      setState(() {
        _isAddingTag = false;
      });
    }
  }

  Future<void> _addTagToAllScreenshots(String tag) async {
    final screenshotsAsync = ref.read(screenshotsProvider);
    final screenshots = screenshotsAsync.value ?? [];

    // Filter screenshots to only include selected ones
    final selectedScreenshots =
        screenshots
            .where((s) => widget.selectedPaths.contains(s.filePath))
            .toList();

    // Add tag to all selected screenshots
    final tagActions = ref.read(tagActionsProvider);
    for (final screenshot in selectedScreenshots) {
      await tagActions.addTag(screenshot, tag);
    }
  }

  Future<void> _removeTagFromAllScreenshots(String tag) async {
    final screenshotsAsync = ref.read(screenshotsProvider);
    final screenshots = screenshotsAsync.value ?? [];

    // Filter screenshots to only include selected ones
    final selectedScreenshots =
        screenshots
            .where((s) => widget.selectedPaths.contains(s.filePath))
            .toList();

    // Remove tag from all selected screenshots
    final tagActions = ref.read(tagActionsProvider);
    for (final screenshot in selectedScreenshots) {
      if (screenshot.tags.contains(tag)) {
        await tagActions.removeTag(screenshot, tag);
      }
    }
  }
}
