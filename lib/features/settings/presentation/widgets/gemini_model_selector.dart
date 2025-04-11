import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../services/gemini_service.dart';
import '../../domain/models/ai_model.dart';
import '../../domain/services/model_registry.dart';

/// Provider for the Gemini service instance
final geminiServiceInstanceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Provider for the selected Gemini model ID
final selectedGeminiModelIdProvider = FutureProvider<String>((ref) async {
  final geminiService = ref.watch(geminiServiceInstanceProvider);
  return await geminiService.getSelectedModelId();
});

/// Widget for selecting Gemini models
class GeminiModelSelector extends ConsumerWidget {
  /// Creates a GeminiModelSelector
  const GeminiModelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModelIdAsync = ref.watch(selectedGeminiModelIdProvider);
    final models = ModelRegistry.getModelsForProvider(AIProviderType.gemini);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gemini Model',
          style: MacosTheme.of(context).typography.subheadline.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        selectedModelIdAsync.when(
          data: (selectedModelId) {
            return Row(
              children: [
                Expanded(
                  child: MacosPopupButton<String>(
                    value: selectedModelId,
                    items: models.map((model) {
                      return MacosPopupMenuItem(
                        value: model.id,
                        child: Text(model.name),
                      );
                    }).toList(),
                    onChanged: (modelId) {
                      if (modelId != null) {
                        ref.read(geminiServiceInstanceProvider).setModel(modelId);
                        ref.invalidate(selectedGeminiModelIdProvider);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.small,
                  secondary: true,
                  onPressed: () {
                    // Reset to default model
                    final defaultModel = ModelRegistry.getDefaultModelForProvider(
                      AIProviderType.gemini,
                    );
                    if (defaultModel != null) {
                      ref.read(geminiServiceInstanceProvider).setModel(defaultModel.id);
                      ref.invalidate(selectedGeminiModelIdProvider);
                    }
                  },
                  child: const Text('Reset to Default'),
                ),
              ],
            );
          },
          loading: () => const ProgressCircle(),
          error: (_, __) => const Text('Error loading model selection'),
        ),
        
        const SizedBox(height: 16),
        
        // Model descriptions
        Text(
          'Available Models:',
          style: MacosTheme.of(context).typography.body.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        ...models.map((model) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MacosIcon(
                CupertinoIcons.circle_fill,
                size: 8,
                color: MacosTheme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: MacosTheme.of(context).typography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getModelDescription(model.id),
                      style: MacosTheme.of(context).typography.caption1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  String _getModelDescription(String modelId) {
    switch (modelId) {
      case 'gemini-1.5-pro':
        return 'Best for complex tasks requiring reasoning across many domains.';
      case 'gemini-1.5-flash':
        return 'Fast and efficient for simpler tasks with good performance.';
      case 'gemini-2.0-flash-thinking-exp':
        return 'Experimental model with enhanced reasoning capabilities.';
      default:
        return 'Gemini model for multimodal AI tasks.';
    }
  }
}
