import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/ai_model.dart';
import '../../domain/models/ai_provider_config.dart';
import '../../domain/models/analysis_options.dart';
import '../../domain/services/ai_service.dart';
import '../../domain/services/model_registry.dart';

/// Implementation of AIService using OpenAI
class OpenAIService implements AIService {
  final FlutterSecureStorage _secureStorage;
  
  static const String _configKey = 'openai_config';
  static const String _selectedModelKey = 'openai_selected_model';
  
  String? _currentModelId;
  AIProviderConfig? _config;
  
  /// Creates an OpenAIService with the given secure storage
  OpenAIService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _initialize();
  }
  
  @override
  AIProviderType get providerType => AIProviderType.openAI;

  Future<void> _initialize() async {
    try {
      // Load configuration
      await _loadConfig();
      
      // Load selected model
      await _loadSelectedModel();
    } catch (e) {
      debugPrint('Error initializing OpenAI: $e');
    }
  }
  
  Future<void> _loadConfig() async {
    try {
      final configJson = await _secureStorage.read(key: _configKey);
      if (configJson != null) {
        _config = AIProviderConfig.fromJson(json.decode(configJson));
      } else {
        // Create default config if none exists
        _config = AIProviderConfig(
          type: AIProviderType.openAI,
          name: 'OpenAI',
          isEnabled: false,
        );
        
        // Save the new config
        await _saveConfig();
      }
    } catch (e) {
      debugPrint('Error loading OpenAI config: $e');
      _config = AIProviderConfig(
        type: AIProviderType.openAI,
        name: 'OpenAI',
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
        final defaultModel = ModelRegistry.getDefaultModelForProvider(providerType);
        if (defaultModel != null) {
          _currentModelId = defaultModel.id;
          await _secureStorage.write(key: _selectedModelKey, value: _currentModelId);
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
    return _config ?? AIProviderConfig(
      type: providerType,
      name: 'OpenAI',
      isEnabled: false,
    );
  }
  
  @override
  Future<void> updateConfig(AIProviderConfig config) async {
    _config = config;
    await _saveConfig();
  }
  
  @override
  Future<bool> testConnection() async {
    try {
      if (!await isConfigured()) {
        return false;
      }
      
      // Simple test request to check if the API is working
      final url = Uri.parse('https://api.openai.com/v1/models');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${_config!.apiKey!}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error testing OpenAI connection: $e');
      return false;
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
        return AnalysisResult.failure('No OpenAI API key configured');
      }

      // Verify image exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return AnalysisResult.failure('Image file not found');
      }
      
      // Get the selected model
      final model = await getSelectedModel();
      final modelId = model?.id ?? 'gpt-4o';

      // Build the analysis prompt based on options
      final prompt = _buildAnalysisPrompt(options);
      
      // Encode image to base64
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Prepare the API request
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final payload = {
        'model': modelId,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a UI analysis assistant that provides structured JSON responses.',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 2000,
      };
      
      // Make the API request
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${_config!.apiKey!}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));
      
      // Handle response
      if (response.statusCode != 200) {
        return AnalysisResult.failure(
          'OpenAI API error: ${response.statusCode} ${response.body}',
        );
      }
      
      final responseData = json.decode(response.body);
      final content = responseData['choices'][0]['message']['content'];
      
      // Extract JSON from response
      final jsonStartIndex = content.indexOf('{');
      final jsonEndIndex = content.lastIndexOf('}');
      
      if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
        final jsonStr = content.substring(jsonStartIndex, jsonEndIndex + 1);
        return AnalysisResult.success(json.decode(jsonStr));
      } else {
        return AnalysisResult.failure('Failed to parse response from OpenAI API');
      }
    } on SocketException {
      return AnalysisResult.failure('Network connection failed');
    } on TimeoutException {
      return AnalysisResult.failure('Request timed out');
    } catch (e) {
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
    buffer.writeln('Analyze this UI screenshot and provide structured JSON response with:');
    
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
      buffer.writeln('- accessibilityIssues (potential accessibility problems)');
    }
    
    if (options.detectDesignSystem) {
      buffer.writeln('- designSystem (detected design system if any)');
    }
    
    buffer.writeln('- uiType (web/mobile/desktop)');
    
    if (options.detectBoundingBoxes) {
      buffer.writeln('- componentBoundingBoxes (coordinates of UI elements in format [x1, y1, x2, y2])');
    }
    
    return buffer.toString();
  }
}
