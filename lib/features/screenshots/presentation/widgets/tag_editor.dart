import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../domain/models/screenshot.dart';
import '../providers/tag_providers.dart';
import 'tag_chip.dart';

/// A widget for editing tags on a screenshot
class TagEditor extends ConsumerStatefulWidget {
  /// The screenshot to edit tags for
  final Screenshot screenshot;
  
  /// Creates a TagEditor widget
  const TagEditor({
    super.key,
    required this.screenshot,
  });

  @override
  ConsumerState<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends ConsumerState<TagEditor> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  
  @override
  void dispose() {
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }
  
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty) {
      ref.read(tagActionsProvider).addTag(widget.screenshot, tag);
      _tagController.clear();
      _tagFocusNode.requestFocus();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: MacosTheme.of(context).typography.headline.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Favorite button
            MacosTooltip(
              message: widget.screenshot.isFavorite ? 'Remove from favorites' : 'Add to favorites',
              child: PushButton(
                controlSize: ControlSize.small,
                secondary: !widget.screenshot.isFavorite,
                onPressed: () {
                  ref.read(tagActionsProvider).toggleFavorite(widget.screenshot);
                },
                child: Row(
                  children: [
                    MacosIcon(
                      widget.screenshot.isFavorite
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      size: 14,
                      color: widget.screenshot.isFavorite
                          ? MacosColors.white
                          : MacosColors.systemPinkColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.screenshot.isFavorite ? 'Favorited' : 'Favorite',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Add tag input
        Row(
          children: [
            Expanded(
              child: MacosTextField(
                controller: _tagController,
                focusNode: _tagFocusNode,
                placeholder: 'Add a tag...',
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: _addTag,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Tags list
        if (widget.screenshot.tags.isEmpty)
          Text(
            'No tags yet. Add some tags to help organize your screenshots.',
            style: MacosTheme.of(context).typography.body.copyWith(
              color: MacosColors.systemGrayColor,
            ),
          )
        else
          Wrap(
            children: [
              ...widget.screenshot.tags.map((tag) => TagChip(
                tag: tag,
                onRemove: () {
                  ref.read(tagActionsProvider).removeTag(widget.screenshot, tag);
                },
              )),
            ],
          ),
      ],
    );
  }
}
