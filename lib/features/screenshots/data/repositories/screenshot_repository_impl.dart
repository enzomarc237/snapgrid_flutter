import '../../domain/models/screenshot.dart';
import '../../domain/repositories/screenshot_repository.dart';

class ScreenshotRepositoryImpl implements ScreenshotRepository {
  final dynamic aiService;

  ScreenshotRepositoryImpl({required this.aiService});

  // Simulated in-memory store
  final List<Screenshot> _screenshots = [
    Screenshot(
      fileName: 'screenshot1.png',
      filePath: '/path/to/screenshot1.png',
      importDate: DateTime.now(),
      tags: ['Tag1'],
      isFavorite: true,
      analysisComplete: false,
    ),
    Screenshot(
      fileName: 'screenshot2.jpg',
      filePath: '/path/to/screenshot2.jpg',
      importDate: DateTime.now(),
      tags: ['Tag2'],
      isFavorite: false,
      analysisComplete: false,
    ),
  ];

  @override
  Future<List<Screenshot>> getAllScreenshots() async {
    return List<Screenshot>.from(_screenshots);
  }

  @override
  Future<Screenshot?> getScreenshotByPath(String path) async {
    try {
      return _screenshots.firstWhere((s) => s.filePath == path);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Screenshot> importScreenshot(String sourcePath) async {
    final fileName = sourcePath.split('/').last;
    final screenshot = Screenshot(
      fileName: fileName,
      filePath: sourcePath,
      importDate: DateTime.now(),
      analysisComplete: false,
    );
    _screenshots.add(screenshot);
    return screenshot;
  }

  @override
  Future<List<Screenshot>> importScreenshots(List<String> sourcePaths) async {
    final imported = sourcePaths.map((path) {
      final fileName = path.split('/').last;
      return Screenshot(
        fileName: fileName,
        filePath: path,
        importDate: DateTime.now(),
        analysisComplete: false,
      );
    }).toList();
    _screenshots.addAll(imported);
    return imported;
  }

  @override
  Future<void> importScreenshotEntities(List<Screenshot> screenshots) async {
    _screenshots.addAll(screenshots);
  }

  @override
  Future<void> deleteScreenshot(Screenshot screenshot) async {
    _screenshots.removeWhere((s) => s.filePath == screenshot.filePath);
  }

  @override
  Future<Screenshot> updateScreenshot(Screenshot screenshot) async {
    final index = _screenshots.indexWhere((s) => s.filePath == screenshot.filePath);
    if (index != -1) {
      _screenshots[index] = screenshot;
      return screenshot;
    }
    throw Exception('Screenshot not found');
  }

  @override
  Future<Screenshot> analyzeScreenshot(Screenshot screenshot) async {
    // Simulated analysis
    final updatedScreenshot = screenshot.copyWith(
      analysisComplete: true,
      analysisResults: {
        'uiType': 'mobile',
        'components': ['button', 'text', 'image'],
        'extractedText': 'Sample text from the screenshot',
        'colorScheme': {'primary': '#007AFF', 'secondary': '#FF9500'},
        'layoutPattern': 'grid',
      },
    );
    return updateScreenshot(updatedScreenshot);
  }

  @override
  Future<Screenshot> addTag(Screenshot screenshot, String tag) async {
    final updated = screenshot.copyWith(
      tags: [...screenshot.tags, tag],
    );
    return updateScreenshot(updated);
  }

  @override
  Future<Screenshot> removeTag(Screenshot screenshot, String tag) async {
    final updated = screenshot.copyWith(
      tags: screenshot.tags.where((t) => t != tag).toList(),
    );
    return updateScreenshot(updated);
  }

  @override
  Future<Screenshot> toggleFavorite(Screenshot screenshot) async {
    final updated = screenshot.copyWith(
      isFavorite: !screenshot.isFavorite,
    );
    return updateScreenshot(updated);
  }

  @override
  Future<List<String>> getAllTags() async {
    final tags = <String>{};
    for (final s in _screenshots) {
      tags.addAll(s.tags);
    }
    return tags.toList();
  }

  @override
  Future<List<Screenshot>> getScreenshotsByTag(String tag) async {
    return _screenshots.where((s) => s.tags.contains(tag)).toList();
  }

  @override
  Future<List<Screenshot>> getFavoriteScreenshots() async {
    return _screenshots.where((s) => s.isFavorite).toList();
  }
}
