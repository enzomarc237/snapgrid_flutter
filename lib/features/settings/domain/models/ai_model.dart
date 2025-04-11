import 'package:flutter/foundation.dart';

/// Represents an AI model's capabilities
class AIModelCapabilities {
  /// Whether the model can analyze images
  final bool canAnalyzeImages;
  
  /// Whether the model can generate text
  final bool canGenerateText;
  
  /// Whether the model supports component detection with bounding boxes
  final bool supportsComponentDetection;
  
  /// Whether the model supports batch processing
  final bool supportsBatchProcessing;
  
  /// Creates an AIModelCapabilities instance
  const AIModelCapabilities({
    this.canAnalyzeImages = false,
    this.canGenerateText = false,
    this.supportsComponentDetection = false,
    this.supportsBatchProcessing = false,
  });
}

/// Represents an AI provider type
enum AIProviderType {
  /// Google Gemini
  gemini,
  
  /// OpenAI
  openAI,
  
  /// Local model (e.g., Ollama)
  local,
  
  /// Custom API endpoint
  custom,
}

/// Represents an AI model that can be used for analysis
@immutable
class AIModel {
  /// The unique identifier for this model
  final String id;
  
  /// The display name of the model
  final String name;
  
  /// The provider of this model
  final AIProviderType provider;
  
  /// The capabilities of this model
  final AIModelCapabilities capabilities;
  
  /// Whether this model is the default for its provider
  final bool isDefault;
  
  /// The maximum context length supported by this model
  final int? maxContextLength;
  
  /// The maximum number of tokens this model can process
  final int? maxTokens;
  
  /// Creates an AIModel instance
  const AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.capabilities,
    this.isDefault = false,
    this.maxContextLength,
    this.maxTokens,
  });
  
  /// Creates a copy of this AIModel with the given fields replaced
  AIModel copyWith({
    String? id,
    String? name,
    AIProviderType? provider,
    AIModelCapabilities? capabilities,
    bool? isDefault,
    int? maxContextLength,
    int? maxTokens,
  }) {
    return AIModel(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      capabilities: capabilities ?? this.capabilities,
      isDefault: isDefault ?? this.isDefault,
      maxContextLength: maxContextLength ?? this.maxContextLength,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          provider == other.provider &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ provider.hashCode ^ isDefault.hashCode;
}
