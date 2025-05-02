abstract class AIAnalysisService {
  Future<Map<String, dynamic>> analyzeScreenshot(String imagePath);
  Future<String> generateSummary(Map<String, dynamic> analysisData);
}