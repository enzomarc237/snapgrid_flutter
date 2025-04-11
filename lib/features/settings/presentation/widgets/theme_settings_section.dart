import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_providers.dart';
import '../../../../core/theme/theme_settings.dart';

/// Widget that displays theme settings
class ThemeSettingsSection extends ConsumerWidget {
  /// Creates a ThemeSettingsSection
  const ThemeSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: MacosTheme.of(context).typography.title3),
        const SizedBox(height: 16),

        // Theme mode selection
        _buildThemeModeSelector(context, ref, themeSettings),
        const SizedBox(height: 24),

        // Accent color selection
        _buildAccentColorSelector(context, ref, themeSettings),
        const SizedBox(height: 24),

        // High contrast mode
        _buildHighContrastToggle(context, ref, themeSettings),
        const SizedBox(height: 24),

        // Theme presets
        _buildThemePresets(context, ref),
      ],
    );
  }

  Widget _buildThemeModeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeSettings themeSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Mode',
          style: MacosTheme.of(
            context,
          ).typography.subheadline.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: themeSettings.themeMode != ThemeMode.system,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    MacosIcon(CupertinoIcons.device_desktop, size: 16),
                    SizedBox(width: 4),
                    Text('System'),
                  ],
                ),
                onPressed: () {
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: themeSettings.themeMode != ThemeMode.light,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    MacosIcon(CupertinoIcons.sun_max, size: 16),
                    SizedBox(width: 4),
                    Text('Light'),
                  ],
                ),
                onPressed: () {
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: themeSettings.themeMode != ThemeMode.dark,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    MacosIcon(CupertinoIcons.moon, size: 16),
                    SizedBox(width: 4),
                    Text('Dark'),
                  ],
                ),
                onPressed: () {
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setThemeMode(ThemeMode.dark);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccentColorSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeSettings themeSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accent Color',
          style: MacosTheme.of(
            context,
          ).typography.subheadline.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              AppTheme.accentColors.map((color) {
                final isSelected = color == themeSettings.accentColor;

                return GestureDetector(
                  onTap: () {
                    ref
                        .read(themeSettingsProvider.notifier)
                        .setAccentColor(color);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? MacosTheme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child:
                        isSelected
                            ? Icon(
                              CupertinoIcons.checkmark,
                              color:
                                  color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                              size: 20,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildHighContrastToggle(
    BuildContext context,
    WidgetRef ref,
    ThemeSettings themeSettings,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'High Contrast',
                style: MacosTheme.of(
                  context,
                ).typography.subheadline.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Increases contrast for better readability',
                style: MacosTheme.of(context).typography.body,
              ),
            ],
          ),
        ),
        MacosSwitch(
          value: themeSettings.highContrast,
          onChanged: (value) {
            ref.read(themeSettingsProvider.notifier).setHighContrast(value);
          },
        ),
      ],
    );
  }

  Widget _buildThemePresets(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Presets',
          style: MacosTheme.of(
            context,
          ).typography.subheadline.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPresetButton(
              context,
              ref,
              'Default',
              ThemeSettings.defaults,
              CupertinoIcons.device_desktop,
            ),
            const SizedBox(width: 8),
            _buildPresetButton(
              context,
              ref,
              'High Contrast',
              ThemeSettings.highContrastPreset(),
              CupertinoIcons.eye,
            ),
            const SizedBox(width: 8),
            _buildPresetButton(
              context,
              ref,
              'Colorful',
              ThemeSettings.colorfulPreset(),
              CupertinoIcons.paintbrush,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    ThemeSettings preset,
    IconData icon,
  ) {
    return PushButton(
      controlSize: ControlSize.regular,
      secondary: true,
      onPressed: () {
        ref.read(themeSettingsProvider.notifier).applyPreset(preset);
      },
      child: Row(
        children: [
          MacosIcon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}
