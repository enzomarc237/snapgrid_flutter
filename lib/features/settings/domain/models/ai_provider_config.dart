import 'package:flutter/foundation.dart';

import 'ai_model.dart';

/// Configuration for an AI provider
@immutable
class AIProviderConfig {
  /// The type of AI provider
  final AIProviderType type;
  
  /// The display name of the provider
  final String name;
  
  /// Whether this provider is enabled
  final bool isEnabled;
  
  /// The API key for this provider (if applicable)
  final String? apiKey;
  
  /// The API endpoint URL for this provider (if applicable)
  final String? apiEndpoint;
  
  /// The ID of the currently selected model for this provider
  final String? selectedModelId;
  
  /// Additional configuration options specific to this provider
  final Map<String, dynamic>? additionalOptions;
  
  /// Creates an AIProviderConfig instance
  const AIProviderConfig({
    required this.type,
    required this.name,
    this.isEnabled = false,
    this.apiKey,
    this.apiEndpoint,
    this.selectedModelId,
    this.additionalOptions,
  });
  
  /// Creates a copy of this AIProviderConfig with the given fields replaced
  AIProviderConfig copyWith({
    AIProviderType? type,
    String? name,
    bool? isEnabled,
    String? apiKey,
    String? apiEndpoint,
    String? selectedModelId,
    Map<String, dynamic>? additionalOptions,
  }) {
    return AIProviderConfig(
      type: type ?? this.type,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      apiKey: apiKey ?? this.apiKey,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      additionalOptions: additionalOptions ?? this.additionalOptions,
    );
  }
  
  /// Creates an AIProviderConfig from JSON data
  factory AIProviderConfig.fromJson(Map<String, dynamic> json) {
    return AIProviderConfig(
      type: AIProviderType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AIProviderType.gemini,
      ),
      name: json['name'] as String,
      isEnabled: json['isEnabled'] as bool? ?? false,
      apiKey: json['apiKey'] as String?,
      apiEndpoint: json['apiEndpoint'] as String?,
      selectedModelId: json['selectedModelId'] as String?,
      additionalOptions: json['additionalOptions'] as Map<String, dynamic>?,
    );
  }
  
  /// Converts this AIProviderConfig to JSON data
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'name': name,
      'isEnabled': isEnabled,
      if (apiKey != null) 'apiKey': apiKey,
      if (apiEndpoint != null) 'apiEndpoint': apiEndpoint,
      if (selectedModelId != null) 'selectedModelId': selectedModelId,
      if (additionalOptions != null) 'additionalOptions': additionalOptions,
    };
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIProviderConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name &&
          isEnabled == other.isEnabled &&
          apiKey == other.apiKey &&
          apiEndpoint == other.apiEndpoint &&
          selectedModelId == other.selectedModelId;

  @override
  int get hashCode =>
      type.hashCode ^
      name.hashCode ^
      isEnabled.hashCode ^
      apiKey.hashCode ^
      apiEndpoint.hashCode ^
      selectedModelId.hashCode;
}
