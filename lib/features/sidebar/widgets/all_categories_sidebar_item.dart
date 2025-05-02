import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/screenshots/presentation/screens/main_screen.dart';
import '../../../providers/screenshot_providers.dart';
import 'generic_sidebar_item.dart';

/// A specialized sidebar item for the "All Categories" option
class AllCategoriesSidebarItem extends ConsumerWidget {
  /// Creates an AllCategoriesSidebarItem
  const AllCategoriesSidebarItem({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    
    return GenericSidebarItem(
      title: 'Toutes les catégories',
      icon: CupertinoIcons.square_grid_2x2,
      isSelected: selectedCategoryId == null,
      isCategory: true,
      onTap: () {
        // Navigate to screenshots view
        ref.read(mainNavigationProvider.notifier).setPageIndex(0);
        // Clear category selection (show all categories)
        ref.read(selectedCategoryIdProvider.notifier).state = null;
        // Clear any screenshot selection
        ref.read(selectedScreenshotProvider.notifier).state = null;
      },
    );
  }
}