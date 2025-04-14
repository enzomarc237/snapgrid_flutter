import 'package:flutter/foundation.dart';

/// Represents a screenshot with its metadata
@immutable
class Screenshot {
  /// The filename of the screenshot
  final String fileName;

  /// The full file path to the screenshot
  final String filePath;

  /// The date when the screenshot was imported
  final DateTime importDate;

  /// Whether AI analysis has been completed
  final bool analysisComplete;

  /// The results of AI analysis, if available
  final Map<String, dynamic>? analysisResults;

  /// Tags associated with this screenshot
  final List<String> tags;

  /// Whether this screenshot is marked as a favorite
  final bool isFavorite;

  /// The ID of the category this screenshot belongs to, if any.
  final String? categoryId;

  /// Creates a Screenshot instance
  const Screenshot({
    required this.fileName,
    required this.filePath,
    required this.importDate,
    this.analysisComplete = false,
    this.analysisResults,
    this.tags = const [],
    this.isFavorite = false,
    this.categoryId, // Added categoryId
  });

  /// Creates a Screenshot from JSON data
  factory Screenshot.fromJson(Map<String, dynamic> json) {
    return Screenshot(
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      importDate: DateTime.parse(json['importDate'] as String),
      analysisComplete: json['analysisComplete'] as bool? ?? false,
      analysisResults: json['analysisResults'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      categoryId: json['categoryId'] as String?, // Added categoryId
    );
  }

  /// Converts the Screenshot to JSON
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'filePath': filePath,
      'importDate': importDate.toIso8601String(),
      'analysisComplete': analysisComplete,
      'analysisResults': analysisResults,
      'tags': tags,
      'isFavorite': isFavorite,
      'categoryId': categoryId, // Added categoryId
    };
  }

  /// Creates a copy of this Screenshot with the given fields replaced
  Screenshot copyWith({
    String? fileName,
    String? filePath,
    DateTime? importDate,
    bool? analysisComplete,
    Map<String, dynamic>? analysisResults,
    List<String>? tags,
    bool? isFavorite,
    String? categoryId, // Added categoryId
    ValueGetter<String?>? categoryIdNullable, // Helper for explicit null setting
  }) {
    final effectiveCategoryId = categoryIdNullable != null ? categoryIdNullable() : (categoryId ?? this.categoryId);
    return Screenshot(
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      importDate: importDate ?? this.importDate,
      analysisComplete: analysisComplete ?? this.analysisComplete,
      analysisResults: analysisResults ?? this.analysisResults,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      categoryId: effectiveCategoryId, // Use calculated categoryId
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Screenshot &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          filePath == other.filePath &&
          importDate.isAtSameMomentAs(other.importDate) &&
          analysisComplete == other.analysisComplete &&
          listEquals(tags, other.tags) &&
          isFavorite == other.isFavorite &&
          categoryId == other.categoryId; // Added categoryId

  @override
  int get hashCode =>
      fileName.hashCode ^
      filePath.hashCode ^
      importDate.hashCode ^
      analysisComplete.hashCode ^
      Object.hashAll(tags) ^
      isFavorite.hashCode ^
      categoryId.hashCode; // Added categoryId
}
