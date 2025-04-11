import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../main.dart';

/// A dialog that displays keyboard shortcuts help
class KeyboardShortcutsHelp extends StatelessWidget {
  /// Creates a KeyboardShortcutsHelp widget
  const KeyboardShortcutsHelp({super.key});

  /// Shows the keyboard shortcuts help dialog
  static void show(BuildContext context) {
    // Use the global navigator key's context if available, otherwise use the provided context
    final effectiveContext = navigatorKey.currentContext ?? context;

    showMacosAlertDialog(
      context: effectiveContext,
      builder:
          (_) => MacosAlertDialog(
            appIcon: const MacosIcon(CupertinoIcons.keyboard, size: 56),
            title: const Text('Keyboard Shortcuts'),
            message: const KeyboardShortcutsHelp(),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              child: const Text('Close'),
              onPressed: () => Navigator.of(effectiveContext).pop(),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 400,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutSection(context, 'Navigation', {
              '⌘ + 1': 'Go to Screenshots',
              '⌘ + 2': 'Go to Settings',
              'ESC': 'Back to grid (from detail view)',
            }),
            const SizedBox(height: 16),
            _buildShortcutSection(context, 'Screenshots Management', {
              '⌘ + I': 'Import screenshots',
              '⌘ + D': 'Delete selected screenshot',
              '⌘ + A': 'Select all screenshots / Analyze screenshot',
              '⌘ + Backspace': 'Delete selected screenshots',
              'ESC': 'Clear selection',
            }),
            const SizedBox(height: 16),
            _buildShortcutSection(context, 'Filtering & Organization', {
              '⌘ + F': 'Focus search field',
              '⌘ + T': 'Clear all filters',
              '⌘ + H': 'Toggle favorites filter/status',
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutSection(
    BuildContext context,
    String title,
    Map<String, String> shortcuts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: MacosTheme.of(context).typography.title3),
        const SizedBox(height: 8),
        ...shortcuts.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: MacosColors.controlBackgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: MacosTheme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    entry.key,
                    style: MacosTheme.of(context).typography.body.copyWith(
                      fontFamily: 'Menlo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    entry.value,
                    style: MacosTheme.of(context).typography.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
