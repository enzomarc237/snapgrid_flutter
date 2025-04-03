import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/screenshot_metadata.dart';
import '../services/gemini_service.dart';

// Provider for the current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider for the filtered screenshots based on search
final filteredScreenshotsProvider =
    Provider<AsyncValue<List<ScreenshotMetadata>>>((ref) {
      final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
      final screenshotsAsync = ref.watch(screenshotsWithMetadataProvider);

      return screenshotsAsync.when(
        data: (screenshots) {
          if (searchQuery.isEmpty) {
            return AsyncValue.data(screenshots);
          }

          // Filter screenshots based on search query
          final filteredScreenshots =
              screenshots.where((metadata) {
                // Search in file name
                if (metadata.fileName.toLowerCase().contains(searchQuery)) {
                  return true;
                }

                // If analysis is complete, search in analysis results
                if (metadata.analysisComplete &&
                    metadata.analysisResults != null) {
                  final results = metadata.analysisResults!;

                  // Search in UI type
                  if (results['uiType'] != null &&
                      results['uiType'].toString().toLowerCase().contains(
                        searchQuery,
                      )) {
                    return true;
                  }

                  // Search in components
                  if (results['components'] != null &&
                      results['components'] is List) {
                    for (final component in results['components']) {
                      if (component.toString().toLowerCase().contains(
                        searchQuery,
                      )) {
                        return true;
                      }
                    }
                  }

                  // Search in extracted text
                  if (results['extractedText'] != null &&
                      results['extractedText']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery)) {
                    return true;
                  }

                  // Search in layout pattern
                  if (results['layoutPattern'] != null &&
                      results['layoutPattern']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery)) {
                    return true;
                  }
                }

                return false;
              }).toList();

          return AsyncValue.data(filteredScreenshots);
        },
        loading: () => screenshotsAsync,
        error: (error, stackTrace) => screenshotsAsync,
      );
    });

// Provider for the GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

// Provider to check if Gemini API key is set
final geminiApiKeySetProvider = FutureProvider<bool>((ref) async {
  final geminiService = ref.watch(geminiServiceProvider);
  return await geminiService.hasApiKey();
});

// Provider for the app directory paths
final appDirectoryProvider = FutureProvider<Map<String, String>>((ref) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final baseDir = '${documentsDir.path}/SnapGridFlutter';

  return {
    'base': baseDir,
    'images': '$baseDir/images',
    'metadata': '$baseDir/metadata',
    'trash': '$baseDir/.trash',
  };
});

// Provider for the list of screenshots with metadata
final screenshotsWithMetadataProvider =
    FutureProvider<List<ScreenshotMetadata>>((ref) async {
      final directories = await ref.watch(appDirectoryProvider.future);
      final imagesDir = Directory(directories['images']!);
      final metadataDir = Directory(directories['metadata']!);

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        return [];
      }

      if (!await metadataDir.exists()) {
        await metadataDir.create(recursive: true);
      }

      final List<FileSystemEntity> imageFiles = await imagesDir.list().toList();
      final List<ScreenshotMetadata> screenshots = [];

      for (final file in imageFiles) {
        if (file is! File) continue;
        if (!file.path.toLowerCase().endsWith('.png') &&
            !file.path.toLowerCase().endsWith('.jpg') &&
            !file.path.toLowerCase().endsWith('.jpeg')) {
          continue;
        }

        final fileName = file.path.split(Platform.pathSeparator).last;
        final metadataPath = '${metadataDir.path}/$fileName.json';
        final metadataFile = File(metadataPath);

        if (await metadataFile.exists()) {
          final metadata = await ScreenshotMetadata.fromFile(metadataPath);
          if (metadata != null) {
            screenshots.add(metadata);
            continue;
          }
        }

        // Create new metadata if not exists
        final newMetadata = ScreenshotMetadata(
          fileName: fileName,
          filePath: file.path,
          importDate: await file.lastModified(),
        );

        await newMetadata.saveToFile(metadataPath);
        screenshots.add(newMetadata);
      }

      // Sort by import date, newest first
      screenshots.sort((a, b) => b.importDate.compareTo(a.importDate));

      return screenshots;
    });

// Provider for a specific screenshot metadata
final screenshotMetadataProvider =
    FutureProvider.family<ScreenshotMetadata?, String>((ref, fileName) async {
      final directories = await ref.watch(appDirectoryProvider.future);
      final metadataPath = '${directories['metadata']}/$fileName.json';
      return await ScreenshotMetadata.fromFile(metadataPath);
    });

// Provider to analyze screenshots with Gemini
final analyzeScreenshotProvider =
    FutureProvider.family<ScreenshotMetadata?, String>((ref, filePath) async {
      final geminiService = ref.watch(geminiServiceProvider);

      // Extract fileName from filePath
      final fileName = filePath.split(Platform.pathSeparator).last;

      // Get current metadata
      final directories = await ref.watch(appDirectoryProvider.future);
      final metadataPath = '${directories['metadata']}/$fileName.json';
      final currentMetadata = await ScreenshotMetadata.fromFile(metadataPath);

      if (currentMetadata == null) {
        return null;
      }

      // Analyze screenshot
      final analysisResults = await geminiService.analyzeScreenshot(filePath);

      // Update metadata
      final updatedMetadata = currentMetadata.copyWith(
        analysisComplete: true,
        analysisResults: analysisResults,
      );

      // Save updated metadata
      await updatedMetadata.saveToFile(metadataPath);

      // Invalidate the screenshots provider to refresh the list
      ref.invalidate(screenshotsWithMetadataProvider);

      return updatedMetadata;
    });

// Provider to hold the file path of the currently selected screenshot
final selectedScreenshotProvider = StateProvider<String?>((ref) => null);
