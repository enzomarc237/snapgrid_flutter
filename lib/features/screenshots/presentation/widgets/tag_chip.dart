import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// A widget that displays a tag as a chip
class TagChip extends StatelessWidget {
  /// The tag text to display
  final String tag;
  
  /// Whether the tag is selected
  final bool isSelected;
  
  /// Callback when the tag is tapped
  final VoidCallback? onTap;
  
  /// Callback when the tag is removed
  final VoidCallback? onRemove;
  
  /// Creates a TagChip widget
  const TagChip({
    super.key,
    required this.tag,
    this.isSelected = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? MacosTheme.of(context).primaryColor
              : MacosTheme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? MacosTheme.of(context).primaryColor
                : MacosTheme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: MacosTheme.of(context).typography.body.copyWith(
                    color: isSelected
                        ? MacosColors.white
                        : MacosTheme.of(context).typography.body.color,
                  ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: MacosIcon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 16,
                  color: isSelected
                      ? MacosColors.white
                      : MacosTheme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
