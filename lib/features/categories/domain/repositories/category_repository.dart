import '../models/category.dart';

/// Abstract repository for managing categories.
abstract class CategoryRepository {
  /// Retrieves the list of all categories.
  Future<List<Category>> getCategories();

  /// Adds a new category.
  Future<void> addCategory(Category category);

  /// Updates an existing category.
  Future<void> updateCategory(Category category);

  /// Deletes a category by its ID.
  Future<void> deleteCategory(String categoryId);

  // Optional: Add methods for associating screenshots if needed later
  // Future<void> addScreenshotToCategory(String categoryId, String screenshotPath);
  // Future<void> removeScreenshotFromCategory(String categoryId, String screenshotPath);
}