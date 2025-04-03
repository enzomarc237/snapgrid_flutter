import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class GeminiService {
  final Gemini _gemini = Gemini.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  GeminiService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final apiKey = await _secureStorage.read(key: 'gemini_api_key');
      if (apiKey != null && apiKey.isNotEmpty) {
        Gemini.init(apiKey: apiKey);
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
    Gemini.init(apiKey: apiKey);
  }

  Future<Map<String, dynamic>?> analyzeScreenshot(String imagePath) async {
    try {
      if (!await hasApiKey()) {
        throw Exception(
          'No API key set. Please set a Gemini API key in Settings.',
        );
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      // final bytes = await file.readAsBytes();

      final prompt = '''
        Analyze this UI screenshot and identify key elements:
        1. Identify the type of UI (web, mobile, desktop)
        2. List all visible UI components (buttons, text fields, etc.)
        3. Extract any visible text
        4. Determine the color scheme (primary, secondary colors)
        5. Identify the layout pattern (grid, list, etc.)
        
        Format your response as JSON with these keys: 
        uiType, components, extractedText, colorScheme, layoutPattern
      ''';

      final content = [
        Content(
          role: 'user',
          parts: [
            TextPart(prompt),
            FilePart(
              FileDataPart(
                mimeType: 'image/jpeg',
                fileUri: file.uri.toString(),
              ),
            ),
          ],
        ),
      ];

      final response = await _gemini.chat(content);

      if (response?.output == null) {
        throw Exception('No response from Gemini API');
      }

      // Extract JSON from response
      final String rawText = response?.output ?? '{}';
      final jsonStartIndex = rawText.indexOf('{');
      final jsonEndIndex = rawText.lastIndexOf('}');

      if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
        final jsonStr = rawText.substring(jsonStartIndex, jsonEndIndex + 1);
        return json.decode(jsonStr);
      } else {
        // Try to extract structured data even if not in perfect JSON format
        return _extractStructuredDataFromText(rawText);
      }
    } catch (e) {
      debugPrint('Error analyzing screenshot: $e');
      return null;
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
