import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/widgets/loading_view.dart';
// Removed unused import
import '../../../screenshots/presentation/providers/screenshot_providers.dart';
import '../../domain/models/category.dart';

/// Screen to confirm AI-suggested screenshots for category import.
class CategoryImportConfirmationScreen extends ConsumerStatefulWidget {
  final Category category;
  final List<String> suggestedScreenshotPaths;

  const CategoryImportConfirmationScreen({
    super.key,
    required this.category,
    required this.suggestedScreenshotPaths,
  });

  @override
  ConsumerState<CategoryImportConfirmationScreen> createState() =>
      _CategoryImportConfirmationScreenState();
}

class _CategoryImportConfirmationScreenState
    extends ConsumerState<CategoryImportConfirmationScreen> {
  late Set<String> _selectedPaths;

  @override
  void initState() {
    super.initState();
    // Initially, all suggested paths are selected
    _selectedPaths = Set<String>.from(widget.suggestedScreenshotPaths);
  }

  void _confirmImport() {
    // Return the set of confirmed paths to the previous screen/caller
    Navigator.of(context).pop(_selectedPaths.toList());
  }

  @override
  Widget build(BuildContext context) {
    final allScreenshotsAsync = ref.watch(screenshotsProvider);

    return MacosScaffold(
      toolBar: ToolBar(
        title: Text('Confirm Import to "${widget.category.title}"'),
        actions: [
          ToolBarIconButton(
            label: 'Cancel',
            icon: const MacosIcon(CupertinoIcons.xmark_circle),
            onPressed: () => Navigator.of(context).pop(null), // Return null on cancel
            showLabel: false,
          ),
          ToolBarIconButton(
            label: 'Confirm',
            icon: const MacosIcon(CupertinoIcons.check_mark_circled),
            onPressed: _confirmImport,
            showLabel: false,
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return allScreenshotsAsync.when(
              data: (allScreenshots) {
                // Filter the full list to get metadata for suggested paths
                final suggestedScreenshots = allScreenshots
                    .where((s) => widget.suggestedScreenshotPaths.contains(s.filePath))
                    .toList();

                if (suggestedScreenshots.isEmpty) {
                  return const Center(
                    child: Text('No relevant screenshots suggested by AI.'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI suggested the following screenshots based on the description:',
                        style: MacosTheme.of(context).typography.headline,
                      ),
                      Text(
                        widget.category.description,
                        style: MacosTheme.of(context).typography.caption1,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200, // Adjust size as needed
                            childAspectRatio: 1.2, // Adjust aspect ratio
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: suggestedScreenshots.length,
                          itemBuilder: (context, index) {
                            final screenshot = suggestedScreenshots[index];
                            final isSelected = _selectedPaths.contains(screenshot.filePath);
                            final file = File(screenshot.filePath);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPaths.remove(screenshot.filePath);
                                  } else {
                                    _selectedPaths.add(screenshot.filePath);
                                  }
                                });
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Screenshot Thumbnail
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? MacosTheme.of(context).primaryColor
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: FutureBuilder<bool>(
                                        future: file.exists(),
                                        builder: (context, snapshot) {
                                          if (snapshot.data == true) {
                                            return Image.file(
                                              file,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Center(child: Text('Error')),
                                            );
                                          } else {
                                            return const Center(child: Text('Not Found'));
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  // Selection Checkmark
                                  if (isSelected)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: MacosTheme.of(context).primaryColor.withAlpha(204), // 0.8 opacity = ~204 alpha
                                          shape: BoxShape.circle,
                                        ),
                                        child: const MacosIcon(
                                          CupertinoIcons.check_mark,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: LoadingView()),
              error: (error, stack) => Center(
                child: Text('Error loading screenshots: $error'),
              ),
            );
          },
        ),
      ],
    );
  }
}