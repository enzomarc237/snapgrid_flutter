import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter/services.dart';

import '../providers/screenshot_providers.dart';
import '../services/gemini_service.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  Map<String, String> _directories = {
    'base': 'Loading...',
    'images': 'Loading...',
    'metadata': 'Loading...',
    'trash': 'Loading...',
  };

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadAppDirectory();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    try {
      // Use the geminiServiceProvider to access the GeminiService
      final geminiService = ref.read(geminiServiceProvider);

      // Check if an API key has been set
      final hasKey = await geminiService.hasApiKey();

      if (hasKey) {
        // We don't actually retrieve the key value for security reasons
        // Just show a placeholder to indicate a key is set
        setState(() {
          _apiKeyController.text = '••••••••••••••••••••••••••';
        });
      } else {
        setState(() {
          _apiKeyController.text = '';
        });
      }
    } catch (e) {
      debugPrint('Error loading API key: $e');
    }
  }

  Future<void> _loadAppDirectory() async {
    // Use the provider directly from screenshot_providers.dart
    final directories = await ref.read(appDirectoryProvider.future);
    setState(() {
      _directories = directories.map(
        (key, value) => MapEntry(key, value ?? 'Error loading path'),
      );
    });
  }

  Future<void> _saveApiKey() async {
    try {
      final geminiService = ref.read(geminiServiceProvider);
      final apiKey = _apiKeyController.text.trim();

      setState(() => _isLoading = true);

      // Clear key if empty, otherwise save it
      if (apiKey.isEmpty || apiKey == '••••••••••••••••••••••••••') {
        // Show confirmation dialog before clearing
        if (!mounted) return;
        final shouldClear =
            await showMacosAlertDialog<bool>(
              context: context,
              builder:
                  (_) => MacosAlertDialog(
                    appIcon: const MacosIcon(
                      CupertinoIcons.exclamationmark_triangle,
                    ),
                    title: const Text('Clear API Key?'),
                    message: const Text(
                      'This will remove your Gemini API key. You won\'t be able to '
                      'analyze screenshots until you add a new key. Continue?',
                    ),
                    primaryButton: PushButton(
                      controlSize: ControlSize.large,
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    secondaryButton: PushButton(
                      controlSize: ControlSize.large,
                      secondary: true,
                      child: const Text('Clear Key'),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
            ) ??
            false;

        if (shouldClear) {
          // Clear the API key
          await geminiService.setApiKey('');

          if (!mounted) return;
          showMacosAlertDialog(
            context: context,
            builder:
                (_) => MacosAlertDialog(
                  appIcon: const FlutterLogo(size: 56),
                  title: const Text('API Key Cleared'),
                  message: const Text('Your Gemini API key has been removed.'),
                  primaryButton: PushButton(
                    controlSize: ControlSize.large,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
          );

          _apiKeyController.clear();
        }
      } else {
        // Save the new API key
        await geminiService.setApiKey(apiKey);

        if (!mounted) return;
        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const FlutterLogo(size: 56),
                title: const Text('API Key Saved'),
                message: const Text(
                  'Your Gemini API key has been saved securely.',
                ),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );

        // Set placeholder for security
        _apiKeyController.text = '••••••••••••••••••••••••••';
      }

      // Invalidate the provider to refresh dependent UI
      ref.invalidate(geminiApiKeySetProvider);
    } catch (e) {
      if (!mounted) return;

      showMacosAlertDialog(
        context: context,
        builder:
            (_) => MacosAlertDialog(
              appIcon: const MacosIcon(CupertinoIcons.exclamationmark_triangle),
              title: const Text('Error'),
              message: Text('Failed to save API key: $e'),
              primaryButton: PushButton(
                controlSize: ControlSize.large,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      );

      debugPrint('Error saving API key: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: const ToolBar(title: Text('Settings')),
      children: [
        ContentArea(
          builder:
              (context, scrollController) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: MacosTheme.of(context).typography.largeTitle,
                    ),
                    const SizedBox(height: 24),

                    // Gemini API Key section
                    Text(
                      'Google Gemini API Key',
                      style: MacosTheme.of(context).typography.title3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: MacosTextField(
                            controller: _apiKeyController,
                            placeholder: 'Enter your Google Gemini API key',
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isLoading
                            ? const ProgressCircle(value: null)
                            : PushButton(
                              controlSize: ControlSize.regular,
                              onPressed: _saveApiKey,
                              child: const Text('Save API Key'),
                            ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Storage location section
                    Text(
                      'Storage Locations',
                      style: MacosTheme.of(context).typography.title3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SnapGrid stores your files in the following directories:',
                      style: MacosTheme.of(context).typography.body,
                    ),
                    const SizedBox(height: 16),

                    // Base directory
                    _buildDirectoryInfoTile(
                      context,
                      title: 'Application Directory',
                      path: _directories['base']!,
                      description: 'Root folder for all SnapGrid data',
                    ),
                    const SizedBox(height: 12),

                    // Images directory
                    _buildDirectoryInfoTile(
                      context,
                      title: 'Screenshots',
                      path: _directories['images']!,
                      description: 'Stores your imported UI screenshots',
                    ),
                    const SizedBox(height: 12),

                    // Metadata directory
                    _buildDirectoryInfoTile(
                      context,
                      title: 'Analysis Data',
                      path: _directories['metadata']!,
                      description: 'Contains Gemini AI analysis results',
                    ),
                    const SizedBox(height: 12),

                    // Trash directory
                    _buildDirectoryInfoTile(
                      context,
                      title: 'Trash',
                      path: _directories['trash']!,
                      description: 'Temporarily stores deleted screenshots',
                    ),
                  ],
                ),
              ),
        ),
      ],
    );
  }

  /// Builds a consistent UI tile for displaying directory information
  Widget _buildDirectoryInfoTile(
    BuildContext context, {
    required String title,
    required String path,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            MacosTheme.of(context).brightness == Brightness.dark
                ? MacosColors.controlBackgroundColor.darkColor
                : MacosColors.controlBackgroundColor.color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: MacosTheme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and description
          Text(
            title,
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: MacosTheme.of(context).typography.subheadline,
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Path display with copy button
          Row(
            children: [
              Expanded(
                child: Text(
                  path,
                  style: MacosTheme.of(
                    context,
                  ).typography.body.copyWith(fontFamily: 'Menlo', fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MacosIcon(CupertinoIcons.doc_on_clipboard, size: 14),
                    const SizedBox(width: 4),
                    const Text('Copy'),
                  ],
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: path));

                  // Show feedback via SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Path copied to clipboard'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
