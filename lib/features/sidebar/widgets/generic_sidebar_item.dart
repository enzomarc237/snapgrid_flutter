import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

/// A standardized sidebar item component for both pages and categories
/// 
/// This component can be used for any type of sidebar item with consistent styling
/// and supports drag-drop functionality when needed.
class GenericSidebarItem extends StatelessWidget {
  /// Creates a GenericSidebarItem
  const GenericSidebarItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.onDragAccept,
    this.isCategory = false,
    this.onSecondaryTapDown,
  }) : super(key: key);

  /// The title text to display
  final String title;
  
  /// The icon to display
  final IconData icon;
  
  /// Whether this item is currently selected
  final bool isSelected;
  
  /// Callback when the item is tapped
  final VoidCallback onTap;
  
  /// Optional callback for drag-drop functionality
  /// Accepts a String (usually JSON data)
  final Function(String)? onDragAccept;
  
  /// Whether this item represents a category (affects styling)
  final bool isCategory;
  
  /// Optional callback for secondary (right) click
  /// Used to show context menus for categories
  final Function(TapDownDetails)? onSecondaryTapDown;

  @override
  Widget build(BuildContext context) {
    // Use MacosTheme for proper macOS styling and dark mode adaptation
    final macosTheme = MacosTheme.of(context);
    final brightness = macosTheme.brightness;
    
    // Determine text and icon color based on selection and theme brightness
    final Color textColor = isSelected
        ? CupertinoColors.white
        : brightness == Brightness.dark
            ? CupertinoColors.white
            : CupertinoColors.black;

    // Determine background color for selected items
    final Color backgroundColor = isSelected
        ? macosTheme.primaryColor
        : Colors.transparent;

    final item = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onSecondaryTapDown: onSecondaryTapDown,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: MacosListTile(
          leading: MacosIcon(icon, color: textColor),
          title: Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ),
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