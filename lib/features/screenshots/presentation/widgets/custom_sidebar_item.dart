// Add CustomSidebarItem code
// ... existing code ...
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../categories/domain/models/category.dart';
import '../screens/main_screen.dart'; // Import selectedCategoryIdProvider
import '../providers/screenshot_providers.dart';

class CustomSidebarItem extends ConsumerWidget {
  const CustomSidebarItem({Key? key, required this.category}) : super(key: key);

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(selectedCategoryIdProvider) == category.id;
    final color =
        isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: MacosListTile(
        leading: MacosIcon(category.icon, color: color),
        title: Text(
          category.title,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        onClick: () {
          ref.read(mainNavigationProvider.notifier).setPageIndex(0);
          ref.read(selectedCategoryIdProvider.notifier).state = category.id;
          ref.read(selectedScreenshotProvider.notifier).state = null;
        },
      ),
    );
  }
}
// ... existing code ...