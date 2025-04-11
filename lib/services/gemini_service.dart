import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../features/settings/domain/services/model_registry.dart';
import '../features/settings/domain/models/ai_model.dart';

class GeminiService {
  late final Gemini _gemini;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _selectedModelId;

  GeminiService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final apiKey = await _secureStorage.read(key: 'gemini_api_key');
      if (apiKey != null && apiKey.isNotEmpty) {
        _gemini = Gemini.init(apiKey: apiKey);
      }

      // Load selected model or use default
      _selectedModelId = await _secureStorage.read(
        key: 'gemini_selected_model',
      );
      if (_selectedModelId == null) {
        final defaultModel = ModelRegistry.getDefaultModelForProvider(
          AIProviderType.gemini,
        );
        if (defaultModel != null) {
          _selectedModelId = defaultModel.id;
          await _secureStorage.write(
            key: 'gemini_selected_model',
            value: _selectedModelId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
    }
  }

  Future<bool> hasApiKey() async {
    final apiKey = await _secureStorage.read(key: 'gemini_api_key');
    return apiKey != null && apiKey.isNotEmpty;
  }

  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: 'gemini_api_key', value: apiKey);
    _gemini = Gemini.init(apiKey: apiKey);
  }

  Future<void> setModel(String modelId) async {
    _selectedModelId = modelId;
    await _secureStorage.write(key: 'gemini_selected_model', value: modelId);
  }

  Future<String> getSelectedModelId() async {
    if (_selectedModelId != null) {
      return _selectedModelId!;
    }

    // Load from storage or use default
    _selectedModelId = await _secureStorage.read(key: 'gemini_selected_model');
    if (_selectedModelId == null) {
      final defaultModel = ModelRegistry.getDefaultModelForProvider(
        AIProviderType.gemini,
      );
      if (defaultModel != null) {
        _selectedModelId = defaultModel.id;
        await _secureStorage.write(
          key: 'gemini_selected_model',
          value: _selectedModelId,
        );
      } else {
        // Fallback to a known model if registry fails
        _selectedModelId = 'gemini-1.5-pro';
      }
    }
    return _selectedModelId!;
  }

  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: 'gemini_api_key');
  }

  // Helper method to get MIME type from file extension
  // This is currently unused but may be needed in future versions
  // ignore: unused_element
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<Map<String, dynamic>?> analyzeScreenshot(String imagePath) async {
    try {
      // Verify API key exists
      if (!await hasApiKey()) {
        throw Exception('No Gemini API key configured');
      }

      // Verify image exists
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found');
      }

      // Prepare the analysis prompt
      const prompt = '''
      Analyze this UI screenshot and provide structured JSON response with:
      - uiType (web/mobile/desktop)
      - components (list of UI elements)
      - extractedText (visible text content)
      - colorScheme (primary colors)
      - layoutPattern (layout structure)
      ''';

      // Get the selected model ID
      final modelId = await getSelectedModelId();

      // Make the API request with timeout
      final response = await _gemini
          .prompt(
            model: modelId,
            parts: [TextPart(prompt), Part.bytes(await file.readAsBytes())],
          )
          .timeout(const Duration(seconds: 30));

      // Handle response
      if (response?.output == null) {
        throw Exception('No response from Gemini API');
      }

      // Log response for debugging (using debugPrint instead of print)
      debugPrint('Gemini response received with model: $modelId');

      // Extract JSON from response
      final String rawText =
          response!.output?.replaceAll("```", "").replaceAll("json", "") ??
          '{}';
      final jsonStartIndex = rawText.indexOf('{');
      final jsonEndIndex = rawText.lastIndexOf('}');

      if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
        final jsonStr = rawText.substring(jsonStartIndex, jsonEndIndex + 1);
        return json.decode(jsonStr);
      } else {
        // Try to extract structured data even if not in perfect JSON format
        return _extractStructuredDataFromText(rawText);
      }
    } on SocketException {
      throw Exception('Network connection failed');
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception(
          'Invalid request - please check your API key and image format',
        );
      }
      if (e.toString().contains('429')) {
        throw Exception('API quota exceeded - try again later');
      }
      throw Exception('Analysis failed: ${e.toString()}');
    }
  }

  Map<String, dynamic>? _extractStructuredDataFromText(String text) {
    try {
      // Simple extraction if the response is not valid JSON
      final Map<String, dynamic> result = {};

      // Try to extract UI type
      final uiTypeMatch = RegExp(r'uiType[":\s]+([^,\n}]+)').firstMatch(text);
      if (uiTypeMatch != null && uiTypeMatch.groupCount >= 1) {
        result['uiType'] = uiTypeMatch.group(1)?.trim().replaceAll('"', '');
      }

      // Extract components if listed
      final componentsMatch = RegExp(
        r'components[":\s]+\[(.*?)\]',
        dotAll: true,
      ).firstMatch(text);
      if (componentsMatch != null && componentsMatch.groupCount >= 1) {
        final componentsText = componentsMatch.group(1);
        result['components'] =
            componentsText
                ?.split(',')
                .map((e) => e.trim().replaceAll('"', ''))
                .where((e) => e.isNotEmpty)
                .toList();
      }

      // Extract extracted text
      final extractedTextMatch = RegExp(
        r'extractedText[":\s]+"(.*?)"',
        dotAll: true,
      ).firstMatch(text);
      if (extractedTextMatch != null && extractedTextMatch.groupCount >= 1) {
        result['extractedText'] = extractedTextMatch.group(1)?.trim();
      } else {
        // Alternative approach if not in quotes
        final extractedTextBlockMatch = RegExp(
          r'extractedText[":\s]+(.*?)(?:,|\})',
          dotAll: true,
        ).firstMatch(text);
        if (extractedTextBlockMatch != null &&
            extractedTextBlockMatch.groupCount >= 1) {
          result['extractedText'] = extractedTextBlockMatch
              .group(1)
              ?.trim()
              .replaceAll('"', '');
        }
      }

      // Extract layout pattern
      final layoutMatch = RegExp(
        r'layoutPattern[":\s]+([^,\n}]+)',
      ).firstMatch(text);
      if (layoutMatch != null && layoutMatch.groupCount >= 1) {
        result['layoutPattern'] = layoutMatch
            .group(1)
            ?.trim()
            .replaceAll('"', '');
      }

      // Extract color scheme
      final colorMatch = RegExp(
        r'colorScheme[":\s]+\{(.*?)\}',
        dotAll: true,
      ).firstMatch(text);
      if (colorMatch != null && colorMatch.groupCount >= 1) {
        final colorText = colorMatch.group(1);
        final Map<String, String> colors = {};

        final colorPairs = RegExp(
          r'([^:,]+):\s*([^,}]+)',
        ).allMatches(colorText ?? '');
        for (final match in colorPairs) {
          if (match.groupCount >= 2) {
            final key = match.group(1)?.trim().replaceAll('"', '') ?? '';
            final value = match.group(2)?.trim().replaceAll('"', '') ?? '';
            colors[key] = value;
          }
        }

        result['colorScheme'] = colors;
      }

      return result;
    } catch (e) {
      debugPrint('Error extracting structured data: $e');
      return null;
    }
  }
}
