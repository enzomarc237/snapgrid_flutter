import 'package:snapgrid_flutter/models/screenshot_metadata.dart';

abstract class ScreenshotRepository {
  Future<List<ScreenshotMetadata>> getAllScreenshots();
  Future<void> saveScreenshot(ScreenshotMetadata screenshot);
  Future<void> deleteScreenshot(String id);
  ScreenshotMetadata? get import;
  set import(ScreenshotMetadata? value);
}