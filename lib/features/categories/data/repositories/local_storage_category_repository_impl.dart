import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';

/// Local storage implementation of the [CategoryRepository] using shared_preferences.
class LocalStorageCategoryRepositoryImpl implements CategoryRepository {
  static const String _categoriesKey = 'categories';
  final Uuid _uuid = const Uuid();
  final SharedPreferences _prefs;

  LocalStorageCategoryRepositoryImpl(this._prefs);

  @override
  Future<List<Category>> getCategories() async {
    final categoriesJson = _prefs.getStringList(_categoriesKey) ?? [];
    return categoriesJson
        .map((json) => Category.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addCategory(Category category) async {
    final categories = await getCategories();
    final newCategory = Category(
      id: _uuid.v4(), // Assign a new UUID
      title: category.title,
      description: category.description,
      icon: category.icon,
    );
    categories.add(newCategory);
    await _saveCategories(categories);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      await _saveCategories(categories);
    } else {
      // Optionally handle the case where the category to update doesn't exist
      print('Warning: Category with ID ${category.id} not found for update.');
      // Or throw an exception: throw Exception('Category not found');
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    final categories = await getCategories();
    categories.removeWhere((c) => c.id == categoryId);
    await _saveCategories(categories);
  }

  Future<void> _saveCategories(List<Category> categories) async {
    final categoriesJson = categories.map((category) => jsonEncode(category.toJson())).toList();
    await _prefs.setStringList(_categoriesKey, categoriesJson);
  }
}