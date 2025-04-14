import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_category_repository_impl.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';

// Provider for the CategoryRepository implementation
// We use the InMemory implementation for now, but this can be swapped later
// for a persistent storage implementation (e.g., database, file storage).
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  // In a real app, you might check configuration or environment
  // to decide which repository implementation to use.
  return InMemoryCategoryRepositoryImpl();
});

// Provider that fetches the list of categories using the repository.
// It automatically handles loading and error states.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategories();
});

// StateNotifierProvider for managing the category list state more actively,
// allowing adding, updating, and deleting categories, and reflecting changes
// immediately in the UI without needing a full refresh of the FutureProvider.
final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Category>>>(
        (ref) {
  return CategoryListNotifier(ref);
});

class CategoryListNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final Ref _ref;

  CategoryListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  CategoryRepository get _repository => _ref.read(categoryRepositoryProvider);

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.getCategories();
      state = AsyncValue.data(categories);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addCategory(Category category) async {
    state = await AsyncValue.guard(() async {
      await _repository.addCategory(category);
      return _repository.getCategories(); // Return updated list
    });
  }

  Future<void> updateCategory(Category category) async {
    state = await AsyncValue.guard(() async {
      await _repository.updateCategory(category);
      return _repository.getCategories(); // Return updated list
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    state = await AsyncValue.guard(() async {
      await _repository.deleteCategory(categoryId);
      return _repository.getCategories(); // Return updated list
    });
  }

  // Optional: Refresh the list explicitly
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadCategories();
  }
}