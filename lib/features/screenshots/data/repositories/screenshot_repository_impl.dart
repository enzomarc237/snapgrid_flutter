import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart'; // Import Uuid package
// path_provider is likely needed indirectly via appDirectoriesProvider
// import 'package:path_provider/path_provider.dart';

// Import domain models and repository interface
import '../../domain/models/screenshot.dart';
import '../../domain/repositories/screenshot_repository.dart';

// Import providers needed
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../presentation/providers/screenshot_providers.dart';

class ScreenshotRepositoryImpl implements ScreenshotRepository {
  final Ref ref; // Use Ref to access other providers

  ScreenshotRepositoryImpl({required this.ref}); // Updated constructor

  // Helper to get the path for the metadata JSON file within the metadata directory
  Future<String> _getMetadataPath(String imagePath) async {
    // Make it async
    final metadataDir = await _getAndEnsureDirectory(
      'metadata',
    ); // Get metadata dir
    final fileNameWithoutExt = p.basenameWithoutExtension(
      imagePath,
    ); // Get filename without ext
    return p.join(
      metadataDir.path,
      '$fileNameWithoutExt.json',
    ); // Construct path in metadata dir
  }

  // Helper to get the directory path from the provider and ensure it exists
  Future<Directory> _getAndEnsureDirectory(String key) async {
    // Read the directories map from the provider
    final directories = await ref.read(appDirectoriesProvider.future);
    final dirPath = directories[key];
    if (dirPath == null) {
      throw Exception(
        'Directory key "$key" not found in appDirectoriesProvider',
      );
    }
    final directory = Directory(dirPath);
    // Create the directory recursively if it doesn't exist
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('Created directory: $dirPath'); // Log directory creation
    }
    return directory;
  }

  // --- Read Operations ---

  @override
  Future<List<Screenshot>> getAllScreenshots() async {
    final metadataDir = await _getAndEnsureDirectory('metadata');
    final List<Screenshot> screenshots = [];
    final List<FileSystemEntity> entities;

    try {
      entities = await metadataDir.list().toList();
    } catch (e) {
      print("Error listing metadata directory ${metadataDir.path}: $e");
      // Return empty list or rethrow depending on desired behavior
      return [];
    }

    for (final entity in entities) {
      if (entity is File && p.extension(entity.path) == '.json') {
        try {
          final jsonString = await entity.readAsString();
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          final screenshot = Screenshot.fromJson(jsonMap);

          // IMPORTANT: Verify that the associated image file actually exists
          final imageFile = File(screenshot.filePath);
          if (await imageFile.exists()) {
            screenshots.add(screenshot);
          } else {
            print(
              'Metadata found for non-existent image: ${entity.path}, skipping and deleting metadata.',
            );
            // Delete orphan metadata file
            await entity.delete();
          }
        } catch (e) {
          print('Error reading or parsing metadata file ${entity.path}: $e');
          // Optionally delete corrupted metadata file
          // await entity.delete();
        }
      }
    }
    // Sort screenshots (optional, but often desired) - example by date descending
    screenshots.sort((a, b) => b.importDate.compareTo(a.importDate));
    return screenshots;
  }

  @override
  Future<Screenshot?> getScreenshotByPath(String imagePath) async {
    // Await the result of the async helper function
    final metadataPath = await _getMetadataPath(imagePath);
    try {
      final file = File(metadataPath);
      final fileExists = await file.exists();
      if (fileExists) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        // Verify image exists before returning
        if (await File(imagePath).exists()) {
          return Screenshot.fromJson(jsonMap);
        } else {
          print(
            'Metadata found for non-existent image: $metadataPath, deleting metadata.',
          );
          await file.delete();
          return null;
        }
      } else {
        return null; // Metadata file doesn't exist
      }
    } catch (e) {
      print(
        'Error reading metadata for $imagePath (metadata path: $metadataPath): $e',
      );
      return null;
    }
  }

  // Helper method to get screenshot by ID (less efficient than by path)
  Future<Screenshot?> getScreenshotById(String id) async {
    final allScreenshots = await getAllScreenshots();
    try {
      return allScreenshots.firstWhere((s) => s.id == id);
    } catch (e) {
      // firstWhere throws if no element is found
      return null;
    }
  }

  @override
  Future<List<String>> getAllTags() async {
    final allScreenshots = await getAllScreenshots(); // Read from files
    final tags = <String>{};
    for (final s in allScreenshots) {
      tags.addAll(s.tags);
    }
    return tags.toList()..sort(); // Return sorted list
  }

  @override
  Future<List<Screenshot>> getScreenshotsByTag(String tag) async {
    final allScreenshots = await getAllScreenshots(); // Read from files
    return allScreenshots.where((s) => s.tags.contains(tag)).toList();
  }

  @override
  Future<List<Screenshot>> getFavoriteScreenshots() async {
    final allScreenshots = await getAllScreenshots(); // Read from files
    return allScreenshots.where((s) => s.isFavorite).toList();
  }

  @override
  Future<List<Screenshot>> getScreenshotsByCategory(String categoryId) async {
    final allScreenshots = await getAllScreenshots(); // Read from files
    return allScreenshots.where((s) => s.categoryId == categoryId).toList();
  }

  // --- Write Operations ---

  @override
  Future<Screenshot> importScreenshot(
    String sourcePath, {
    String? categoryId,
  }) async {
    // 1. Determine destination paths
    final imagesDir = await _getAndEnsureDirectory('images');
    final metadataDir = await _getAndEnsureDirectory('metadata');
    final fileName = p.basename(sourcePath);
    final destImagePath = p.join(imagesDir.path, fileName);
    final destMetadataPath = p.join(
      metadataDir.path,
      '${p.withoutExtension(fileName)}.json',
    );

    // 2. Check if file already exists
    if (await File(destImagePath).exists() ||
        await File(destMetadataPath).exists()) {
      print('Skipping import for "$fileName": File already exists.');
      final existing = await getScreenshotByPath(destImagePath);
      if (existing != null) return existing;
      throw Exception(
        'Inconsistent state: Image or metadata already exists for $fileName',
      );
    }

    // 3. Copy image file
    try {
      await File(sourcePath).copy(destImagePath);
      print('Copied image to: $destImagePath');
    } catch (e) {
      print('Error copying image file $sourcePath to $destImagePath: $e');
      throw Exception('Failed to copy image file: $e');
    }

    // 4. Create Screenshot object with the *destination* path
    final screenshot = Screenshot(
      id: const Uuid().v4(),
      fileName: fileName,
      filePath: destImagePath,
      importDate: DateTime.now(),
      analysisComplete: false,
      tags: [],
      analysisResults: {},
      categoryId: categoryId, // Assign category if provided
    );

    // 5. Persist initial metadata
    try {
      final jsonMap = screenshot.toJson();
      final jsonString = jsonEncode(jsonMap);
      await File(destMetadataPath).writeAsString(jsonString);
      return screenshot;
    } catch (e) {
      print('Error creating initial metadata for ${screenshot.filePath}: $e');
      try {
        await File(destImagePath).delete();
      } catch (_) {}
      throw Exception(
        'Failed to create metadata for ${screenshot.filePath}: $e',
      );
    }
  }

  @override
  Future<List<Screenshot>> importScreenshots(
    List<String> sourcePaths, {
    String? categoryId,
  }) async {
    final List<Screenshot> successfullyImported = [];
    for (final sourcePath in sourcePaths) {
      try {
        final importedScreenshot = await importScreenshot(
          sourcePath,
          categoryId: categoryId,
        );
        successfullyImported.add(importedScreenshot);
      } catch (e) {
        print('Failed to import $sourcePath: $e');
        // Continue with the next file
      }
    }
    // Invalidate provider once after batch import attempt is complete
    if (successfullyImported.isNotEmpty) {}
    return successfullyImported;
  }

  @override
  Future<void> importScreenshotEntities(List<Screenshot> screenshots) async {
    // This method assumes the Screenshot objects already have the correct filePaths
    // within the application support directory. It will overwrite existing metadata.
    print("Importing screenshot entities. Ensure filePaths are correct.");
    final metadataDir = await _getAndEnsureDirectory('metadata');
    for (final screenshot in screenshots) {
      try {
        final metadataPath = p.join(
          metadataDir.path,
          '${p.withoutExtension(screenshot.fileName)}.json',
        );
        // Verify image exists before writing metadata
        if (!await File(screenshot.filePath).exists()) {
          print(
            "Skipping entity import for ${screenshot.fileName}: Image file not found at ${screenshot.filePath}",
          );
          continue;
        }
        final jsonMap = screenshot.toJson();
        final jsonString = jsonEncode(jsonMap);
        await File(metadataPath).writeAsString(jsonString);
      } catch (e) {
        print('Error importing entity metadata for ${screenshot.fileName}: $e');
      }
    }
    ref.invalidate(screenshotsProvider);
  }

  @override
  Future<void> deleteScreenshot(Screenshot screenshot) async {
    bool metadataDeleted = false;
    // --- Delete metadata file first ---
    try {
      // Await the result of the async helper function
      final metadataPath = await _getMetadataPath(screenshot.filePath);
      final file = File(metadataPath);
      if (await file.exists()) {
        await file.delete();
        metadataDeleted = true;
        print('Deleted metadata: $metadataPath');
      } else {
        print('Metadata file not found for deletion: $metadataPath');
        metadataDeleted = true; // Consider it "deleted" if not found
      }
    } catch (e) {
      print('Error deleting metadata file for ${screenshot.filePath}: $e');
      // Do not proceed if metadata deletion failed
      throw Exception(
        'Failed to delete metadata, aborting delete operation: $e',
      );
    }

    // --- Delete image file only if metadata was successfully deleted (or wasn't found) ---
    if (metadataDeleted) {
      try {
        final imageFile = File(screenshot.filePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
          print('Deleted image: ${screenshot.filePath}');
        } else {
          print('Image file not found for deletion: ${screenshot.filePath}');
        }
      } catch (e) {
        print('Error deleting image file ${screenshot.filePath}: $e');
        // If image deletion fails after metadata deletion, the state is inconsistent.
        // It might be better to log this prominently or attempt recovery.
        // For now, we still invalidate as the metadata is gone.
      }
    }

    // Invalidate the provider to trigger UI refresh
    ref.invalidate(screenshotsProvider);
  }

  @override
  Future<Screenshot> updateScreenshot(Screenshot screenshot) async {
    // Directly write the updated data to the JSON file.
    try {
      // Await the result of the async helper function
      final metadataPath = await _getMetadataPath(screenshot.filePath);
      final imagePath = screenshot.filePath;
      // print('Updating metadata: $metadataPath with data: ${screenshot.toJson()}'); // Removed log

      // Ensure the image file still exists before updating metadata
      if (!await File(imagePath).exists()) {
        print('Image file $imagePath not found for update, deleting metadata.');
        // Await the result of the async helper function
        final metadataPath = await _getMetadataPath(imagePath);
        try {
          await File(metadataPath).delete();
        } catch (e) {
          print('Error deleting metadata file for non-existent image: $e');
        }
        throw Exception('Image file $imagePath not found for update.');
      }
      // Ensure the metadata directory exists
      await _getAndEnsureDirectory('metadata');

      final jsonMap = screenshot.toJson();
      final jsonString = jsonEncode(jsonMap);
      // print('Updating metadata: $metadataPath with data: $jsonString'); // Removed log
      await File(metadataPath).writeAsString(jsonString);
      // print('Updated metadata: $metadataPath'); // Removed log

      // Invalidate provider to reflect changes
      // ref.invalidate(screenshotsProvider);
      return screenshot; // Return the updated screenshot object
    } catch (e) {
      print('Error saving metadata for ${screenshot.filePath}: $e');
      throw Exception(
        'Failed to update metadata for ${screenshot.filePath}: $e',
      );
    }
  }

  @override
  Future<Screenshot> analyzeScreenshot(Screenshot screenshot) async {
    // Get active AI service via ref
    final activeAiService = ref.read(activeAIServiceProvider);
    if (!await activeAiService.isConfigured()) {
      throw Exception('AI Service is not configured.');
    }
    // Pass screenshot to AI model for analysis
    print('Analyzing screenshot: ${screenshot.filePath}');
    // Call the correct method name and handle the AnalysisResult
    final analysisResult = await activeAiService.analyzeImage(
      screenshot.filePath,
    );

    if (!analysisResult.success) {
      throw Exception('AI analysis failed: ${analysisResult.errorMessage}');
    }
    final analysisResults =
        analysisResult.data ?? {}; // Use empty map if data is null
    print('Analysis complete for: ${screenshot.filePath}');

    final updatedScreenshot = screenshot.copyWith(
      analysisComplete: true,
      analysisResults: analysisResults,
    );

    // Use updateScreenshot to persist the results
    return updateScreenshot(updatedScreenshot);
  }

  // --- Methods using updateScreenshot implicitly handle persistence ---

  @override
  Future<Screenshot> addTag(Screenshot screenshot, String tag) async {
    if (screenshot.tags.contains(tag)) return screenshot; // Avoid duplicates
    final updatedTags = List<String>.from(screenshot.tags)..add(tag);
    final updated = screenshot.copyWith(tags: updatedTags);
    return updateScreenshot(updated);
  }

  @override
  Future<Screenshot> removeTag(Screenshot screenshot, String tag) async {
    if (!screenshot.tags.contains(tag)) return screenshot;
    final updatedTags = screenshot.tags.where((t) => t != tag).toList();
    final updated = screenshot.copyWith(tags: updatedTags);
    return updateScreenshot(updated);
  }

  @override
  Future<Screenshot> toggleFavorite(Screenshot screenshot) async {
    final updated = screenshot.copyWith(isFavorite: !screenshot.isFavorite);
    return updateScreenshot(updated);
  }

  @override
  // Update signature to accept screenshotPath
  Future<Screenshot> setScreenshotCategory(
    String screenshotId,
    String screenshotPath,
    String? categoryId,
  ) async {
    // print('setScreenshotCategory called with screenshotId: $screenshotId, path: $screenshotPath, categoryId: $categoryId'); // Removed log
    // Directly read, update, and write the specific metadata file
    // Await the result of the async helper function
    final metadataPath = await _getMetadataPath(screenshotPath);
    // print('Attempting to update category directly in: $metadataPath'); // Removed log

    try {
      final file = File(metadataPath);
      if (!await file.exists()) {
        // print('Metadata file $metadataPath not found for direct update.'); // Removed log
        throw Exception(
          'Screenshot metadata not found at $metadataPath for category update',
        );
      }

      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

      // Create a Screenshot object from JSON to easily update it
      // Ensure backward compatibility for 'id'
      jsonMap['id'] ??= const Uuid().v4(); // Assign ID if missing
      final screenshot = Screenshot.fromJson(jsonMap);

      // Check if the ID matches (optional sanity check)
      if (screenshot.id != screenshotId) {
        // print('Warning: ID mismatch in metadata file $metadataPath. Expected $screenshotId, found ${screenshot.id}'); // Removed log
        // Decide how to handle mismatch: throw error, update anyway, etc.
        // For now, we'll proceed but log the warning.
      }

      // Update the category ID
      final updatedScreenshot = screenshot.copyWith(
        categoryIdNullable: () => categoryId,
      );

      // Write the updated JSON back to the file
      final updatedJsonMap = updatedScreenshot.toJson();
      final updatedJsonString = jsonEncode(updatedJsonMap);
      await file.writeAsString(updatedJsonString);
      // print('Successfully updated category in $metadataPath'); // Removed log

      // Invalidation will be handled by the caller (ScreenshotActions)
      return updatedScreenshot; // Return the updated object
    } catch (e) {
      // print('Error directly updating category for $screenshotPath: $e'); // Keep error logging? Maybe not for production. Removed for now.
      throw Exception(
        'Failed to update category for screenshot $screenshotId: $e',
      );
    }
  }
}
