import '../models/ai_model.dart';
import '../models/ai_provider_config.dart';
import '../models/analysis_options.dart';

/// Result of an AI analysis operation
class AnalysisResult {
  /// Whether the analysis was successful
  final bool success;

  /// The structured data returned by the analysis
  final Map<String, dynamic>? data;

  /// Any error message if the analysis failed
  final String? errorMessage;

  /// Creates an AnalysisResult
  const AnalysisResult({required this.success, this.data, this.errorMessage});

  /// Creates a successful result
  factory AnalysisResult.success(Map<String, dynamic> data) {
    return AnalysisResult(success: true, data: data);
  }

  /// Creates a failed result
  factory AnalysisResult.failure(String errorMessage) {
    return AnalysisResult(success: false, errorMessage: errorMessage);
  }
}

/// Interface for AI services
abstract class AIService {
  /// Gets the provider type
  AIProviderType get providerType;

  /// Gets the available models for this provider
  Future<List<AIModel>> getAvailableModels();

  /// Gets the currently selected model
  Future<AIModel?> getSelectedModel();

  /// Sets the model to use for analysis
  Future<void> setModel(String modelId);

  /// Checks if the provider is properly configured
  Future<bool> isConfigured();

  /// Gets the provider configuration
  Future<AIProviderConfig> getConfig();

  /// Updates the provider configuration
  Future<void> updateConfig(AIProviderConfig config);

  /// Tests the connection to the provider
  Future<bool> testConnection();

  /// Analyzes an image and returns structured data
  Future<AnalysisResult> analyzeImage(
    String imagePath, {
    AnalysisOptions options = const AnalysisOptions(),
  });

  /// Analyzes multiple images in batch
  Future<List<AnalysisResult>> analyzeImages(
    List<String> imagePaths, {
    AnalysisOptions options = const AnalysisOptions(),
    void Function(int completed, int total)? progressCallback,
  });
}
