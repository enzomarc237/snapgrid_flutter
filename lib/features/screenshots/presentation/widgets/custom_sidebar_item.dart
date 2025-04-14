// Add CustomSidebarItem code
// ... existing code ...
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../categories/domain/models/category.dart';
import '../screens/main_screen.dart'; // Import selectedCategoryIdProvider

class CustomSidebarItem extends ConsumerWidget {
  const CustomSidebarItem({
    Key? key,
    required this.category,
  }) : super(key: key);

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(selectedCategoryIdProvider) == category.id;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? MacosTheme.of(context).primaryColor.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
          padding: EdgeInsets.all(4.0),
      child:Row(children: [
         MacosIcon(category.icon),
         Text(category.title),
         ],)
    ),
  );
  }
}
// ... existing code ...