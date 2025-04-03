import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'models/screenshot_metadata.dart';
import 'providers/screenshot_providers.dart';
import 'views/screenshot_detail_view.dart';
import 'views/settings_view.dart';

/// This method initializes macos_window_utils and styles the window.
Future<void> _configureMacosWindowUtils() async {
  try {
    const config = MacosWindowUtilsConfig(
      toolbarStyle: NSWindowToolbarStyle.expanded,
    );
    await config.apply();
  } catch (e) {
    // Handle or ignore the error if not running on macOS
    debugPrint('Failed to configure macOS window: $e');
  }
}

// No longer needed, appDirectoryProvider handles creation implicitly
// Future<void> _setupAppDirectories() async { ... }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only run on macOS to avoid errors on other platforms
  if (Platform.isMacOS) {
    await _configureMacosWindowUtils();
  }

  // No need to explicitly call setup directories, providers will handle it.
  // await _setupAppDirectories();

  runApp(const ProviderScope(child: SnapGridApp()));
}

class SnapGridApp extends StatelessWidget {
  const SnapGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'SnapGrid Flutter',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const MainView(),
    );
  }
}

// Old provider removed, using screenshotsWithMetadataProvider from providers file

// ScreenshotGridView widget
class ScreenshotGridView extends ConsumerWidget {
  const ScreenshotGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the filtered provider that returns ScreenshotMetadata objects
    final screenshotsAsync = ref.watch(filteredScreenshotsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: MacosSearchField(
            placeholder: 'Search screenshots by content, elements, colors...',
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ),

        // Screenshots grid
        Expanded(
          child: screenshotsAsync.when(
            data: (screenshotsData) {
              // Renamed variable
              if (screenshotsData.isEmpty) {
                // Check if it's empty due to search filter
                final searchQuery = ref.watch(searchQueryProvider);
                if (searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const MacosIcon(
                          CupertinoIcons.search,
                          size: 48,
                          color: CupertinoColors.systemGrey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matching screenshots found',
                          style: MacosTheme.of(context).typography.title3
                              .copyWith(color: MacosColors.systemGrayColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: MacosTheme.of(context).typography.body
                              .copyWith(color: MacosColors.systemGrayColor),
                        ),
                      ],
                    ),
                  );
                }

                // Otherwise show the default empty state
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MacosIcon(
                        CupertinoIcons.photo_on_rectangle,
                        size: 48,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No screenshots yet',
                        style: MacosTheme.of(context).typography.title3
                            .copyWith(color: MacosColors.systemGrayColor),
                      ),
                      const SizedBox(height: 8),
                      PushButton(
                        controlSize: ControlSize.large,
                        child: const Text('Add Screenshot'),
                        onPressed: () {
                          // Use ref to call method on state
                          ref
                              .read(mainViewStateProvider.notifier)
                              .pickScreenshot(context);
                        },
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 16 / 10, // Common screenshot aspect ratio
                ),
                itemCount: screenshotsData.length,
                itemBuilder: (context, index) {
                  final screenshotMetadata = screenshotsData[index];
                  // Pass the whole metadata object
                  return ScreenshotGridItem(metadata: screenshotMetadata);
                },
              );
            },
            loading: () => const Center(child: ProgressCircle()),
            error:
                (error, stackTrace) =>
                    Center(child: Text('Error loading screenshots: $error')),
          ),
        ),
      ],
    );
  }
}

// ScreenshotGridItem widget - Now accepts ScreenshotMetadata
class ScreenshotGridItem extends ConsumerWidget {
  // Changed to ConsumerWidget
  final ScreenshotMetadata metadata;

  const ScreenshotGridItem({super.key, required this.metadata});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef
    // Watch the selected screenshot provider
    final selectedPath = ref.watch(selectedScreenshotProvider);
    final isSelected = selectedPath == metadata.filePath;

    return GestureDetector(
      // Wrap with GestureDetector for taps
      onTap: () {
        // Update the selected screenshot provider on tap
        // If already selected, deselect; otherwise, select.
        ref.read(selectedScreenshotProvider.notifier).state =
            isSelected ? null : metadata.filePath;
      },
      child: MacosTooltip(
        message: metadata.fileName,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border:
                isSelected
                    ? Border.all(
                      color: MacosTheme.of(context).primaryColor,
                      width: 2.5,
                    )
                    : Border.all(
                      color: MacosTheme.of(context).dividerColor,
                      width: 0.5,
                    ),
            boxShadow: [
              BoxShadow(
                color:
                    MacosTheme.of(context).brightness == Brightness.dark
                        ? MacosColors.black.withOpacity(0.3)
                        : MacosColors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            color:
                isSelected
                    ? MacosTheme.of(context).primaryColor.withOpacity(0.1)
                    : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(metadata.filePath), // Use filePath from metadata
              fit: BoxFit.cover,
              // Removed invalid loadingBuilder parameter
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading image ${metadata.fileName}: $error');
                return Container(
                  color: MacosTheme.of(context).canvasColor,
                  child: const Center(
                    child: MacosIcon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 24,
                      color: MacosColors.systemRedColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// MainView widget to handle navigation between screens
class MainView extends ConsumerWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(mainViewStateProvider).pageIndex;
    final selectedScreenshot = ref.watch(selectedScreenshotProvider);

    return MacosWindow(
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
              ref.read(mainViewStateProvider.notifier).setPageIndex(index);
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
                final screenshotsAsync = ref.watch(
                  screenshotsWithMetadataProvider,
                );
                return screenshotsAsync.when(
                  data: (screenshots) {
                    final selectedMetadata = screenshots.firstWhere(
                      (metadata) => metadata.filePath == selectedScreenshot,
                      orElse:
                          () => ScreenshotMetadata(
                            fileName: 'Unknown',
                            filePath: selectedScreenshot,
                            importDate: DateTime.now(),
                          ),
                    );
                    return ScreenshotDetailView(screenshot: selectedMetadata);
                  },
                  loading: () => const Center(child: ProgressCircle()),
                  error:
                      (error, stack) => Center(
                        child: Text('Error loading screenshot details: $error'),
                      ),
                );
              } else {
                return const ScreenshotGridView();
              }
            },
          ),

          // Settings View
          const SettingsView(),
        ],
      ),
    );
  }
}

