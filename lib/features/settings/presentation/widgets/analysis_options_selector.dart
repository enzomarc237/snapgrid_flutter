import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../domain/models/analysis_options.dart';
import '../providers/settings_providers.dart';

/// Widget for configuring analysis options
class AnalysisOptionsSelector extends ConsumerWidget {
  /// Creates an AnalysisOptionsSelector
  const AnalysisOptionsSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(analysisOptionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Options',
          style: MacosTheme.of(context).typography.title3,
        ),
        const SizedBox(height: 8),

        // Preset buttons
        Row(
          children: [
            Text('Presets:', style: MacosTheme.of(context).typography.body),
            const SizedBox(width: 8),
            PushButton(
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: () {
                ref.read(analysisOptionsProvider.notifier).state =
                    AnalysisOptions.basic;
              },
              child: const Text('Basic'),
            ),
            const SizedBox(width: 8),
            PushButton(
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: () {
                ref.read(analysisOptionsProvider.notifier).state =
                    AnalysisOptions.defaults;
              },
              child: const Text('Standard'),
            ),
            const SizedBox(width: 8),
            PushButton(
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: () {
                ref.read(analysisOptionsProvider.notifier).state =
                    AnalysisOptions.comprehensive;
              },
              child: const Text('Comprehensive'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Options checkboxes
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildOptionCheckbox(
              context,
              ref,
              'Detect Components',
              options.detectComponents,
              (value) {
                ref.read(analysisOptionsProvider.notifier).state = options
                    .copyWith(detectComponents: value);
              },
            ),
            _buildOptionCheckbox(
              context,
              ref,
              'Extract Text',
              options.extractText,
              (value) {
                ref.read(analysisOptionsProvider.notifier).state = options
                    .copyWith(extractText: value);
              },
            ),
            _buildOptionCheckbox(
              context,
              ref,
              'Analyze Color Scheme',
              options.analyzeColorScheme,
              (value) {
                ref.read(analysisOptionsProvider.notifier).state = options
                    .copyWith(analyzeColorScheme: value);
              },
            ),
            _buildOptionCheckbox(
              context,
              ref,
              'Detect Layout Patterns',
              options.detectLayoutPatterns,
              (value) {
                ref.read(analysisOptionsProvider.notifier).state = options
                    .copyWith(detectLayoutPatterns: value);
              },
            ),
            _buildOptionCheckbox(
              context,
              ref,
              'Identify Accessibility Issues',
              options.identifyAccessibilityIssues,
              (value) {
                ref.read(analysisOptionsProvider.notifier).state = options
                    .copyWith(identifyAccessibilityIssues: value);
              },
            ),
            _buildOptionCheckbox(
              context,
              ref,
              'Detect Design System',
              options.detectDesignSystem,
              (value) {
                ref.read(analysisOptionsProvider.notifier).state = options
                    .copyWith(detectDesignSystem: value);
              },
            ),
            _buildOptionCheckbox(
              context,
              ref,
              'Detect Bounding Boxes',
              options.detectBoundingBoxes,
              (value) {
                ref.read(analysisOptionsProvider.notifier).state = options
                    .copyWith(detectBoundingBoxes: value);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Confidence threshold slider
        Row(
          children: [
            Text(
              'Confidence Threshold:',
              style: MacosTheme.of(context).typography.body,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MacosSlider(
                value: options.confidenceThreshold,
                min: 0.1,
                max: 1.0,
                splits: 9,
                onChanged: (value) {
                  ref.read(analysisOptionsProvider.notifier).state = options
                      .copyWith(confidenceThreshold: value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(options.confidenceThreshold * 100).toInt()}%',
              style: MacosTheme.of(context).typography.body,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCheckbox(
    BuildContext context,
    WidgetRef ref,
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          MacosCheckbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue),
          ),
          Text(label),
        ],
      ),
    );
  }
}
