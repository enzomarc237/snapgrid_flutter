import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/widgets/themed_progress_circle.dart';

import '../providers/settings_providers.dart';
import '../widgets/ai_provider_selector.dart';
import '../widgets/analysis_options_selector.dart';
import '../widgets/directory_info_tile.dart';
import '../widgets/gemini_model_selector.dart';
import '../widgets/theme_settings_section.dart';

/// Screen that displays application settings
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates a SettingsScreen
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    ref.read(appDirectoriesProvider);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    try {
      final config = await ref.read(activeProviderConfigProvider.future);

      if (config.apiKey != null && config.apiKey!.isNotEmpty) {
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

  Future<void> _saveApiKey() async {
    try {
      final manager = ref.read(aiProviderManagerProvider);
      final activeProvider = ref.read(activeProviderTypeProvider);
      final config = await manager.getConfig(activeProvider);
      final apiKey = _apiKeyController.text.trim();

      setState(() => _isLoading = true);

      if (apiKey.isEmpty || apiKey == '••••••••••••••••••••••••••') {
        // If empty or masked, ask if they want to clear the key
        if (!mounted) return;
        final shouldClear =
            await showMacosAlertDialog<bool>(
              context: context,
              builder:
                  (_) => MacosAlertDialog(
                    appIcon: const MacosIcon(CupertinoIcons.lock),
                    title: const Text('Clear API Key?'),
                    message: Text(
                      'Do you want to remove your ${config?.name ?? "AI"} API key?',
                    ),
                    primaryButton: PushButton(
                      controlSize: ControlSize.large,
                      child: const Text('Keep Key'),
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
          if (config != null) {
            final updatedConfig = config.copyWith(apiKey: '', isEnabled: false);
            await manager.updateConfig(activeProvider, updatedConfig);
          }

          if (!mounted) return;
          showMacosAlertDialog(
            context: context,
            builder:
                (_) => MacosAlertDialog(
                  appIcon: const MacosIcon(CupertinoIcons.lock),
                  title: const Text('API Key Cleared'),
                  message: Text(
                    'Your ${config?.name ?? "AI"} API key has been removed.',
                  ),
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
        if (config != null) {
          final updatedConfig = config.copyWith(
            apiKey: apiKey,
            isEnabled: true,
          );
          await manager.updateConfig(activeProvider, updatedConfig);
        }

        if (!mounted) return;
        showMacosAlertDialog(
          context: context,
          builder:
              (_) => MacosAlertDialog(
                appIcon: const MacosIcon(CupertinoIcons.lock),
                title: const Text('API Key Saved'),
                message: Text(
                  'Your ${config?.name ?? "AI"} API key has been saved securely.',
                ),
                primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        );

        // Replace with masked version
        _apiKeyController.text = '••••••••••••••••••••••••••';
      }

      // Invalidate the providers to refresh dependent UI
      ref.invalidate(activeProviderConfigProvider);
      ref.invalidate(isActiveProviderConfiguredProvider);
      ref.invalidate(allProviderConfigsProvider);
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
    final directoriesAsync = ref.watch(appDirectoriesProvider);

    return MacosScaffold(
      children: [
        ContentArea(
          builder:
              (context, scrollController) => Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: MacosTheme.of(context).typography.largeTitle,
                      ),
                      const SizedBox(height: 24),

                      // AI Provider section
                      const AIProviderSelector(),
                      const SizedBox(height: 24),

                      // API key section
                      Text(
                        'API Key',
                        style: MacosTheme.of(context).typography.title3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your API key to enable AI analysis features.',
                        style: MacosTheme.of(context).typography.body,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: MacosTextField(
                              controller: _apiKeyController,
                              placeholder: 'Enter your API key',
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

                      // Gemini model selector
                      const GeminiModelSelector(),
                      const SizedBox(height: 24),

                      // Analysis options section
                      const AnalysisOptionsSelector(),
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

                      // Directory info
                      directoriesAsync.when(
                        data:
                            (directories) => Column(
                              children: [
                                // Base directory
                                DirectoryInfoTile(
                                  title: 'Application Directory',
                                  path: directories['base']!,
                                  description:
                                      'Root folder for all SnapGrid data',
                                ),
                                const SizedBox(height: 12),

                                // Images directory
                                DirectoryInfoTile(
                                  title: 'Screenshots',
                                  path: directories['images']!,
                                  description:
                                      'Stores your imported UI screenshots',
                                ),
                                const SizedBox(height: 12),

                                // Metadata directory
                                DirectoryInfoTile(
                                  title: 'Analysis Data',
                                  path: directories['metadata']!,
                                  description:
                                      'Contains Gemini AI analysis results',
                                ),
                                const SizedBox(height: 12),

                                // Trash directory
                                DirectoryInfoTile(
                                  title: 'Trash',
                                  path: directories['trash']!,
                                  description:
                                      'Temporarily stores deleted screenshots',
                                ),
                              ],
                            ),
                        loading:
                            () => const Center(child: ThemedProgressCircle()),
                        error:
                            (error, stack) =>
                                Text('Error loading directories: $error'),
                      ),

                      const SizedBox(height: 24),

                      // Theme settings section
                      const ThemeSettingsSection(),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),

                      // About section
                      Text(
                        'About',
                        style: MacosTheme.of(context).typography.title3,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              MacosTheme.of(context).brightness ==
                                      Brightness.dark
                                  ? MacosColors.controlBackgroundColor.darkColor
                                  : MacosColors.controlBackgroundColor.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: MacosTheme.of(context).dividerColor,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SnapGrid',
                              style: MacosTheme.of(context).typography.headline,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version 1.0.1',
                              style: MacosTheme.of(context).typography.body,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A modern screenshot management tool with AI-powered UI element detection',
                              style: MacosTheme.of(context).typography.body,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ],
    );
  }
}
