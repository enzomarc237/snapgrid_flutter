import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/screenshot.dart';
import 'screenshot_providers.dart';

/// Provider for the selected tag filter
final selectedTagProvider = StateProvider<String?>((ref) => null);

/// Provider for the favorites filter
final showFavoritesOnlyProvider = StateProvider<bool>((ref) => false);

/// Provider for all available tags
final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(screenshotRepositoryProvider);
  return repository.getAllTags();
});

/// Provider for screenshots filtered by tags and favorites
final tagFilteredScreenshotsProvider = Provider<AsyncValue<List<Screenshot>>>((ref) {
  final selectedTag = ref.watch(selectedTagProvider);
  final showFavoritesOnly = ref.watch(showFavoritesOnlyProvider);
  final screenshotsAsync = ref.watch(screenshotsProvider);
  
  return screenshotsAsync.when(
    data: (screenshots) {
      // Apply filters in sequence
      List<Screenshot> filteredScreenshots = screenshots;
      
      // Filter by favorites if needed
      if (showFavoritesOnly) {
        filteredScreenshots = filteredScreenshots.where((s) => s.isFavorite).toList();
      }
      
      // Filter by tag if selected
      if (selectedTag != null && selectedTag.isNotEmpty) {
        filteredScreenshots = filteredScreenshots.where((s) => s.tags.contains(selectedTag)).toList();
      }
      
      return AsyncValue.data(filteredScreenshots);
    },
    loading: () => screenshotsAsync,
    error: (error, stackTrace) => screenshotsAsync,
  );
});

/// Provider for tag actions
final tagActionsProvider = Provider<TagActions>((ref) {
  return TagActions(ref);
});

/// Class for tag-related actions
class TagActions {
  final Ref _ref;

  TagActions(this._ref);

  /// Adds a tag to a screenshot
  Future<void> addTag(Screenshot screenshot, String tag) async {
    if (tag.isEmpty) return;
    
    final repository = _ref.read(screenshotRepositoryProvider);
    await repository.addTag(screenshot, tag);
    
    // Refresh the list after adding tag
    _ref.invalidate(screenshotsProvider);
    _ref.invalidate(allTagsProvider);
  }

  /// Removes a tag from a screenshot
  Future<void> removeTag(Screenshot screenshot, String tag) async {
    final repository = _ref.read(screenshotRepositoryProvider);
    await repository.removeTag(screenshot, tag);
    
    // Refresh the list after removing tag
    _ref.invalidate(screenshotsProvider);
    _ref.invalidate(allTagsProvider);
  }

  /// Toggles the favorite status of a screenshot
  Future<void> toggleFavorite(Screenshot screenshot) async {
    final repository = _ref.read(screenshotRepositoryProvider);
    await repository.toggleFavorite(screenshot);
    
    // Refresh the list after toggling favorite
    _ref.invalidate(screenshotsProvider);
  }
}
