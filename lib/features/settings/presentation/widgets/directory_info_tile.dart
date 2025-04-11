import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

/// Widget that displays information about a directory
class DirectoryInfoTile extends StatelessWidget {
  /// The title of the directory
  final String title;
  
  /// The path of the directory
  final String path;
  
  /// A description of the directory
  final String description;

  /// Creates a DirectoryInfoTile
  const DirectoryInfoTile({
    super.key,
    required this.title,
    required this.path,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            MacosTheme.of(context).brightness == Brightness.dark
                ? MacosColors.controlBackgroundColor.darkColor
                : MacosColors.controlBackgroundColor.color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: MacosTheme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and description
          Text(
            title,
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: MacosTheme.of(context).typography.subheadline,
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Path display with copy button
          Row(
            children: [
              Expanded(
                child: Text(
                  path,
                  style: MacosTheme.of(
                    context,
                  ).typography.body.copyWith(fontFamily: 'Menlo', fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                child: const Text('Copy'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: path));
                  
                  // Show a tooltip or snackbar to indicate the path was copied
                  final tooltip = OverlayEntry(
                    builder: (context) => Positioned(
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
                                color: MacosColors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MacosIcon(
                                CupertinoIcons.checkmark_circle,
                                color: MacosColors.systemGreenColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Path copied to clipboard',
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
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
