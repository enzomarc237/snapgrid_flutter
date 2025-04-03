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
  String _appDirectoryPath = 'Loading...';

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
    // TODO: Implement with flutter_secure_storage (Phase 4)
    // final secureStorage = ref.read(flutterSecureStorageProvider);
    // final key = await secureStorage.read(key: 'geminiApiKey');
    // if (key != null && key.isNotEmpty) {
    //   _apiKeyController.text = key;
    // }
  }

  Future<void> _loadAppDirectory() async {
    // Use the provider directly from screenshot_providers.dart
    final directories = await ref.read(appDirectoryProvider.future);
    setState(() {
      _appDirectoryPath = directories['base'] ?? 'Error loading path';
    });
  }

  Future<void> _saveApiKey() async {
    // TODO: Implement with flutter_secure_storage (Phase 4)
    // final secureStorage = ref.read(flutterSecureStorageProvider);
    // final apiKey = _apiKeyController.text;
    setState(() => _isLoading = true);
    // await secureStorage.write(key: 'geminiApiKey', value: apiKey);
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate save
    setState(() => _isLoading = false);
    // ref.invalidate(geminiApiKeySetProvider); // Invalidate check provider

    if (!mounted) return;
    showMacosAlertDialog(
      context: context,
      builder:
          (_) => MacosAlertDialog(
            appIcon: const FlutterLogo(size: 56),
            title: const Text('API Key Saved'),
            message: const Text('Your Gemini API key has been saved securely.'),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
    );
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
                      'Storage Location',
                      style: MacosTheme.of(context).typography.title3,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            MacosTheme.of(context).brightness == Brightness.dark
                                ? MacosColors.controlBackgroundColor.darkColor
                                : MacosColors.controlBackgroundColor.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _appDirectoryPath,
                              style: MacosTheme.of(
                                context,
                              ).typography.body.copyWith(fontFamily: 'Menlo'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PushButton(
                            controlSize: ControlSize.small,
                            child: const Text('Copy Path'),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _appDirectoryPath),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ],
    );
  }
}
