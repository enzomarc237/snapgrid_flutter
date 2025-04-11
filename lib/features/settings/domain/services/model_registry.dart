import '../models/ai_model.dart';

/// Registry of available AI models
class ModelRegistry {
  /// Gets all available Gemini models
  static List<AIModel> getGeminiModels() {
    return [
      const AIModel(
        id: 'gemini-1.5-pro',
        name: 'Gemini 1.5 Pro',
        provider: AIProviderType.gemini,
        capabilities: AIModelCapabilities(
          canAnalyzeImages: true,
          canGenerateText: true,
          supportsComponentDetection: false,
          supportsBatchProcessing: true,
        ),
        isDefault: true,
        maxContextLength: 1000000,
      ),
      const AIModel(
        id: 'gemini-1.5-flash',
        name: 'Gemini 1.5 Flash',
        provider: AIProviderType.gemini,
        capabilities: AIModelCapabilities(
          canAnalyzeImages: true,
          canGenerateText: true,
          supportsComponentDetection: false,
          supportsBatchProcessing: true,
        ),
        maxContextLength: 1000000,
      ),
      const AIModel(
        id: 'gemini-2.0-flash-thinking-exp',
        name: 'Gemini 2.0 Flash (Experimental)',
        provider: AIProviderType.gemini,
        capabilities: AIModelCapabilities(
          canAnalyzeImages: true,
          canGenerateText: true,
          supportsComponentDetection: false,
          supportsBatchProcessing: true,
        ),
        maxContextLength: 1000000,
      ),
    ];
  }
  
  /// Gets all available OpenAI models
  static List<AIModel> getOpenAIModels() {
    return [
      const AIModel(
        id: 'gpt-4o',
        name: 'GPT-4o',
        provider: AIProviderType.openAI,
        capabilities: AIModelCapabilities(
          canAnalyzeImages: true,
          canGenerateText: true,
          supportsComponentDetection: false,
          supportsBatchProcessing: true,
        ),
        isDefault: true,
        maxTokens: 128000,
      ),
      const AIModel(
        id: 'gpt-4-vision-preview',
        name: 'GPT-4 Vision',
        provider: AIProviderType.openAI,
        capabilities: AIModelCapabilities(
          canAnalyzeImages: true,
          canGenerateText: true,
          supportsComponentDetection: false,
          supportsBatchProcessing: true,
        ),
        maxTokens: 128000,
      ),
    ];
  }
  
  /// Gets all available local models
  static List<AIModel> getLocalModels() {
    return [
      const AIModel(
        id: 'llava',
        name: 'LLaVA',
        provider: AIProviderType.local,
        capabilities: AIModelCapabilities(
          canAnalyzeImages: true,
          canGenerateText: true,
          supportsComponentDetection: false,
          supportsBatchProcessing: false,
        ),
        isDefault: true,
      ),
      const AIModel(
        id: 'bakllava',
        name: 'BakLLaVA',
        provider: AIProviderType.local,
        capabilities: AIModelCapabilities(
          canAnalyzeImages: true,
          canGenerateText: true,
          supportsComponentDetection: false,
          supportsBatchProcessing: false,
        ),
      ),
    ];
  }
  
  /// Gets all available models for a specific provider
  static List<AIModel> getModelsForProvider(AIProviderType provider) {
    switch (provider) {
      case AIProviderType.gemini:
        return getGeminiModels();
      case AIProviderType.openAI:
        return getOpenAIModels();
      case AIProviderType.local:
        return getLocalModels();
      case AIProviderType.custom:
        return []; // Custom providers don't have predefined models
    }
  }
  
  /// Gets the default model for a specific provider
  static AIModel? getDefaultModelForProvider(AIProviderType provider) {
    final models = getModelsForProvider(provider);
    return models.firstWhere(
      (model) => model.isDefault,
      orElse: () => models.first,
    );
  }
  
  /// Gets a model by its ID
  static AIModel? getModelById(String id) {
    for (final provider in AIProviderType.values) {
      final models = getModelsForProvider(provider);
      for (final model in models) {
        if (model.id == id) {
          return model;
        }
      }
    }
    return null;
  }
}
