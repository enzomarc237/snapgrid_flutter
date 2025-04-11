import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/ai_model.dart';
import '../../domain/models/ai_provider_config.dart';
import '../../domain/models/analysis_options.dart';
import '../../domain/services/ai_provider_manager.dart';
import '../../domain/services/ai_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/openai_service.dart';

/// Provider for the Gemini service
final geminiServiceProvider = Provider<AIService>((ref) {
  return GeminiService();
});

/// Provider for the OpenAI service
final openAIServiceProvider = Provider<AIService>((ref) {
  return OpenAIService();
});

/// Provider for the AI provider manager
final aiProviderManagerProvider = Provider<AIProviderManager>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  final openAIService = ref.watch(openAIServiceProvider);

  return AIProviderManager({
    AIProviderType.gemini: geminiService,
    AIProviderType.openAI: openAIService,
  });
});

/// Provider for the active AI service
final activeAIServiceProvider = Provider<AIService>((ref) {
  final manager = ref.watch(aiProviderManagerProvider);
  return manager.activeService;
});

/// Provider for the active provider type
final activeProviderTypeProvider = StateProvider<AIProviderType>((ref) {
  return AIProviderType.gemini;
});

/// Provider to check if the active provider is configured
final isActiveProviderConfiguredProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(activeAIServiceProvider);
  return await service.isConfigured();
});

/// Provider for the active provider's configuration
final activeProviderConfigProvider = FutureProvider<AIProviderConfig>((
  ref,
) async {
  final service = ref.watch(activeAIServiceProvider);
  return await service.getConfig();
});

/// Provider for all provider configurations
final allProviderConfigsProvider =
    FutureProvider<Map<AIProviderType, AIProviderConfig>>((ref) async {
      final manager = ref.watch(aiProviderManagerProvider);
      return await manager.getAllConfigs();
    });

/// Provider for the available models of the active provider
final availableModelsProvider = FutureProvider<List<AIModel>>((ref) async {
  final service = ref.watch(activeAIServiceProvider);
  return await service.getAvailableModels();
});

/// Provider for the selected model of the active provider
final selectedModelProvider = FutureProvider<AIModel?>((ref) async {
  final service = ref.watch(activeAIServiceProvider);
  return await service.getSelectedModel();
});

/// Provider for the analysis options
final analysisOptionsProvider = StateProvider<AnalysisOptions>((ref) {
  return AnalysisOptions.defaults;
});

/// Provider for the app directories
final appDirectoriesProvider = FutureProvider<Map<String, String>>((ref) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final baseDir = '${documentsDir.path}/SnapGridFlutter';

  return {
    'base': baseDir,
    'images': '$baseDir/images',
    'metadata': '$baseDir/metadata',
    'trash': '$baseDir/.trash',
  };
});
