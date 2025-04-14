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

  // Optional: Add methods for serialization/deserialization if needed
  // factory Category.fromJson(Map<String, dynamic> json) => ...
  // Map<String, dynamic> toJson() => ...
}