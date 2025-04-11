import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/utils/keyboard_shortcuts.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/models/screenshot.dart';
import '../providers/screenshot_providers.dart';
import '../widgets/screenshot_grid.dart';
import 'screenshot_detail_screen.dart';

/// The main navigation state provider
final mainNavigationProvider =
    StateNotifierProvider<MainNavigationNotifier, int>((ref) {
      return MainNavigationNotifier();
    });

/// Notifier for the main navigation state
class MainNavigationNotifier extends StateNotifier<int> {
  MainNavigationNotifier() : super(0);

  /// Sets the current page index
  void setPageIndex(int index) {
    state = index;
  }
}

/// The main screen of the application
class MainScreen extends ConsumerWidget {
  /// Creates a MainScreen
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(mainNavigationProvider);
    final selectedScreenshot = ref.watch(selectedScreenshotProvider);

    return KeyboardShortcuts.buildMainScreenShortcuts(
      context: context,
      ref: ref,
      child: Scaffold(
        body: MacosWindow(
          sidebar: Sidebar(
            minWidth: 200,
            builder: (context, scrollController) {
              return SidebarItems(
                currentIndex: pageIndex,
                onChanged: (index) {
                  // Clear selected screenshot when switching to settings
                  if (index == 1) {
                    ref.read(selectedScreenshotProvider.notifier).state = null;
                  }
                  ref.read(mainNavigationProvider.notifier).setPageIndex(index);
                },
                items: const [
                  SidebarItem(
                    leading: MacosIcon(CupertinoIcons.photo_on_rectangle),
                    label: Text('Screenshots'),
                  ),
                  SidebarItem(
                    leading: MacosIcon(CupertinoIcons.settings),
                    label: Text('Settings'),
                  ),
                ],
              );
            },
          ),
          child: IndexedStack(
            index: pageIndex,
            children: [
              // Screenshots View (Grid or Detail)
              Builder(
                builder: (context) {
                  // Show detail view if a screenshot is selected
                  if (selectedScreenshot != null) {
                    // Find the selected screenshot's metadata
                    final screenshotsAsync = ref.watch(screenshotsProvider);
                    return screenshotsAsync.when(
                      data: (screenshots) {
                        Screenshot? selectedMetadata;
                        try {
                          selectedMetadata = screenshots.firstWhere(
                            (metadata) =>
                                metadata.filePath == selectedScreenshot,
                          );
                        } catch (e) {
                          selectedMetadata = null;
                        }

                        if (selectedMetadata == null) {
                          // If screenshot not found, clear selection and show grid
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ref
                                .read(selectedScreenshotProvider.notifier)
                                .state = null;
                          });
                          return const ScreenshotGrid();
                        }

                        return ScreenshotDetailScreen(
                          screenshot: selectedMetadata,
                        );
                      },
                      loading: () => const Center(child: ProgressCircle()),
                      error:
                          (error, stack) => Center(
                            child: Text(
                              'Error loading screenshot details: $error',
                            ),
                          ),
                    );
                  } else {
                    return const ScreenshotGrid();
                  }
                },
              ),

              // Settings View
              const SettingsScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
