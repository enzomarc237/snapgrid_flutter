import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import '../models/screenshot_metadata.dart';
import '../providers/screenshot_providers.dart';

class ScreenshotDetailView extends ConsumerWidget {
  final ScreenshotMetadata screenshot;

  const ScreenshotDetailView({super.key, required this.screenshot});

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
                        'Importé: ${screenshot.importDate.toString().split('.').first}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        PushButton(
                          controlSize: ControlSize.regular,
                          secondary: true,
                          child: const Text('Exporter'),
                          onPressed: () {
                            // Implémenter la fonctionnalité d'exportation
                          },
                        ),
                        const SizedBox(width: 12),
                        PushButton(
                          controlSize: ControlSize.regular,
                          child: const Row(
                            children: [
                              MacosIcon(CupertinoIcons.wand_stars, size: 16),
                              SizedBox(width: 8),
                              Text('Analyser'),
                            ],
                          ),
                          onPressed: () => _analyzeScreenshot(context, ref),
                        ),
                      ],
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
    final analysisAsyncValue = ref.watch(
      screenshotMetadataProvider(screenshot.fileName),
    );

    return analysisAsyncValue.when(
      data: (metadata) {
        if (metadata == null ||
            !metadata.analysisComplete ||
            metadata.analysisResults == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analyse UI',
                    style: MacosTheme.of(context).typography.title3,
                  ),
                  PushButton(
                    controlSize: ControlSize.small,
                    child: const Row(
                      children: [
                        MacosIcon(CupertinoIcons.wand_stars, size: 14),
                        SizedBox(width: 6),
                        Text('Analyser'),
                      ],
                    ),
                    onPressed: () => _analyzeScreenshot(context, ref),
                  ),
                ],
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
                      'Aucune analyse disponible',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cliquez sur "Analyser" pour détecter les éléments UI',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analyse UI',
                    style: MacosTheme.of(context).typography.title3,
                  ),
                  PushButton(
                    controlSize: ControlSize.small,
                    child: const Row(
                      children: [
                        MacosIcon(
                          CupertinoIcons.arrow_counterclockwise,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text('Réanalyser'),
                      ],
                    ),
                    onPressed: () => _analyzeScreenshot(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // UI Type
              if (results.containsKey('uiType'))
                _buildAnalysisSection(
                  context,
                  'Type d\'interface',
                  results['uiType'].toString(),
                ),

              // Components
              if (results.containsKey('components') &&
                  results['components'] is List)
                _buildAnalysisListSection(
                  context,
                  'Composants UI',
                  (results['components'] as List).cast<String>(),
                ),

              // Color Scheme
              if (results.containsKey('colorScheme') &&
                  results['colorScheme'] is Map)
                _buildAnalysisMapSection(
                  context,
                  'Palette de couleurs',
                  (results['colorScheme'] as Map).cast<String, dynamic>(),
                ),

              // Layout Pattern
              if (results.containsKey('layoutPattern'))
                _buildAnalysisSection(
                  context,
                  'Structure de mise en page',
                  results['layoutPattern'].toString(),
                ),

              // Extracted Text
              if (results.containsKey('extractedText'))
                _buildAnalysisSection(
                  context,
                  'Texte extrait',
                  results['extractedText'].toString(),
                  expanded: true,
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: ProgressCircle()),
      error:
          (error, stackTrace) =>
              Center(child: Text('Erreur de chargement de l\'analyse: $error')),
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
          ).typography.subheadline.copyWith(fontWeight: FontWeight.bold),
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
                      Text(content),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PushButton(
                            controlSize: ControlSize.small,
                            child: const Text('Copier'),
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
          style: MacosTheme.of(
            context,
          ).typography.subheadline.copyWith(fontWeight: FontWeight.bold),
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
                    children: [const Text('• '), Expanded(child: Text(item))],
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
          ).typography.subheadline.copyWith(fontWeight: FontWeight.bold),
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(entry.value.toString())),
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

  void _analyzeScreenshot(BuildContext context, WidgetRef ref) async {
    // Check if API key is set
    final hasApiKey = await ref.read(geminiApiKeySetProvider.future);

    if (!hasApiKey) {
      if (!context.mounted) return;

      showMacosAlertDialog(
        context: context,
        builder:
            (_) => MacosAlertDialog(
              appIcon: const Icon(CupertinoIcons.wand_stars),
              title: const Text('Clé API manquante'),
              message: const Text(
                'Vous devez configurer une clé API Google Gemini dans les Paramètres avant d\'analyser les captures d\'écran.',
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
      builder:
          (_) => MacosAlertDialog(
            appIcon: const Icon(CupertinoIcons.wand_stars),
            title: const Text('Analyse en cours'),
            message: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),
                ProgressCircle(),
                SizedBox(height: 16),
                Text(
                  'L\'IA analyse votre capture d\'écran...\nCela peut prendre un moment.',
                ),
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
          builder:
              (_) => MacosAlertDialog(
                appIcon: const Icon(CupertinoIcons.wand_stars),
                title: const Text('Échec de l\'analyse'),
                message: Text('Erreur: $e'),
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
