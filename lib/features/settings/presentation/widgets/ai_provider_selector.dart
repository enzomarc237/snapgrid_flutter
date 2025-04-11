import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../domain/models/ai_model.dart';
// Removing unused import
import '../providers/settings_providers.dart';

/// Widget for selecting and configuring AI providers
class AIProviderSelector extends ConsumerWidget {
  /// Creates an AIProviderSelector
  const AIProviderSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProviderType = ref.watch(activeProviderTypeProvider);
    final allConfigsAsync = ref.watch(allProviderConfigsProvider);
    final availableModelsAsync = ref.watch(availableModelsProvider);
    final selectedModelAsync = ref.watch(selectedModelProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Provider',
          style: MacosTheme.of(context).typography.title3,
        ),
        const SizedBox(height: 8),
        
        // Provider selection
        Row(
          children: [
            for (final provider in AIProviderType.values) ...[
              PushButton(
                controlSize: ControlSize.regular,
                secondary: provider != activeProviderType,
                onPressed: () {
                  ref.read(activeProviderTypeProvider.notifier).state = provider;
                  ref.read(aiProviderManagerProvider).activeProvider = provider;
                  
                  // Refresh providers
                  ref.invalidate(activeProviderConfigProvider);
                  ref.invalidate(availableModelsProvider);
                  ref.invalidate(selectedModelProvider);
                },
                child: Text(_getProviderName(provider)),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 16),
        
        // Provider configuration
        allConfigsAsync.when(
          data: (configs) {
            final config = configs[activeProviderType];
            if (config == null) {
              return const Text('Provider configuration not available');
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider status
                Row(
                  children: [
                    MacosIcon(
                      config.isEnabled
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.exclamationmark_circle_fill,
                      color: config.isEnabled
                          ? MacosColors.systemGreenColor
                          : MacosColors.systemOrangeColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      config.isEnabled
                          ? '${config.name} is configured and ready to use'
                          : '${config.name} needs configuration',
                      style: MacosTheme.of(context).typography.body,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Model selection
                Text(
                  'Model',
                  style: MacosTheme.of(context).typography.subheadline.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                availableModelsAsync.when(
                  data: (models) {
                    return selectedModelAsync.when(
                      data: (selectedModel) {
                        return MacosPopupButton<String>(
                          value: selectedModel?.id ?? models.first.id,
                          items: models.map((model) {
                            return MacosPopupMenuItem(
                              value: model.id,
                              child: Text(model.name),
                            );
                          }).toList(),
                          onChanged: (modelId) {
                            if (modelId != null) {
                              ref.read(aiProviderManagerProvider).setModel(
                                activeProviderType,
                                modelId,
                              );
                              ref.invalidate(selectedModelProvider);
                            }
                          },
                        );
                      },
                      loading: () => const ProgressCircle(),
                      error: (_, __) => const Text('Error loading selected model'),
                    );
                  },
                  loading: () => const ProgressCircle(),
                  error: (_, __) => const Text('Error loading available models'),
                ),
                const SizedBox(height: 16),
                
                // Model capabilities
                selectedModelAsync.when(
                  data: (model) {
                    if (model == null) {
                      return const SizedBox.shrink();
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capabilities',
                          style: MacosTheme.of(context).typography.subheadline.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        _buildCapabilityItem(
                          context,
                          'Image Analysis',
                          model.capabilities.canAnalyzeImages,
                        ),
                        _buildCapabilityItem(
                          context,
                          'Text Generation',
                          model.capabilities.canGenerateText,
                        ),
                        _buildCapabilityItem(
                          context,
                          'Component Detection',
                          model.capabilities.supportsComponentDetection,
                        ),
                        _buildCapabilityItem(
                          context,
                          'Batch Processing',
                          model.capabilities.supportsBatchProcessing,
                        ),
                      ],
                    );
                  },
                  loading: () => const ProgressCircle(),
                  error: (_, __) => const Text('Error loading model capabilities'),
                ),
              ],
            );
          },
          loading: () => const ProgressCircle(),
          error: (_, __) => const Text('Error loading provider configurations'),
        ),
      ],
    );
  }
  
  Widget _buildCapabilityItem(BuildContext context, String name, bool isSupported) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          MacosIcon(
            isSupported
                ? CupertinoIcons.checkmark_circle
                : CupertinoIcons.xmark_circle,
            color: isSupported
                ? MacosColors.systemGreenColor
                : MacosColors.systemGrayColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(name, style: MacosTheme.of(context).typography.body),
        ],
      ),
    );
  }
  
  String _getProviderName(AIProviderType provider) {
    switch (provider) {
      case AIProviderType.gemini:
        return 'Gemini';
      case AIProviderType.openAI:
        return 'OpenAI';
      case AIProviderType.local:
        return 'Local';
      case AIProviderType.custom:
        return 'Custom';
    }
  }
}
