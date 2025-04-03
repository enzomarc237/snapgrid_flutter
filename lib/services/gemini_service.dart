import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Service for interacting with Google's Gemini AI model to analyze screenshots
///
/// Handles secure storage of API keys, image analysis requests, and structured
/// response parsing. This service is part of Phase 3 of the SnapGrid development
/// plan, providing AI-powered UI element detection for screenshots.
class GeminiService {
  final Gemini _gemini = Gemini.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Creates a new GeminiService instance and initializes the Gemini API
  /// with any stored API key.
  GeminiService() {
    _initialize();
  }

  /// Initializes the Gemini API with the stored API key, if available.
  ///
  /// Gracefully handles errors during initialization to prevent app crashes.
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

  /// Checks if a Gemini API key is stored and available for use.
  ///
  /// Returns true if a non-empty API key is found in secure storage.
  Future<bool> hasApiKey() async {
    final apiKey = await _secureStorage.read(key: 'gemini_api_key');
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Securely stores a new Gemini API key and initializes the API with it.
  ///
  /// This method should be called when the user enters a new API key in settings.
  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: 'gemini_api_key', value: apiKey);
    Gemini.init(apiKey: apiKey);
  }

  /// Determines the MIME type based on file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Analyzes a screenshot using Google's Gemini AI vision model to identify UI elements.
  ///
  /// Takes the file path of the screenshot and sends it to Gemini with a prompt
  /// requesting identification of UI type, components, text, colors, and layout pattern.
  /// Returns a structured Map containing the analysis results or null if the analysis fails.
  ///
  /// Per the DEV_PLAN, this implements Phase 3 of the SnapGrid application functionality.
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

      // Determine mime type based on file extension
      final String mimeType = _getMimeType(imagePath);

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
              FileDataPart(mimeType: mimeType, fileUri: file.uri.toString()),
            ),
          ],
        ),
      ];

      try {
        final response = await _gemini.chat(content);

        if (response?.output == null) {
          throw Exception('No response from Gemini API');
        }

        // Check for potential content filtering or policy violation responses
        final String rawText = response?.output ?? '{}';
        if (rawText.toLowerCase().contains('content filtered') ||
            rawText.toLowerCase().contains('policy violation') ||
            rawText.toLowerCase().contains('could not process')) {
          throw Exception(
            'Content filtering applied or policy violation detected by Gemini API. ' +
                'The image may contain content that violates Google\'s policies.',
          );
        }

        // Extract JSON from response
        final jsonStartIndex = rawText.indexOf('{');
        final jsonEndIndex = rawText.lastIndexOf('}');

        if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
          final jsonStr = rawText.substring(jsonStartIndex, jsonEndIndex + 1);
          try {
            return json.decode(jsonStr);
          } catch (jsonError) {
            debugPrint('Error parsing JSON from Gemini response: $jsonError');
            // Fall back to regex extraction if JSON parsing fails
            return _extractStructuredDataFromText(rawText);
          }
        } else {
          // Try to extract structured data even if not in perfect JSON format
          return _extractStructuredDataFromText(rawText);
        }
      } on SocketException catch (e) {
        throw Exception(
          'Network error: Please check your internet connection. $e',
        );
      } on TimeoutException catch (e) {
        throw Exception(
          'Request timed out: The Gemini API is taking too long to respond. $e',
        );
      } catch (apiError) {
        // Check for rate limit errors
        final errorMsg = apiError.toString().toLowerCase();
        if (errorMsg.contains('rate limit') ||
            errorMsg.contains('quota') ||
            errorMsg.contains('429')) {
          throw Exception(
            'Rate limit exceeded: You have exceeded your Gemini API quota. ' +
                'Please try again later or check your API key usage limits.',
          );
        }
        // Re-throw with more context
        throw Exception('Gemini API error: $apiError');
      }
    } catch (e) {
      debugPrint('Error analyzing screenshot: $e');
      return null;
    }
  }

  /// Extracts structured data from unformatted text when JSON parsing fails.
  ///
  /// This method serves as a fallback mechanism when the Gemini API response
  /// is not in perfect JSON format. It uses regular expressions to extract the
  /// required fields (uiType, components, extractedText, colorScheme, layoutPattern)
  /// from the raw text response.
  ///
  /// Returns a Map with the same structure as expected from JSON parsing,
  /// or null if extraction fails.
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
