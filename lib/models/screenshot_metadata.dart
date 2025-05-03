import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ScreenshotMetadata {
  final String fileName;
  final String filePath;
  final DateTime importDate;
  final bool analysisComplete;
  final Map<String, dynamic>? analysisResults;
  
  ScreenshotMetadata({
    required this.fileName,
    required this.filePath,
    required this.importDate,
    this.analysisComplete = false,
    this.analysisResults,
  });
  
  factory ScreenshotMetadata.fromJson(Map<String, dynamic> json) {
    return ScreenshotMetadata(
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      importDate: DateTime.parse(json['importDate'] as String),
      analysisComplete: json['analysisComplete'] as bool? ?? false,
      analysisResults: json['analysisResults'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'filePath': filePath,
      'importDate': importDate.toIso8601String(),
      'analysisComplete': analysisComplete,
      'analysisResults': analysisResults,
    };
  }
  
  static Future<ScreenshotMetadata?> fromFile(String metadataPath) async {
    try {
      final file = File(metadataPath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return ScreenshotMetadata.fromJson(json);
      }
      return null;
    } catch (e) {
      debugPrint('Error reading metadata file: $e');
      return null;
    }
  }
  
  Future<void> saveToFile(String metadataPath) async {
    try {
      final file = File(metadataPath);
      final jsonString = jsonEncode(toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error writing metadata file: $e');
    }
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenshotMetadata &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          filePath == other.filePath &&
          importDate.isAtSameMomentAs(other.importDate) &&
          analysisComplete == other.analysisComplete;

  @override
  int get hashCode =>
      fileName.hashCode ^
      filePath.hashCode ^
      importDate.hashCode ^
      analysisComplete.hashCode;
  
  ScreenshotMetadata copyWith({
    String? fileName,
    String? filePath,
    DateTime? importDate,
    bool? analysisComplete,
    Map<String, dynamic>? analysisResults,
  }) {
    return ScreenshotMetadata(
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      importDate: importDate ?? this.importDate,
      analysisComplete: analysisComplete ?? this.analysisComplete,
      analysisResults: analysisResults ?? this.analysisResults,
    );
  }
  
  List<String> getFonts() {
    return (analysisResults?['detectedFonts'] as List<dynamic>? ?? []).cast<String>();
  }
  
  Map<String, String> getColors() {
    return (analysisResults?['colorScheme'] as Map<String, dynamic>? ?? {}).map((key, value) => MapEntry(key, value as String));
  }
}
