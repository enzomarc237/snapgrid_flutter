import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/utils/keyboard_shortcuts.dart';

import '../../../../core/widgets/error_view.dart';
import '../../domain/models/screenshot.dart';
import '../providers/screenshot_providers.dart';
import '../widgets/tag_editor.dart';

/// Screen that displays the details of a screenshot
class ScreenshotDetailScreen extends ConsumerWidget {
  /// The screenshot to display
  final Screenshot screenshot;

  /// Creates a ScreenshotDetailScreen
  const ScreenshotDetailScreen({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KeyboardShortcuts.buildDetailScreenShortcuts(
      context: context,
      ref: ref,
      screenshot: screenshot,
      child: ContentArea(
        builder: (context, scrollController) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildToolbar(context, ref),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: MacosTheme.of(context).dividerColor,
                              width: 0.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(screenshot.filePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      MacosListTile(
                        title: const Text('Image Details'),
                        subtitle: Text(
                          'Imported: ${screenshot.importDate.toString().split('.').first}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Analysis results
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildAnalysisPanel(context, ref),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        PushButton(
          controlSize: ControlSize.regular,
          secondary: true,
          child: const Text('Back'),
          onPressed: () {
            ref.read(selectedScreenshotProvider.notifier).state = null;
          },
        ),
        const Spacer(),
        PushButton(
          controlSize: ControlSize.regular,
          secondary: true,
          child: const Text('Delete'),
          onPressed: () {
            ref
                .read(screenshotActionsProvider)
                .deleteScreenshot(screenshot, context);
          },
        ),
        const SizedBox(width: 8),
        PushButton(
          controlSize: ControlSize.regular,
          child: Row(
            children: [
              const MacosIcon(CupertinoIcons.wand_stars, size: 16),
              const SizedBox(width: 4),
              Text(screenshot.analysisComplete ? 'Re-analyze' : 'Analyze'),
            ],
          ),
          onPressed: () {
            ref
                .read(screenshotActionsProvider)
                .analyzeScreenshot(screenshot, context);
          },
        ),
      ],
    );
  }

  Widget _buildAnalysisPanel(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag editor
          TagEditor(screenshot: screenshot),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Analysis results
          Text('AI Analysis', style: MacosTheme.of(context).typography.title3),
          const SizedBox(height: 16),

          _buildAnalysisContent(context, ref),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent(BuildContext context, WidgetRef ref) {
    if (!screenshot.analysisComplete) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MacosIcon(
              CupertinoIcons.wand_stars,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Analysis Yet',
              style: MacosTheme.of(context).typography.title3,
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Analyze" to detect UI elements and patterns',
              style: MacosTheme.of(context).typography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PushButton(
              controlSize: ControlSize.large,
              child: const Text('Analyze Screenshot'),
              onPressed: () {
                ref
                    .read(screenshotActionsProvider)
                    .analyzeScreenshot(screenshot, context);
              },
            ),
          ],
        ),
      );
    }

    final results = screenshot.analysisResults;
    if (results == null) {
      return const ErrorView(message: 'Analysis results are missing');
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UI Analysis', style: MacosTheme.of(context).typography.title3),
          const SizedBox(height: 16),

          // UI Type
          if (results.containsKey('uiType'))
            _buildAnalysisSection(
              context,
              'UI Type',
              results['uiType'].toString(),
            ),

          // Components
          if (results.containsKey('components') &&
              results['components'] is List)
            _buildAnalysisListSection(
              context,
              'UI Components',
              (results['components'] as List).cast<String>(),
            ),

          // Color Scheme
          if (results.containsKey('colorScheme') &&
              results['colorScheme'] is Map)
            _buildAnalysisMapSection(
              context,
              'Color Scheme',
              (results['colorScheme'] as Map).cast<String, dynamic>(),
            ),

          // Layout Pattern
          if (results.containsKey('layoutPattern'))
            _buildAnalysisSection(
              context,
              'Layout Pattern',
              results['layoutPattern'].toString(),
            ),

          // Design System
          if (results.containsKey('designSystem'))
            _buildAnalysisSection(
              context,
              'Design System',
              results['designSystem'].toString(),
            ),

          // Accessibility Issues
          if (results.containsKey('accessibilityIssues') &&
              results['accessibilityIssues'] is List &&
              (results['accessibilityIssues'] as List).isNotEmpty)
            _buildAnalysisListSection(
              context,
              'Accessibility Issues',
              (results['accessibilityIssues'] as List).cast<String>(),
            ),

          // Extracted Text
          if (results.containsKey('extractedText'))
            _buildAnalysisSection(
              context,
              'Extracted Text',
              results['extractedText'].toString(),
              expanded: true,
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(
    BuildContext context,
    String title,
    String content, {
    bool expanded = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: MacosTheme.of(
            context,
          ).typography.headline.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                MacosTheme.of(context).brightness == Brightness.dark
                    ? MacosColors.controlBackgroundColor.darkColor
                    : MacosColors.controlBackgroundColor.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child:
              expanded
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: TextStyle(
                          color:
                              MacosTheme.of(context).brightness ==
                                      Brightness.dark
                                  ? MacosColors.white
                                  : MacosColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PushButton(
                            controlSize: ControlSize.small,
                            child: const Text('Copy'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: content));
                            },
                          ),
                        ],
                      ),
                    ],
                  )
                  : Text(
                    content,
                    style: TextStyle(
                      color:
                          MacosTheme.of(context).brightness == Brightness.dark
                              ? MacosColors.white
                              : MacosColors.black,
                    ),
                  ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAnalysisListSection(
    BuildContext context,
    String title,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: MacosTheme.of(
            context,
          ).typography.headline.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                MacosTheme.of(context).brightness == Brightness.dark
                    ? MacosColors.controlBackgroundColor.darkColor
                    : MacosColors.controlBackgroundColor.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color:
                              MacosTheme.of(context).brightness ==
                                      Brightness.dark
                                  ? MacosColors.white
                                  : MacosColors.black,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color:
                                MacosTheme.of(context).brightness ==
                                        Brightness.dark
                                    ? MacosColors.white
                                    : MacosColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAnalysisMapSection(
    BuildContext context,
    String title,
    Map<String, dynamic> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: MacosTheme.of(
            context,
          ).typography.headline.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                MacosTheme.of(context).brightness == Brightness.dark
                    ? MacosColors.controlBackgroundColor.darkColor
                    : MacosColors.controlBackgroundColor.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...items.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              MacosTheme.of(context).brightness ==
                                      Brightness.dark
                                  ? MacosColors.white
                                  : MacosColors.black,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color:
                                MacosTheme.of(context).brightness ==
                                        Brightness.dark
                                    ? MacosColors.white
                                    : MacosColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
