import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/utils/keyboard_shortcuts.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../categories/domain/models/category.dart'; // Import Category model
import '../../../categories/presentation/providers/category_providers.dart'; // Import categoryListProvider
import '../../../categories/presentation/screens/manage_categories_screen.dart'; // Import the new screen
import '../../domain/models/screenshot.dart';
import '../providers/screenshot_providers.dart';
import '../widgets/screenshot_grid.dart';
import 'screenshot_detail_screen.dart';

/// Provider to hold the ID of the currently selected category.
/// `null` means "All Screenshots" is selected.
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

/// The main navigation state provider (index for IndexedStack)
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

/// Helper widget for Sidebar section titles
class SidebarSectionTitle extends StatelessWidget {
  final String title;
  const SidebarSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Increase vertical padding for section titles
      padding: const EdgeInsets.fromLTRB(12.0, 20.0, 12.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: MacosTheme.of(context).typography.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: MacosTheme.of(context).brightness == Brightness.dark
                  ? MacosColors.systemGrayColor
                  : MacosColors.secondaryLabelColor, // Subtle color
            ),
      ),
    );
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
    final currentSelectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    // Determine the overall selected index for SidebarItems highlighting
    // 0: Screenshots (All or specific category)
    // 1: Settings
    // 2+: Categories (index + 2) - Not directly used for pageIndex, but for highlighting
    int calculateSidebarIndex() {
      if (pageIndex == 1) return 1; // Settings is selected
      if (pageIndex == 0) {
        if (currentSelectedCategoryId == null) return 0; // Screenshots (All) selected
        // Find index of selected category if pageIndex is 0
        final categories = categoriesAsync.valueOrNull ?? [];
        final categoryIndex = categories.indexWhere((cat) => cat.id == currentSelectedCategoryId);
        if (categoryIndex != -1) {
          return categoryIndex + 2; // Offset by 2 (Screenshots, Settings)
        }
        return 0; // Fallback to Screenshots (All)
      }
      return 0; // Default
    }

    final sidebarIndex = calculateSidebarIndex();


    return KeyboardShortcuts.buildMainScreenShortcuts(
      context: context,
      ref: ref,
      child: Scaffold(
        body: MacosWindow(
          sidebar: Sidebar(
            minWidth: 200,
            top: const SizedBox.shrink(), // Keep top empty
            builder: (context, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PAGES Section ---
                  const SidebarSectionTitle('Pages'),
                  // Replace SidebarItems with individual MacosListTile for fixed items
                  // Apply custom styling for selected item
                  () {
                    final isSelected = sidebarIndex == 0;
                    final color = isSelected ? MacosColors.white : MacosTheme.of(context).typography.body.color;
                    return Container(
                      // Increase vertical margin between items
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? MacosTheme.of(context).primaryColor : null,
                        borderRadius: BorderRadius.circular(6), // Rounded corners
                      ),
                      child: MacosListTile(
                        leading: MacosIcon(
                          CupertinoIcons.photo_on_rectangle,
                          color: color, // Set icon color
                        ),
                        title: Text(
                          'Screenshots', // Represents "All"
                          style: TextStyle(color: color), // Set text color
                        ),
                        onClick: () {
                          ref.read(mainNavigationProvider.notifier).setPageIndex(0);
                          ref.read(selectedCategoryIdProvider.notifier).state = null;
                          ref.read(selectedScreenshotProvider.notifier).state = null; // Clear screenshot selection
                        },
                      ),
                    );
                  }(), // Immediately invoke the closure
                  () {
                    final isSelected = sidebarIndex == 1;
                    final color = isSelected ? MacosColors.white : MacosTheme.of(context).typography.body.color;
                     return Container(
                      // Increase vertical margin between items
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? MacosTheme.of(context).primaryColor : null,
                        borderRadius: BorderRadius.circular(6), // Rounded corners
                      ),
                       child: MacosListTile(
                        leading: MacosIcon(
                          CupertinoIcons.settings,
                          color: color, // Set icon color
                        ),
                        title: Text(
                          'Settings',
                           style: TextStyle(color: color), // Set text color
                        ),
                        onClick: () {
                           ref.read(mainNavigationProvider.notifier).setPageIndex(1);
                           ref.read(selectedCategoryIdProvider.notifier).state = null; // Clear category selection
                           ref.read(selectedScreenshotProvider.notifier).state = null; // Clear screenshot selection
                        },
                      ),
                    );
                  }(), // Immediately invoke the closure

                  // --- CATEGORIES Section ---
                  const SidebarSectionTitle('Catégories'),
                  Expanded( // Make the category list scrollable and take remaining space
                    child: categoriesAsync.when(
                       data: (categoryList) {
                         // Combine "All" (handled above) and specific categories
                         return ListView.builder(
                           controller: scrollController, // Use the provided controller
                           itemCount: categoryList.length,
                           itemBuilder: (context, index) {
                             final category = categoryList[index];
                             final categorySidebarIndex = index + 2; // Offset by 2
                             final isSelected = sidebarIndex == categorySidebarIndex;
                             final color = isSelected ? MacosColors.white : MacosTheme.of(context).typography.body.color;
                             return Container(
                               // Increase vertical margin between items
                               margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(
                                 color: isSelected ? MacosTheme.of(context).primaryColor : null,
                                 borderRadius: BorderRadius.circular(6), // Rounded corners
                               ),
                               child: MacosListTile(
                                 leading: MacosIcon(
                                   category.icon,
                                   color: color, // Set icon color
                                 ),
                                 title: Text(
                                   category.title,
                                   style: TextStyle(color: color), // Set text color
                                 ),
                                 // Use onClick instead of onPressed for MacosListTile
                                 onClick: () {
                                   ref.read(mainNavigationProvider.notifier).setPageIndex(0); // Always show screenshot view
                                   ref.read(selectedCategoryIdProvider.notifier).state = category.id;
                                   ref.read(selectedScreenshotProvider.notifier).state = null; // Clear screenshot selection
                                 },
                               ),
                             );
                           },
                         );
                       },
                       loading: () => const Center(child: ProgressCircle()),
                       error: (error, stack) => Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Text('Erreur cat: $error'),
                       ),
                     ),
                  ),

                  // --- Manage Categories Button ---
                  const Spacer(), // Pushes the button to the bottom
                  Padding(
                    // Reduce padding around the bottom button
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0), // Less top/horizontal, keep bottom
                    // Use MacosListTile for consistency
                    child: MacosListTile(
                      leading: const MacosIcon(
                        CupertinoIcons.add_circled,
                        // Use default color or a subtle one 
                        color: MacosColors.systemGrayColor,
                      ),
                      title: const Text(
                        'Gérer Catégories',
                         // Use default color or a subtle one
                        style: TextStyle(color: MacosColors.systemGrayColor),
                      ),
                      onClick: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ManageCategoriesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          child: IndexedStack(
            index: pageIndex,
            children: [
              // Screenshots View (Grid or Detail) - Index 0
              Builder(
                builder: (context) {
                  // Show detail view if a screenshot is selected
                  if (selectedScreenshot != null) {
                    final screenshotsAsyncValue = ref.watch(screenshotsProvider);
                    return screenshotsAsyncValue.when(
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
                          // ScreenshotGrid already uses categoryFilteredScreenshotsProvider
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
                    // ScreenshotGrid already uses categoryFilteredScreenshotsProvider
                    return const ScreenshotGrid();
                  }
                },
              ),

              // Settings View - Index 1
              const SettingsScreen(),
            ],
          ),
        ),
      ),
    );
  }
}