// Provider for the MainView state to allow calling methods from elsewhere
final mainViewStateProvider =
    StateNotifierProvider<MainViewStateNotifier, _MainViewStateData>((ref) {
      return MainViewStateNotifier(ref);
    });

// Simple data class for MainView state
class _MainViewStateData {
  final int pageIndex;
  _MainViewStateData({this.pageIndex = 0});
}

// StateNotifier for MainView
class MainViewStateNotifier extends StateNotifier<_MainViewStateData> {
  final Ref _ref;
  MainViewStateNotifier(this._ref) : super(_MainViewStateData());

  void setPageIndex(int index) {
    state = _MainViewStateData(pageIndex: index);
  }

  Future<void> pickScreenshot(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final directories = await _ref.read(appDirectoryProvider.future);
        final imagesDir = Directory(directories['images']!);
        final metadataDir = Directory(directories['metadata']!);

        if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
        if (!await metadataDir.exists())
          await metadataDir.create(recursive: true);

        for (final file in result.files) {
          if (file.path != null) {
            await _importScreenshot(
              file.path!,
              imagesDir.path,
              metadataDir.path,
            );
          }
        }
        // Refresh the list after importing
        _ref.invalidate(screenshotsWithMetadataProvider);
      }
    } catch (e) {
      debugPrint('Error picking screenshot: $e');
      if (context.mounted) {
        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const FlutterLogo(size: 56),
                title: const Text('Error'),
                message: Text('Failed to pick screenshot: $e'),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );
      }
    }
  }

  Future<void> _importScreenshot(
    String sourcePath,
    String imagesPath,
    String metadataPath,
  ) async {
    try {
      final fileName = sourcePath.split(Platform.pathSeparator).last;
      final targetPath = '$imagesPath/$fileName';
      final metadataFilePath = '$metadataPath/$fileName.json';

      // Check if file already exists (simple check by name)
      if (await File(targetPath).exists()) {
        debugPrint('Screenshot already exists: $fileName');
        // Optionally show a dialog to the user
        return;
      }

      final sourceFile = File(sourcePath);
      await sourceFile.copy(targetPath);

      final metadata = ScreenshotMetadata(
        fileName: fileName,
        filePath: targetPath,
        importDate: DateTime.now(), // Use current time for import date
        analysisComplete: false,
      );

      await metadata.saveToFile(metadataFilePath);
      debugPrint('Imported screenshot: $fileName');
    } catch (e) {
      debugPrint('Error importing screenshot $sourcePath: $e');
      // Optionally show an error to the user
    }
  }

  // TODO: Implement deleteScreenshot method (Phase 2)
  Future<void> deleteScreenshot(ScreenshotMetadata metadata) async {
    debugPrint('Attempting to delete ${metadata.fileName}');
    try {
      final directories = await _ref.read(appDirectoryProvider.future);
      final trashDirImages = Directory('${directories['trash']}/images');
      final trashDirMetadata = Directory('${directories['trash']}/metadata');

      if (!await trashDirImages.exists())
        await trashDirImages.create(recursive: true);
      if (!await trashDirMetadata.exists())
        await trashDirMetadata.create(recursive: true);

      final imageFile = File(metadata.filePath);
      final metadataFile = File(
        '${directories['metadata']}/${metadata.fileName}.json',
      );

      // Move image
      if (await imageFile.exists()) {
        await imageFile.rename('${trashDirImages.path}/${metadata.fileName}');
        debugPrint('Moved image to trash: ${metadata.fileName}');
      } else {
        debugPrint('Image file not found for deletion: ${metadata.filePath}');
      }

      // Move metadata
      if (await metadataFile.exists()) {
        await metadataFile.rename(
          '${trashDirMetadata.path}/${metadata.fileName}.json',
        );
        debugPrint('Moved metadata to trash: ${metadata.fileName}.json');
      } else {
        debugPrint(
          'Metadata file not found for deletion: ${directories['metadata']}/${metadata.fileName}.json',
        );
      }

      _ref.invalidate(screenshotsWithMetadataProvider); // Refresh list
    } catch (e) {
      debugPrint('Error deleting screenshot ${metadata.fileName}: $e');
      // Optionally show error to user
    }
  }
}
