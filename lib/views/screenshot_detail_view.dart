import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import '../models/screenshot_metadata.dart';
import '../providers/screenshot_providers.dart';

class ScreenshotDetailView extends ConsumerWidget {
  final ScreenshotMetadata screenshot;
  
  const ScreenshotDetailView({
    super.key,
    required this.screenshot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentArea(
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
                    Container(
                      constraints: const BoxConstraints(maxHeight: 500),
                      child: Image.file(
                        File(screenshot.filePath),
                        fit: BoxFit.contain,
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
    );
  }
  
  Widget _buildAnalysisPanel(BuildContext context, WidgetRef ref) {
    final analysisAsyncValue = ref.watch(screenshotMetadataProvider(screenshot.fileName));
    
    return analysisAsyncValue.when(
      data: (metadata) {
        if (metadata == null || !metadata.analysisComplete || metadata.analysisResults == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UI Analysis',
                style: MacosTheme.of(context).typography.title3,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MacosIcon(
                      CupertinoIcons.wand_stars,
                      size: 48,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No analysis available',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click "Analyze" to detect UI elements',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        
        final results = metadata.analysisResults!;
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UI Analysis',
                style: MacosTheme.of(context).typography.title3,
              ),
              const SizedBox(height: 16),
              
              // UI Type
              if (results.containsKey('uiType'))
                _buildAnalysisSection(
                  context,
                  'UI Type',
                  results['uiType'].toString(),
                ),
              
              // Components
              if (results.containsKey('components') && results['components'] is List)
                _buildAnalysisListSection(
                  context,
                  'UI Components',
                  (results['components'] as List).cast<String>(),
                ),
              
              // Color Scheme
              if (results.containsKey('colorScheme') && results['colorScheme'] is Map)
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
      },
      loading: () => const Center(child: ProgressCircle()),
      error: (error, stackTrace) => Center(
        child: Text('Error loading analysis: $error'),
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
          style: MacosTheme.of(context).typography.subheadline.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MacosTheme.of(context).brightness == Brightness.dark
              ? MacosColors.controlBackgroundColor.darkColor
              : MacosColors.controlBackgroundColor.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: expanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(content),
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
            : Text(content),
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
          style: MacosTheme.of(context).typography.subheadline.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MacosTheme.of(context).brightness == Brightness.dark
              ? MacosColors.controlBackgroundColor.darkColor
              : MacosColors.controlBackgroundColor.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              )),
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
          style: MacosTheme.of(context).typography.subheadline.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MacosTheme.of(context).brightness == Brightness.dark
              ? MacosColors.controlBackgroundColor.darkColor
              : MacosColors.controlBackgroundColor.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...items.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(entry.value.toString())),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  void _analyzeScreenshot(BuildContext context, WidgetRef ref) async {
    // Check if API key is set
    final hasApiKey = await ref.read(geminiApiKeySetProvider.future);
    
    if (!hasApiKey) {
      if (!context.mounted) return;
      
      showMacosAlertDialog(
        context: context,
        builder: (_) => MacosAlertDialog(
          appIcon: const Icon(CupertinoIcons.wand_stars),
          title: const Text('API Key Missing'),
          message: const Text(
            'You need to set a Google Gemini API key in Settings before analyzing screenshots.',
          ),
          primaryButton: PushButton(
            controlSize: ControlSize.large,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
      return;
    }
    
    // Show analysis in progress dialog
    if (!context.mounted) return;
    
    showMacosAlertDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MacosAlertDialog(
        appIcon: const Icon(CupertinoIcons.wand_stars),
        title: const Text('Analyzing Screenshot'),
        message: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            ProgressCircle(),
            SizedBox(height: 16),
            Text('AI is analyzing your screenshot...\nThis may take a moment.'),
            SizedBox(height: 16), 
          ],
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
    
    // Start analysis
    try {
      await ref.read(analyzeScreenshotProvider(screenshot.filePath).future);
      
      // Close the dialog when done
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close the dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop();
        
        showMacosAlertDialog(
          context: context,
          builder: (_) => MacosAlertDialog(
            appIcon: const Icon(CupertinoIcons.wand_stars),
            title: const Text('Analysis Failed'),
            message: Text('Error: $e'),
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
}