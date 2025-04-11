import 'package:flutter/foundation.dart';

/// Options for AI analysis
@immutable
class AnalysisOptions {
  /// Whether to detect UI components
  final bool detectComponents;
  
  /// Whether to extract text
  final bool extractText;
  
  /// Whether to analyze color scheme
  final bool analyzeColorScheme;
  
  /// Whether to detect layout patterns
  final bool detectLayoutPatterns;
  
  /// Whether to identify accessibility issues
  final bool identifyAccessibilityIssues;
  
  /// Whether to detect design system
  final bool detectDesignSystem;
  
  /// Whether to detect component bounding boxes
  final bool detectBoundingBoxes;
  
  /// The maximum number of components to detect
  final int? maxComponents;
  
  /// The confidence threshold for detection (0.0 to 1.0)
  final double confidenceThreshold;
  
  /// Creates an AnalysisOptions instance
  const AnalysisOptions({
    this.detectComponents = true,
    this.extractText = true,
    this.analyzeColorScheme = true,
    this.detectLayoutPatterns = true,
    this.identifyAccessibilityIssues = true,
    this.detectDesignSystem = true,
    this.detectBoundingBoxes = false,
    this.maxComponents,
    this.confidenceThreshold = 0.7,
  });
  
  /// Creates a copy of this AnalysisOptions with the given fields replaced
  AnalysisOptions copyWith({
    bool? detectComponents,
    bool? extractText,
    bool? analyzeColorScheme,
    bool? detectLayoutPatterns,
    bool? identifyAccessibilityIssues,
    bool? detectDesignSystem,
    bool? detectBoundingBoxes,
    int? maxComponents,
    double? confidenceThreshold,
  }) {
    return AnalysisOptions(
      detectComponents: detectComponents ?? this.detectComponents,
      extractText: extractText ?? this.extractText,
      analyzeColorScheme: analyzeColorScheme ?? this.analyzeColorScheme,
      detectLayoutPatterns: detectLayoutPatterns ?? this.detectLayoutPatterns,
      identifyAccessibilityIssues: 
          identifyAccessibilityIssues ?? this.identifyAccessibilityIssues,
      detectDesignSystem: detectDesignSystem ?? this.detectDesignSystem,
      detectBoundingBoxes: detectBoundingBoxes ?? this.detectBoundingBoxes,
      maxComponents: maxComponents ?? this.maxComponents,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
    );
  }
  
  /// Creates an AnalysisOptions from JSON data
  factory AnalysisOptions.fromJson(Map<String, dynamic> json) {
    return AnalysisOptions(
      detectComponents: json['detectComponents'] as bool? ?? true,
      extractText: json['extractText'] as bool? ?? true,
      analyzeColorScheme: json['analyzeColorScheme'] as bool? ?? true,
      detectLayoutPatterns: json['detectLayoutPatterns'] as bool? ?? true,
      identifyAccessibilityIssues: 
          json['identifyAccessibilityIssues'] as bool? ?? true,
      detectDesignSystem: json['detectDesignSystem'] as bool? ?? true,
      detectBoundingBoxes: json['detectBoundingBoxes'] as bool? ?? false,
      maxComponents: json['maxComponents'] as int?,
      confidenceThreshold: 
          (json['confidenceThreshold'] as num?)?.toDouble() ?? 0.7,
    );
  }
  
  /// Converts this AnalysisOptions to JSON data
  Map<String, dynamic> toJson() {
    return {
      'detectComponents': detectComponents,
      'extractText': extractText,
      'analyzeColorScheme': analyzeColorScheme,
      'detectLayoutPatterns': detectLayoutPatterns,
      'identifyAccessibilityIssues': identifyAccessibilityIssues,
      'detectDesignSystem': detectDesignSystem,
      'detectBoundingBoxes': detectBoundingBoxes,
      if (maxComponents != null) 'maxComponents': maxComponents,
      'confidenceThreshold': confidenceThreshold,
    };
  }
  
  /// Default analysis options
  static const AnalysisOptions defaults = AnalysisOptions();
  
  /// Basic analysis options (fewer features)
  static const AnalysisOptions basic = AnalysisOptions(
    detectComponents: true,
    extractText: true,
    analyzeColorScheme: true,
    detectLayoutPatterns: false,
    identifyAccessibilityIssues: false,
    detectDesignSystem: false,
    detectBoundingBoxes: false,
  );
  
  /// Comprehensive analysis options (all features)
  static const AnalysisOptions comprehensive = AnalysisOptions(
    detectComponents: true,
    extractText: true,
    analyzeColorScheme: true,
    detectLayoutPatterns: true,
    identifyAccessibilityIssues: true,
    detectDesignSystem: true,
    detectBoundingBoxes: true,
    confidenceThreshold: 0.5,
  );
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisOptions &&
          runtimeType == other.runtimeType &&
          detectComponents == other.detectComponents &&
          extractText == other.extractText &&
          analyzeColorScheme == other.analyzeColorScheme &&
          detectLayoutPatterns == other.detectLayoutPatterns &&
          identifyAccessibilityIssues == other.identifyAccessibilityIssues &&
          detectDesignSystem == other.detectDesignSystem &&
          detectBoundingBoxes == other.detectBoundingBoxes &&
          maxComponents == other.maxComponents &&
          confidenceThreshold == other.confidenceThreshold;

  @override
  int get hashCode =>
      detectComponents.hashCode ^
      extractText.hashCode ^
      analyzeColorScheme.hashCode ^
      detectLayoutPatterns.hashCode ^
      identifyAccessibilityIssues.hashCode ^
      detectDesignSystem.hashCode ^
      detectBoundingBoxes.hashCode ^
      maxComponents.hashCode ^
      confidenceThreshold.hashCode;
}
