import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// No longer needed: import '../../data/repositories/in_memory_category_repository_impl.dart';
import '../../data/repositories/local_storage_category_repository_impl.dart'; // Import the new repo
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';

// --- Provider Setup for Asynchronous Initialization ---

// 1. Provider for SharedPreferences instance (must be overridden in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences provider was not overridden');
});

// 2. Provider for the LocalStorage implementation instance
//    Depends on SharedPreferences being ready.
final localStorageCategoryRepositoryProvider = Provider<LocalStorageCategoryRepositoryImpl>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider); // Watch the prefs provider
  return LocalStorageCategoryRepositoryImpl(prefs);
});

// 3. The main repository provider - chooses the implementation.
//    This is now synchronous after initialization. Watches the specific implementation.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return ref.watch(localStorageCategoryRepositoryProvider);
});

// Provider that fetches the list of categories using the repository.
// It automatically handles loading and error states.
// Provider that fetches the list of categories using the repository.
// It automatically handles loading and error states because it watches
// the synchronous categoryRepositoryProvider which depends on async initialization.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  // Watch the main repository provider. Riverpod handles the dependency chain.
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
    // Load categories once the repository is available.
    // Watching the provider ensures this notifier rebuilds when the repo is ready.
    // Establish dependency to trigger rebuild when repo is ready.
    _ref.listen(categoryRepositoryProvider, (_, __) => _loadCategories(), fireImmediately: true);
    // _loadCategories(); // Initial load triggered by listen
  }

  // Read the repository instance directly now. It's synchronous after init.
  CategoryRepository get _repository => _ref.read(categoryRepositoryProvider);

  Future<void> _loadCategories() async {
    // No need to check for readiness here anymore, Riverpod handles it via listen/watch.
    state = const AsyncValue.loading(); // Show loading explicitly on load/refresh
    try {
      final categories = await _repository.getCategories();
      // Check if the notifier is still mounted before updating state
      if (mounted) {
        state = AsyncValue.data(categories);
      }
    } catch (e, s) {
       if (mounted) {
         state = AsyncValue.error(e, s);
       }
    }
  }

  Future<void> addCategory(Category category) async {
    // Indicate loading
    state = const AsyncValue.loading();
    try {
      await _repository.addCategory(category);
      await _loadCategories(); // Reload the list from storage
    } catch (e, s) {
       if (mounted) {
         state = AsyncValue.error(e, s);
       }
      // Optionally revert to previous state or keep error state
    }
  }

  Future<void> updateCategory(Category category) async {
     state = const AsyncValue.loading();
     try {
       await _repository.updateCategory(category);
       await _loadCategories(); // Reload
     } catch (e, s) {
       if (mounted) {
         state = AsyncValue.error(e, s);
       }
     }
  }

  Future<void> deleteCategory(String categoryId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCategory(categoryId);
      await _loadCategories(); // Reload
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  // Optional: Refresh the list explicitly
  Future<void> refresh() async {
    // Simply call _loadCategories which handles setting loading state
    await _loadCategories();
  }
}