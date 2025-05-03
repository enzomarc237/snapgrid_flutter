import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

/// A widget that displays a palette of colors as rounded squares
/// with tooltips showing the hex color code and click-to-copy functionality
class ColorPaletteWidget extends StatefulWidget {
  /// The map of color names to hex values
  final Map<String, String> colors;

  /// Creates a ColorPaletteWidget
  const ColorPaletteWidget({
    super.key,
    required this.colors,
  });

  @override
  State<ColorPaletteWidget> createState() => _ColorPaletteWidgetState();
}

class _ColorPaletteWidgetState extends State<ColorPaletteWidget> {
  OverlayEntry? _copiedOverlay;

  @override
  void dispose() {
    _removeCopiedToast();
    super.dispose();
  }

  void _removeCopiedToast() {
    _copiedOverlay?.remove();
    _copiedOverlay = null;
  }

  void _showCopiedToast(BuildContext context, String value) {
    _removeCopiedToast();

    _copiedOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MacosTheme.of(context).brightness == Brightness.dark
                    ? MacosColors.controlBackgroundColor.darkColor
                    : MacosColors.controlBackgroundColor.color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text('Copied: $value'),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_copiedOverlay!);
    Future.delayed(const Duration(seconds: 2), _removeCopiedToast);
  }

  Color _hexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.colors.entries.map((entry) {
        // Parse the hex color
        Color color;
        try {
          final hexColor = entry.key.trim();
          if (hexColor.startsWith('#')) {
            color = _hexToColor(hexColor);
          } else if (hexColor.startsWith('0x')) {
            color = Color(int.parse(hexColor.substring(2), radix: 16) | 0xFF000000);
          } else {
            // Try to parse as hex without # prefix
            color = _hexToColor('#$hexColor');
          }
        } catch (e) {
          // Fallback to a default color if parsing fails
          color = CupertinoColors.systemGrey;
        }

        final hexValue = entry.key.trim();
        final colorName = entry.value;
        
        return Tooltip(
          message: '$colorName: $hexValue',
          mouseCursor: MouseCursor.defer,
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: hexValue));
              _showCopiedToast(context, hexValue);
            },
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: MacosTheme.of(context).brightness == Brightness.dark
                          ? CupertinoColors.white.withOpacity(0.2)
                          : CupertinoColors.black.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  colorName,
                  style: TextStyle(
                    fontSize: 10,
                    color: MacosTheme.of(context).brightness == Brightness.dark
                        ? MacosColors.white
                        : MacosColors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
