import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

/// A widget that displays a list of detected fonts
class FontListWidget extends StatelessWidget {
  /// The list of detected fonts
  final List<String> fonts;

  /// Creates a FontListWidget
  const FontListWidget({
    super.key,
    required this.fonts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fonts.map((font) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MacosTheme.of(context).brightness == Brightness.dark
                  ? MacosColors.controlBackgroundColor.darkColor
                  : MacosColors.controlBackgroundColor.color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: MacosTheme.of(context).brightness == Brightness.dark
                    ? CupertinoColors.white.withOpacity(0.1)
                    : CupertinoColors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const MacosIcon(
                  CupertinoIcons.textformat,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    font,
                    style: TextStyle(
                      fontFamily: _tryToMatchFont(font),
                      fontSize: 14,
                      color: MacosTheme.of(context).brightness == Brightness.dark
                          ? MacosColors.white
                          : MacosColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Try to match the font name to a system font if possible
  String? _tryToMatchFont(String fontName) {
    // Common system fonts that might match the detected fonts
    final Map<String, String> fontMappings = {
      'helvetica': 'Helvetica',
      'arial': 'Arial',
      'san francisco': 'SF Pro',
      'sf pro': 'SF Pro',
      'times': 'Times New Roman',
      'times new roman': 'Times New Roman',
      'georgia': 'Georgia',
      'roboto': 'Roboto',
      'open sans': 'Open Sans',
      'montserrat': 'Montserrat',
      'lato': 'Lato',
      'poppins': 'Poppins',
    };

    final lowerFontName = fontName.toLowerCase();
    for (final entry in fontMappings.entries) {
      if (lowerFontName.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default to system font if no match
    return null;
  }
}
