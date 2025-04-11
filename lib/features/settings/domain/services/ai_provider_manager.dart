import 'package:flutter/foundation.dart';

import '../models/ai_model.dart';
import '../models/ai_provider_config.dart';
import '../models/analysis_options.dart';
import 'ai_service.dart';

/// Manager for AI providers
class AIProviderManager {
  final Map<AIProviderType, AIService> _providers;
  AIProviderType _activeProvider;
  
  /// Creates an AIProviderManager with the given providers
  AIProviderManager(this._providers, {AIProviderType? activeProvider})
      : _activeProvider = activeProvider ?? AIProviderType.gemini;
  
  /// Gets all available providers
  List<AIProviderType> get availableProviders => _providers.keys.toList();
  
  /// Gets the currently active provider
  AIProviderType get activeProvider => _activeProvider;
  
  /// Sets the active provider
  set activeProvider(AIProviderType provider) {
    if (_providers.containsKey(provider)) {
      _activeProvider = provider;
    }
  }
  
  /// Gets the service for the active provider
  AIService get activeService {
    return _providers[_activeProvider]!;
  }
  
  /// Gets the service for a specific provider
  AIService? getService(AIProviderType provider) {
    return _providers[provider];
  }
  
  /// Adds a provider service
  void addProvider(AIProviderType provider, AIService service) {
    _providers[provider] = service;
  }
  
  /// Removes a provider service
  void removeProvider(AIProviderType provider) {
    _providers.remove(provider);
    
    // If the active provider was removed, switch to another one
    if (_activeProvider == provider && _providers.isNotEmpty) {
      _activeProvider = _providers.keys.first;
    }
  }
  
  /// Gets the configuration for all providers
  Future<Map<AIProviderType, AIProviderConfig>> getAllConfigs() async {
    final configs = <AIProviderType, AIProviderConfig>{};
    
    for (final entry in _providers.entries) {
      configs[entry.key] = await entry.value.getConfig();
    }
    
    return configs;
  }
  
  /// Gets the configuration for a specific provider
  Future<AIProviderConfig?> getConfig(AIProviderType provider) async {
    final service = _providers[provider];
    if (service != null) {
      return await service.getConfig();
    }
    return null;
  }
  
  /// Updates the configuration for a specific provider
  Future<void> updateConfig(
    AIProviderType provider, 
    AIProviderConfig config,
  ) async {
    final service = _providers[provider];
    if (service != null) {
      await service.updateConfig(config);
    }
  }
  
  /// Gets all available models for a specific provider
  Future<List<AIModel>> getAvailableModels(AIProviderType provider) async {
    final service = _providers[provider];
    if (service != null) {
      return await service.getAvailableModels();
    }
    return [];
  }
  
  /// Gets the currently selected model for a specific provider
  Future<AIModel?> getSelectedModel(AIProviderType provider) async {
    final service = _providers[provider];
    if (service != null) {
      return await service.getSelectedModel();
    }
    return null;
  }
  
  /// Sets the model for a specific provider
  Future<void> setModel(AIProviderType provider, String modelId) async {
    final service = _providers[provider];
    if (service != null) {
      await service.setModel(modelId);
    }
  }
  
  /// Tests the connection to a specific provider
  Future<bool> testConnection(AIProviderType provider) async {
    final service = _providers[provider];
    if (service != null) {
      return await service.testConnection();
    }
    return false;
  }
  
  /// Analyzes an image using the active provider
  Future<AnalysisResult> analyzeImage(
    String imagePath, {
    AnalysisOptions options = const AnalysisOptions(),
  }) async {
    try {
      return await activeService.analyzeImage(imagePath, options: options);
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      return AnalysisResult.failure('Analysis failed: $e');
    }
  }
  
  /// Analyzes multiple images using the active provider
  Future<List<AnalysisResult>> analyzeImages(
    List<String> imagePaths, {
    AnalysisOptions options = const AnalysisOptions(),
    void Function(int completed, int total)? progressCallback,
  }) async {
    try {
      return await activeService.analyzeImages(
        imagePaths, 
        options: options,
        progressCallback: progressCallback,
      );
    } catch (e) {
      debugPrint('Error analyzing images: $e');
      return imagePaths.map(
        (_) => AnalysisResult.failure('Analysis failed: $e')
      ).toList();
    }
  }
}
