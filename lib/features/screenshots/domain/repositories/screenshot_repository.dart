
import '../models/screenshot.dart';

/// Repository interface for screenshot operations
abstract class ScreenshotRepository {
  /// Gets all screenshots
  Future<List<Screenshot>> getAllScreenshots();

  /// Gets a screenshot by its file path
  Future<Screenshot?> getScreenshotByPath(String path);

  /// Imports a screenshot from the given source path
  Future<Screenshot> importScreenshot(String sourcePath);

  /// Imports multiple screenshots from the given source paths
  Future<List<Screenshot>> importScreenshots(List<String> sourcePaths);

  /// Batch import screenshots (entity version)
  Future<void> importScreenshotEntities(List<Screenshot> screenshots);

  /// Deletes a screenshot (moves it to trash)
  Future<void> deleteScreenshot(Screenshot screenshot);

  /// Updates a screenshot's metadata
  Future<Screenshot> updateScreenshot(Screenshot screenshot);

  /// Analyzes a screenshot using AI
  Future<Screenshot> analyzeScreenshot(Screenshot screenshot);

  /// Adds a tag to a screenshot
  Future<Screenshot> addTag(Screenshot screenshot, String tag);

  /// Removes a tag from a screenshot
  Future<Screenshot> removeTag(Screenshot screenshot, String tag);

  /// Toggles the favorite status of a screenshot
  Future<Screenshot> toggleFavorite(Screenshot screenshot);

  /// Gets all available tags across all screenshots
  Future<List<String>> getAllTags();

  /// Gets screenshots filtered by tag
  Future<List<Screenshot>> getScreenshotsByTag(String tag);

  /// Gets all favorite screenshots
  Future<List<Screenshot>> getFavoriteScreenshots();
}
