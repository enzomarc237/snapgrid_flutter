import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/ai_model.dart';
import '../../domain/models/ai_provider_config.dart';
import '../../domain/models/analysis_options.dart';
import '../../domain/services/ai_service.dart';
import '../../domain/services/model_registry.dart';

/// Implementation of AIService using Google Gemini
class GeminiService implements AIService {
  late Gemini _gemini;
  final FlutterSecureStorage _secureStorage;

  static const String _configKey = 'gemini_config';
  static const String _selectedModelKey = 'gemini_selected_model';

  String? _currentModelId;
  AIProviderConfig? _config;

  /// Creates a GeminiService with the given secure storage
  GeminiService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _initialize();
  }

  @override
  AIProviderType get providerType => AIProviderType.gemini;

  Future<void> _initialize() async {
    try {
      // Load configuration
      await _loadConfig();

      // Initialize Gemini if API key is available
      if (_config != null &&
          _config!.apiKey != null &&
          _config!.apiKey!.isNotEmpty) {
        _gemini = Gemini.init(apiKey: _config!.apiKey!);
      }

      // Load selected model
      await _loadSelectedModel();
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
    }
  }

  Future<void> _loadConfig() async {
    try {
      final configJson = await _secureStorage.read(key: _configKey);
      if (configJson != null) {
        _config = AIProviderConfig.fromJson(json.decode(configJson));
      } else {
        // Create default config if none exists
        final apiKey = await _secureStorage.read(key: 'gemini_api_key');
        _config = AIProviderConfig(
          type: AIProviderType.gemini,
          name: 'Google Gemini',
          isEnabled: apiKey != null && apiKey.isNotEmpty,
          apiKey: apiKey,
        );

        // Save the new config
        await _saveConfig();
      }
    } catch (e) {
      debugPrint('Error loading Gemini config: $e');
      _config = AIProviderConfig(
        type: AIProviderType.gemini,
        name: 'Google Gemini',
        isEnabled: false,
      );
    }
  }

  Future<void> _saveConfig() async {
    if (_config != null) {
      await _secureStorage.write(
        key: _configKey,
        value: json.encode(_config!.toJson()),
      );
    }
  }

  Future<void> _loadSelectedModel() async {
    try {
      _currentModelId = await _secureStorage.read(key: _selectedModelKey);

      // If no model is selected, use the default
      if (_currentModelId == null) {
        final defaultModel = ModelRegistry.getDefaultModelForProvider(
          providerType,
        );
        if (defaultModel != null) {
          _currentModelId = defaultModel.id;
          await _secureStorage.write(
            key: _selectedModelKey,
            value: _currentModelId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading selected model: $e');
    }
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return ModelRegistry.getModelsForProvider(providerType);
  }

  @override
  Future<AIModel?> getSelectedModel() async {
    if (_currentModelId != null) {
      return ModelRegistry.getModelById(_currentModelId!);
    }
    return ModelRegistry.getDefaultModelForProvider(providerType);
  }

  @override
  Future<void> setModel(String modelId) async {
    _currentModelId = modelId;
    await _secureStorage.write(key: _selectedModelKey, value: modelId);
  }

  @override
  Future<bool> isConfigured() async {
    await _loadConfig();
    return _config != null &&
        _config!.isEnabled &&
        _config!.apiKey != null &&
        _config!.apiKey!.isNotEmpty;
  }

  @override
  Future<AIProviderConfig> getConfig() async {
    await _loadConfig();
    return _config ??
        AIProviderConfig(
          type: providerType,
          name: 'Google Gemini',
          isEnabled: false,
        );
  }

  @override
  Future<void> updateConfig(AIProviderConfig config) async {
    _config = config;

    // Initialize Gemini with the new API key if provided
    if (config.apiKey != null && config.apiKey!.isNotEmpty) {
      _gemini = Gemini.init(apiKey: config.apiKey!);
    }

    await _saveConfig();
  }

  @override
  Future<bool> testConnection() async {
    try {
      if (!await isConfigured()) {
        return false;
      }

      // Simple test prompt to check if the API is working
      final response = await _gemini
          .prompt(model: "gemini-1.5-flash", parts: [TextPart('Hello')])
          .timeout(const Duration(seconds: 10));

      return response != null && response.output != null;
    } catch (e) {
      debugPrint('Error testing Gemini connection: $e');
      return false;
    }
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

  @override
  Future<AnalysisResult> analyzeImage(
    String imagePath, {
    AnalysisOptions options = const AnalysisOptions(),
  }) async {
    try {
      // Verify configuration
      if (!await isConfigured()) {
        return AnalysisResult.failure('No Gemini API key configured');
      }

      // Verify image exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return AnalysisResult.failure('Image file not found');
      }

      // Get the selected model
      final model = await getSelectedModel();
      final modelId = model?.id ?? 'gemini-1.5-pro';

      // Build the analysis prompt based on options
      final prompt = _buildAnalysisPrompt(options);

      // Make the API request with timeout
      final response = await _gemini
          .prompt(
            model: modelId,
            parts: [TextPart(prompt), Part.bytes(await file.readAsBytes())],
          )
          .timeout(const Duration(seconds: 30));

      // Handle response
      if (response?.output == null) {
        return AnalysisResult.failure('No response from Gemini API');
      }

      // Extract JSON from response
      final String? rawText = response?.output!
          .replaceAll("```", "")
          .replaceAll("json", "");
      final jsonStartIndex = rawText?.indexOf('{');
      final jsonEndIndex = rawText?.lastIndexOf('}');

      if (jsonStartIndex! >= 0 && jsonEndIndex! > jsonStartIndex) {
        final jsonStr = rawText!.substring(jsonStartIndex, jsonEndIndex + 1);
        return AnalysisResult.success(json.decode(jsonStr));
      } else {
        // Try to extract structured data even if not in perfect JSON format
        final extractedData = _extractStructuredDataFromText(rawText!);
        if (extractedData != null) {
          return AnalysisResult.success(extractedData);
        } else {
          return AnalysisResult.failure(
            'Failed to parse response from Gemini API',
          );
        }
      }
    } on SocketException {
      return AnalysisResult.failure('Network connection failed');
    } on TimeoutException {
      return AnalysisResult.failure('Request timed out');
    } catch (e) {
      if (e.toString().contains('400')) {
        return AnalysisResult.failure(
          'Invalid request - please check your API key and image format',
        );
      }
      if (e.toString().contains('429')) {
        return AnalysisResult.failure('API quota exceeded - try again later');
      }
      return AnalysisResult.failure('Analysis failed: ${e.toString()}');
    }
  }

  @override
  Future<List<AnalysisResult>> analyzeImages(
    List<String> imagePaths, {
    AnalysisOptions options = const AnalysisOptions(),
    void Function(int completed, int total)? progressCallback,
  }) async {
    final results = <AnalysisResult>[];

    for (int i = 0; i < imagePaths.length; i++) {
      final result = await analyzeImage(imagePaths[i], options: options);
      results.add(result);

      // Update progress if callback is provided
      if (progressCallback != null) {
        progressCallback(i + 1, imagePaths.length);
      }
    }

    return results;
  }

  /// Builds the analysis prompt based on the provided options
  String _buildAnalysisPrompt(AnalysisOptions options) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Analyze this UI screenshot and provide structured JSON response with:',
    );

    if (options.detectComponents) {
      buffer.writeln('- components (list of UI elements)');
    }

    if (options.extractText) {
      buffer.writeln('- extractedText (visible text content)');
    }

    if (options.analyzeColorScheme) {
      buffer.writeln('- colorScheme (primary colors)');
    }

    if (options.detectLayoutPatterns) {
      buffer.writeln('- layoutPattern (layout structure)');
    }

    if (options.identifyAccessibilityIssues) {
      buffer.writeln(
        '- accessibilityIssues (potential accessibility problems)',
      );
    }

    if (options.detectDesignSystem) {
      buffer.writeln('- designSystem (detected design system if any)');
    }

    buffer.writeln('- uiType (web/mobile/desktop)');

    if (options.detectBoundingBoxes) {
      buffer.writeln(
        '- componentBoundingBoxes (coordinates of UI elements in format [x1, y1, x2, y2])',
      );
    }

    return buffer.toString();
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

      // Extract accessibility issues
      final accessibilityMatch = RegExp(
        r'accessibilityIssues[":\s]+\[(.*?)\]',
        dotAll: true,
      ).firstMatch(text);
      if (accessibilityMatch != null && accessibilityMatch.groupCount >= 1) {
        final accessibilityText = accessibilityMatch.group(1);
        result['accessibilityIssues'] =
            accessibilityText
                ?.split(',')
                .map((e) => e.trim().replaceAll('"', ''))
                .where((e) => e.isNotEmpty)
                .toList();
      }

      // Extract design system
      final designSystemMatch = RegExp(
        r'designSystem[":\s]+([^,\n}]+)',
      ).firstMatch(text);
      if (designSystemMatch != null && designSystemMatch.groupCount >= 1) {
        result['designSystem'] = designSystemMatch
            .group(1)
            ?.trim()
            .replaceAll('"', '');
      }

      return result;
    } catch (e) {
      debugPrint('Error extracting structured data: $e');
      return null;
    }
  }
}
