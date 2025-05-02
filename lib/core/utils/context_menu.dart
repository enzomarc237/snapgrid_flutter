import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

/// Shows a macOS-style context menu
void showMacosContextMenu({
  required BuildContext context,
  required Offset position,
  required List<Widget> items,
}) {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  showCupertinoMenu(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(
        position,
        position,
      ),
      Offset.zero & overlay.size,
    ),
    items: items,
  );
}

/// Shows a Cupertino menu which looks similar to macOS context menu
void showCupertinoMenu({
  required BuildContext context,
  required RelativeRect position,
  required List<Widget> items,
}) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) {
      return CupertinoActionSheet(
        actions: items,
      );
    },
  );
}

/// A menu item for macOS context menus
class MacosContextMenuItem extends StatelessWidget {
  final Widget title;
  final VoidCallback onClick;

  const MacosContextMenuItem({
    super.key,
    required this.title,
    required this.onClick,
    this.separator = false,
  });

  final bool separator;

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheetAction(
      child: title,
      onPressed: () {
        Navigator.of(context).pop();
        onClick();
      },
    );
  }
}

/// A divider for macOS context menus
class MacosContextMenuDivider extends StatelessWidget {
  const MacosContextMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: MacosTheme.of(context).dividerColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}