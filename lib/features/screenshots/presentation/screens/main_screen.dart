// Import for Completer
import 'dart:convert'; // Import for jsonDecode
// Needed for ui.Image

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/utils/keyboard_shortcuts.dart';
// For placeholder
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/models/screenshot.dart';
import '../providers/screenshot_providers.dart';
import '../widgets/custom_sidebar_item.dart';
import '../widgets/screenshot_grid.dart';
import 'screenshot_detail_screen.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/screens/manage_categories_screen.dart';

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
    final macosTheme = MacosTheme.of(context);
    final brightness = macosTheme.brightness;
    
    // Use appropriate color based on theme brightness
    final Color textColor = brightness == Brightness.dark
        ? CupertinoColors.white.withOpacity(0.65)
        : CupertinoColors.black.withOpacity(0.65);
    
    return Padding(
      // Increase vertical padding for section titles
      padding: const EdgeInsets.fromLTRB(12.0, 20.0, 12.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: macosTheme.typography.body.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor, // Adaptive color for dark/light mode
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
        if (currentSelectedCategoryId == null)
          return 0; // Screenshots (All) selected
        // Find index of selected category if pageIndex is 0
        final categories = categoriesAsync.valueOrNull ?? [];
        final categoryIndex = categories.indexWhere(
          (cat) => cat.id == currentSelectedCategoryId,
        );
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
              return Container(
                // color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PAGES Section ---
                    const SidebarSectionTitle('Pages'),
                    // Screenshots item
                    GenericSidebarItem(
                      title: 'Captures d\'écran',
                      icon: CupertinoIcons.photo_on_rectangle,
                      isSelected: sidebarIndex == 0 && currentSelectedCategoryId == null,
                      onTap: () {
                        ref.read(mainNavigationProvider.notifier).setPageIndex(0);
                        ref.read(selectedCategoryIdProvider.notifier).state = null;
                        ref.read(selectedScreenshotProvider.notifier).state = null;
                      },
                    ),
                    // Settings item
                    GenericSidebarItem(
                      title: 'Paramètres',
                      icon: CupertinoIcons.settings,
                      isSelected: sidebarIndex == 1,
                      onTap: () {
                        ref.read(mainNavigationProvider.notifier).setPageIndex(1);
                        ref.read(selectedCategoryIdProvider.notifier).state = null;
                        ref.read(selectedScreenshotProvider.notifier).state = null;
                      },
                    ),
                    // --- CATEGORIES Section ---
                    const SidebarSectionTitle('Catégories'),
                    // Add "All Categories" entry first
                    GenericSidebarItem(
                      title: 'Toutes les catégories',
                      icon: CupertinoIcons.square_grid_2x2,
                      isSelected: sidebarIndex == 0 && currentSelectedCategoryId == null,
                      onTap: () {
                        ref.read(mainNavigationProvider.notifier).setPageIndex(0);
                        ref.read(selectedCategoryIdProvider.notifier).state = null;
                        ref.read(selectedScreenshotProvider.notifier).state = null;
                      },
                    ),
                    Expanded(
                      // Make the category list scrollable and take remaining space
                      child: categoriesAsync.when(
                        data: (categoryList) {
                          // Combine "All" (handled above) and specific categories
                          return ListView.builder(
                            controller:
                                scrollController, // Use the provided controller
                            itemCount: categoryList.length,
                            itemBuilder: (context, index) {
                              final category = categoryList[index];
                              final categorySidebarIndex =
                                  index + 2; // Offset by 2
                              final isSelected =
                                  sidebarIndex == categorySidebarIndex;
                              // Use MacosTheme for proper macOS styling and dark mode adaptation
                              final macosTheme = MacosTheme.of(context);
                              final brightness = macosTheme.brightness;
                              
                              // Determine text and icon color based on selection and theme brightness
                              final Color color = isSelected
                                  ? CupertinoColors.white
                                  : brightness == Brightness.dark
                                      ? CupertinoColors.white
                                      : CupertinoColors.black;
                              return DragTarget<String>(
                                builder: (
                                  BuildContext context,
                                  List<dynamic> accepted,
                                  List<dynamic> rejected,
                                ) {
                                  return Container(
                                    // Increase vertical margin between items
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? macosTheme.primaryColor
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        6,
                                      ), // Rounded corners
                                    ),
                                    child: MacosListTile(
                                      leading: MacosIcon(
                                        category.icon,
                                        color: color, // Set icon color
                                      ),
                                      title: Text(
                                        category.title,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ), // Set text color
                                      ),
                                      // Use onClick instead of onPressed for MacosListTile
                                      onClick: () {
                                        ref
                                            .read(
                                              mainNavigationProvider.notifier,
                                            )
                                            .setPageIndex(
                                              0,
                                            ); // Always show screenshot view
                                        ref
                                            .read(
                                              selectedCategoryIdProvider
                                                  .notifier,
                                            )
                                            .state = category.id;
                                        ref
                                                .read(
                                                  selectedScreenshotProvider
                                                      .notifier,
                                                )
                                                .state =
                                            null; // Clear screenshot selection
                                      },
                                    ),
                                  );
                                },
                                onAccept: (String jsonData) {
                                  // Accept JSON string
                                  try {
                                    final data =
                                        jsonDecode(jsonData)
                                            as Map<String, dynamic>;
                                    final screenshotId = data['id'] as String?;
                                    final screenshotPath =
                                        data['filePath']
                                            as String?; // Get filePath

                                    if (screenshotId != null &&
                                        screenshotPath != null) {
                                      ref
                                          .read(screenshotActionsProvider)
                                          .assignCategory(
                                            screenshotId, // Pass the ID
                                            screenshotPath, // Pass the Path
                                            category.id,
                                          );
                                    } else {
                                      print(
                                        'Erreur: Données glissées manquantes id ou filePath.',
                                      );
                                    }
                                  } catch (e) {
                                    print(
                                      'Erreur de décodage des données glissées: $e',
                                    );
                                  }
                                },
                                onWillAccept: (String? screenshotPath) {
                                  return true; // Toujours accepter pour l'instant
                                },
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: ProgressCircle()),
                        error:
                            (error, stack) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Erreur catégories: $error'),
                            ),
                      ),
                    ),

                    // --- Manage Categories Button ---
                    const Spacer(), // Pushes the button to the bottom
                    Padding(
                      // Reduce padding around the bottom button
                      padding: const EdgeInsets.fromLTRB(
                        8.0,
                        8.0,
                        8.0,
                        16.0,
                      ), // Less top/horizontal, keep bottom
                      // Use MacosListTile for consistency
                      child: MacosListTile(
                        // Style the bottom button similarly to non-selected items
                        leading: MacosIcon(
                          CupertinoIcons.add_circled,
                          color: MacosTheme.of(context).brightness == Brightness.dark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                        title: Text(
                          'Gérer Catégories',
                          style: TextStyle(
                            color: MacosTheme.of(context).brightness == Brightness.dark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                        onClick: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => const ManageCategoriesScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
                    final screenshotsAsyncValue = ref.watch(
                      screenshotsProvider,
                    );
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
                              'Erreur de chargement des détails de capture d\'écran: $error',
                            ),
                          ),
                    );
                  } else {
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
