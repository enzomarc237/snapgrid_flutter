import 'package:snapgrid_flutter/features/categories/domain/category_repository.dart';



class LocalCategoryRepository implements CategoryRepository {
  final List<String> _categories = [];

  @override
  Future<List<String>> getCategories() async {
    return List.from(_categories);
  }

  @override
  Future<void> addCategory(String category) async {
    if (!_categories.contains(category)) {
      _categories.add(category);
    }
  }

  @override
  Future<void> deleteCategory(String category) async {
    _categories.remove(category);
  }

  @override
  Future<void> updateCategory(String oldCategory, String newCategory) async {
    final index = _categories.indexOf(oldCategory);
    if (index != -1) {
      _categories[index] = newCategory;
    }
  }

}