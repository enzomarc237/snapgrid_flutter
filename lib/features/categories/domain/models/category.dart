import 'package:flutter/material.dart';

/// Represents a category for organizing screenshots.
class Category {
  final String id;
  final String title;
  final String description;
  final IconData icon; // Or potentially String for icon name/path

  Category({
    required this.id,
    required this.title,
    this.description = '',
    required this.icon,
  });

  // Serialization/deserialization methods for persistence
  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'), // Or handle icon deserialization appropriately
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconCodePoint': icon.codePoint, // Serialize IconData to storable format
      };
}