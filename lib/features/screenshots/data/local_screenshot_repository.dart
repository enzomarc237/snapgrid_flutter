import 'package:snapgrid_flutter/features/screenshots/domain/screenshot_repository.dart';

import 'package:snapgrid_flutter/models/screenshot_metadata.dart';







class LocalScreenshotRepository implements ScreenshotRepository {
  final List<ScreenshotMetadata> _screenshots = [];

  @override
  Future<List<ScreenshotMetadata>> getAllScreenshots() async {
    return List.from(_screenshots);
  }

  @override
  Future<void> saveScreenshot(ScreenshotMetadata screenshot) async {
    final existingIndex = _screenshots.indexWhere((s) => s.fileName == screenshot.fileName);
    if (existingIndex >= 0) {
      _screenshots[existingIndex] = screenshot;
    } else {
      _screenshots.add(screenshot);
    }
  }

  @override
  Future<void> deleteScreenshot(String id) async {
    _screenshots.removeWhere((screenshot) => screenshot.fileName == id);
  }


  ScreenshotMetadata? _import;

  @override
  ScreenshotMetadata? get import => _import;

  @override
  set import(ScreenshotMetadata? value) {
    _import = value;
  }


}