import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:file_picker/file_picker.dart';

import '../../main.dart';

import '../../features/screenshots/presentation/providers/screenshot_providers.dart';
import '../../features/screenshots/presentation/widgets/batch_tag_dialog.dart';
import '../../core/widgets/keyboard_shortcuts_help.dart';

/// Provider for the selected tab index
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Builds the platform menu bar for the app
class AppPlatformMenuBar {
  /// Imports screenshots
  static Future<void> _importScreenshots(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final picker = FilePicker.platform;
    final result = await picker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'heic'],
    );

    if (result != null && result.files.isNotEmpty) {
      final paths = result.files.map((file) => file.path!).toList();
      final repository = ref.read(screenshotRepositoryProvider);
      await repository.importScreenshots(paths);

      // Refresh the list after importing
      ref.invalidate(screenshotsProvider);

      // Show success message
      if (context.mounted) {
        // Just print to console since we can't reliably show a snackbar from the menu bar
        debugPrint('Imported ${paths.length} screenshots');

        // Optionally show a dialog instead of a snackbar
        final effectiveContext = navigatorKey.currentContext ?? context;
        if (effectiveContext.mounted) {
          showMacosAlertDialog(
            context: effectiveContext,
            builder:
                (_) => MacosAlertDialog(
                  appIcon: const MacosIcon(CupertinoIcons.photo_on_rectangle),
                  title: const Text('Import Complete'),
                  message: Text(
                    'Successfully imported ${paths.length} screenshots.',
                  ),
                  primaryButton: PushButton(
                    controlSize: ControlSize.large,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(effectiveContext).pop(),
                  ),
                ),
          );
        }
      }
    }
  }

  /// Builds the platform menu bar
  static PlatformMenuBar build(BuildContext context, WidgetRef ref) {
    return PlatformMenuBar(
      menus: [
        // App menu (automatically added on macOS)
        PlatformMenu(
          label: 'SnapGrid',
          menus: [
            PlatformMenuItem(
              label: 'About SnapGrid',
              onSelected: () {
                final effectiveContext = navigatorKey.currentContext ?? context;
                showAboutDialog(
                  context: effectiveContext,
                  applicationName: 'SnapGrid',
                  applicationVersion: '1.0.0',
                  applicationIcon: const MacosIcon(
                    CupertinoIcons.photo_on_rectangle,
                  ),
                  applicationLegalese: '© 2023 SnapGrid',
                );
              },
            ),
            const PlatformMenuItem(label: '-'),
            PlatformMenuItem(
              label: 'Settings',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.comma,
                meta: true,
              ),
              onSelected: () {
                // Navigate to settings
                ref.read(selectedTabProvider.notifier).state = 1;
              },
            ),
            const PlatformMenuItem(label: '-'),
            const PlatformMenuItem(
              label: 'Quit SnapGrid',
              shortcut: SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
            ),
          ],
        ),

        // File menu
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: 'Import Screenshots',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyI,
                meta: true,
              ),
              onSelected: () {
                // Import screenshots
                final effectiveContext = navigatorKey.currentContext ?? context;
                _importScreenshots(effectiveContext, ref);
              },
            ),
            const PlatformMenuItem(label: '-'),
            PlatformMenuItem(
              label: 'Delete Selected Screenshot',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyD,
                meta: true,
              ),
              onSelected: () {
                final effectiveContext = navigatorKey.currentContext ?? context;
                final selectedPath = ref.read(selectedScreenshotProvider);
                if (selectedPath != null) {
                  final screenshotsAsync = ref.read(screenshotsProvider);
                  final screenshots = screenshotsAsync.value ?? [];
                  final screenshot = screenshots.firstWhere(
                    (s) => s.filePath == selectedPath,
                    orElse: () => throw Exception('Screenshot not found'),
                  );
                  ref
                      .read(screenshotActionsProvider)
                      .deleteScreenshot(screenshot, effectiveContext);
                }
              },
            ),
            PlatformMenuItem(
              label: 'Delete Selected Screenshots',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.backspace,
                meta: true,
              ),
              onSelected: () {
                final effectiveContext = navigatorKey.currentContext ?? context;
                ref
                    .read(screenshotActionsProvider)
                    .deleteSelectedScreenshots(effectiveContext);
              },
            ),
          ],
        ),

        // Edit menu
        PlatformMenu(
          label: 'Edit',
          menus: [
            PlatformMenuItem(
              label: 'Select All',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyA,
                meta: true,
              ),
              onSelected: () {
                final screenshotsAsync = ref.read(screenshotsProvider);
                final screenshots = screenshotsAsync.value ?? [];
                if (screenshots.isEmpty) return;

                final paths = screenshots.map((s) => s.filePath).toList();
                ref.read(selectedScreenshotsProvider.notifier).selectAll(paths);
              },
            ),
            PlatformMenuItem(
              label: 'Clear Selection',
              shortcut: const SingleActivator(LogicalKeyboardKey.escape),
              onSelected: () {
                ref.read(selectedScreenshotsProvider.notifier).deselectAll();
              },
            ),
            const PlatformMenuItem(label: '-'),
            PlatformMenuItem(
              label: 'Manage Tags for Selected Screenshots',
              onSelected: () {
                final selectedPaths = ref.read(selectedScreenshotsProvider);
                if (selectedPaths.isNotEmpty) {
                  final effectiveContext =
                      navigatorKey.currentContext ?? context;
                  BatchTagDialog.show(effectiveContext, selectedPaths);
                }
              },
            ),
            PlatformMenuItem(
              label: 'Analyze Selected Screenshots',
              onSelected: () {
                final effectiveContext = navigatorKey.currentContext ?? context;
                ref
                    .read(screenshotActionsProvider)
                    .analyzeSelectedScreenshots(effectiveContext);
              },
            ),
          ],
        ),

        // View menu
        PlatformMenu(
          label: 'View',
          menus: [
            PlatformMenuItem(
              label: 'Screenshots Grid',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit1,
                meta: true,
              ),
              onSelected: () {
                ref.read(selectedTabProvider.notifier).state = 0;
              },
            ),
            PlatformMenuItem(
              label: 'Settings',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit2,
                meta: true,
              ),
              onSelected: () {
                ref.read(selectedTabProvider.notifier).state = 1;
              },
            ),
            const PlatformMenuItem(label: '-'),
            PlatformMenuItem(
              label: 'Back to Grid',
              shortcut: const SingleActivator(LogicalKeyboardKey.escape),
              onSelected: () {
                ref.read(selectedScreenshotProvider.notifier).state = null;
              },
            ),
          ],
        ),

        // Filter menu
        PlatformMenu(
          label: 'Filter',
          menus: [
            PlatformMenuItem(
              label: 'Focus Search',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyF,
                meta: true,
              ),
              onSelected: () {
                // This is handled by the keyboard shortcuts
                // We just need to define it here for the menu
              },
            ),
            PlatformMenuItem(
              label: 'Clear All Filters',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyT,
                meta: true,
              ),
              onSelected: () {
                ref.read(selectedTagProvider.notifier).state = null;
                ref.read(showFavoritesOnlyProvider.notifier).state = false;
              },
            ),
            PlatformMenuItem(
              label: 'Toggle Favorites Filter',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyH,
                meta: true,
              ),
              onSelected: () {
                final current = ref.read(showFavoritesOnlyProvider);
                ref.read(showFavoritesOnlyProvider.notifier).state = !current;
              },
            ),
          ],
        ),

        // Help menu
        PlatformMenu(
          label: 'Help',
          menus: [
            PlatformMenuItem(
              label: 'Keyboard Shortcuts',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.slash,
                meta: true,
              ),
              onSelected: () {
                final effectiveContext = navigatorKey.currentContext ?? context;
                KeyboardShortcutsHelp.show(effectiveContext);
              },
            ),
            PlatformMenuItem(
              label: 'Documentation',
              onSelected: () {
                // Open documentation URL
                // This would typically use url_launcher package
              },
            ),
          ],
        ),
      ],
    );
  }
}
