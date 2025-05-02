import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../categories/domain/models/category.dart';
import '../screens/main_screen.dart';
import '../providers/screenshot_providers.dart';

/// A generic sidebar item that can be used for both pages and categories
class GenericSidebarItem extends ConsumerWidget {
  const GenericSidebarItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.onDragAccept,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(String)? onDragAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use MacosTheme for proper macOS styling and dark mode adaptation
    final macosTheme = MacosTheme.of(context);
    final brightness = macosTheme.brightness;
    
    // Determine text and icon color based on selection and theme brightness
    final Color color = isSelected
        ? CupertinoColors.white
        : brightness == Brightness.dark
            ? CupertinoColors.white
            : CupertinoColors.black;

    // Determine background color for selected items
    final Color backgroundColor = isSelected
        ? macosTheme.primaryColor
        : Colors.transparent;

    final item = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: MacosListTile(
        leading: MacosIcon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        onClick: onTap,
      ),
    );

    // If drag acceptance is provided, wrap in DragTarget
    if (onDragAccept != null) {
      return DragTarget<String>(
        builder: (context, accepted, rejected) => item,
        onAccept: onDragAccept,
        onWillAccept: (_) => true,
      );
    }

    return item;
  }
}

/// A sidebar item specifically for categories with drag-drop support
class CategorySidebarItem extends ConsumerWidget {
  const CategorySidebarItem({Key? key, required this.category}) : super(key: key);

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(selectedCategoryIdProvider) == category.id;
    final screenshotActions = ref.read(screenshotActionsProvider);
    
    return GenericSidebarItem(
      title: category.title,
      icon: category.icon,
      isSelected: isSelected,
      onTap: () {
        ref.read(mainNavigationProvider.notifier).setPageIndex(0);
        ref.read(selectedCategoryIdProvider.notifier).state = category.id;
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
            print('Erreur: Données glissées manquantes id ou filePath.');
          }
        } catch (e) {
          print('Erreur de décodage des données glissées: $e');
        }
      },
    );
  }
}