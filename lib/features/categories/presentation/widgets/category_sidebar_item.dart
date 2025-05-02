import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/utils/context_menu.dart';

import '../../domain/models/category.dart';


class CategorySidebarItem extends ConsumerWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onImportSuggested;

  const CategorySidebarItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onImportSuggested,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? MacosTheme.of(context).primaryColor.withAlpha(26) : null, // 0.1 opacity = ~26 alpha
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            MacosIcon(category.icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.title,
                style: MacosTheme.of(context).typography.body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMacosContextMenu(
      context: context,
      position: position,
      items: [
        MacosContextMenuItem(
          title: const Text('Edit Category'),
          onClick: onEdit,
        ),
        MacosContextMenuItem(
          title: const Text('Delete Category'),
          onClick: onDelete,
        ),
        const MacosContextMenuDivider(),
        MacosContextMenuItem(
          title: const Text('Import based on description...'),
          onClick: onImportSuggested,
        ),
      ],
    );
  }
}