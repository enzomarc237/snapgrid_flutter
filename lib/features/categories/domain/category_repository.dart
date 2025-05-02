abstract class CategoryRepository {
  Future<List<String>> getCategories();
  Future<void> addCategory(String category);
  Future<void> updateCategory(String oldCategory, String newCategory);
  Future<void> deleteCategory(String category);
}