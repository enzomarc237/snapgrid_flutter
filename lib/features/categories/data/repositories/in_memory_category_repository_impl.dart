import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';

/// In-memory implementation of the [CategoryRepository].
/// Useful for testing and initial development.
class InMemoryCategoryRepositoryImpl implements CategoryRepository {
  final List<Category> _categories = [
    // Add some default categories for testing if needed
    Category(id: const Uuid().v4(), title: 'UI Designs', icon: CupertinoIcons.paintbrush),
    Category(id: const Uuid().v4(), title: 'Code Snippets', icon: CupertinoIcons.doc_text),
    Category(id: const Uuid().v4(), title: 'Inspiration', icon: CupertinoIcons.lightbulb),
  ];
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Category>> getCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_categories);
  }

  @override
  Future<void> addCategory(Category category) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Ensure the category has a unique ID
    final newCategory = Category(
      id: _uuid.v4(), // Assign a new UUID
      title: category.title,
      description: category.description,
      icon: category.icon,
    );
    _categories.add(newCategory);
  }

  @override
  Future<void> updateCategory(Category category) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    } else {
      // Optionally handle the case where the category to update doesn't exist
      print('Warning: Category with ID ${category.id} not found for update.');
      // Or throw an exception: throw Exception('Category not found');
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _categories.removeWhere((c) => c.id == categoryId);
  }
}