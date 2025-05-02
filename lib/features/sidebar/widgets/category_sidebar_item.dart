import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/context_menu.dart';
import '../../../features/categories/domain/models/category.dart';
import '../../../features/screenshots/presentation/providers/screenshot_providers.dart';
import '../../../features/screenshots/presentation/screens/main_screen.dart';
import 'generic_sidebar_item.dart';

/// A specialized sidebar item for categories with drag-drop and context menu support
class CategorySidebarItem extends ConsumerWidget {
  /// Creates a CategorySidebarItem
  const CategorySidebarItem({
    Key? key,
    required this.category,
    this.onEdit,
    this.onDelete,
    this.onImportSuggested,
  }) : super(key: key);

  /// The category to display
  final Category category;
  
  /// Optional callback for editing the category
  final VoidCallback? onEdit;
  
  /// Optional callback for deleting the category
  final VoidCallback? onDelete;
  
  /// Optional callback for importing suggestions based on the category
  final VoidCallback? onImportSuggested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(selectedCategoryIdProvider) == category.id;
    final screenshotActions = ref.read(screenshotActionsProvider);
    
    return GenericSidebarItem(
      title: category.title,
      icon: category.icon,
      isSelected: isSelected,
      isCategory: true,
      onTap: () {
        // Navigate to screenshots view
        ref.read(mainNavigationProvider.notifier).setPageIndex(0);
        // Set the selected category
        ref.read(selectedCategoryIdProvider.notifier).state = category.id;
        // Clear any screenshot selection
        ref.read(selectedScreenshotProvider.notifier).state = null;
      },
      onDragAccept: (String jsonData) {
        try {
          final data = jsonDecode(jsonData) as Map<String, dynamic>;
          final screenshotId = data['id'] as String?;
          final screenshotPath = data['filePath'] as String?;

          if (screenshotId != null && screenshotPath != null) {
            screenshotActions.assignCategory(
              screenshotId,
              screenshotPath,
              category.id,
            );
          } else {
            print('Error: Dropped data missing id or filePath.');
          }
        } catch (e) {
          print('Error decoding dropped data: $e');
        }
      },
      onSecondaryTapDown: onEdit != null || onDelete != null || onImportSuggested != null
          ? (details) => _showContextMenu(context, details.globalPosition)
          : null,
    );
  }

  /// Shows a context menu for the category with edit/delete options
  void _showContextMenu(BuildContext context, Offset position) {
    final menuItems = <MacosContextMenuItem>[];
    
    if (onEdit != null) {
      menuItems.add(
        MacosContextMenuItem(
          title: const Text('Edit Category'),
          onClick: onEdit!,
        ),
      );
    }
    
    if (onDelete != null) {
      menuItems.add(
        MacosContextMenuItem(
          title: const Text('Delete Category'),
          onClick: onDelete!,
        ),
      );
    }
    
    if (onImportSuggested != null) {
      // Add separator if there are previous items
      if (menuItems.isNotEmpty) {
        menuItems.add(MacosContextMenuItem(title: const Text(''), separator: true, onClick: () {  },));
      }
      
      menuItems.add(
        MacosContextMenuItem(
          title: const Text('Import based on description...'),
          onClick: onImportSuggested!,
        ),
      );
    }
    
    // Show the menu if there are items
    if (menuItems.isNotEmpty) {
      showMacosContextMenu(
        context: context,
        position: position,
        items: menuItems,
      );
    }
  }
}