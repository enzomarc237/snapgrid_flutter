import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import 'themed_progress_circle.dart';

/// A reusable widget for displaying loading state
class LoadingView extends StatelessWidget {
  /// Optional message to display
  final String? message;

  /// Creates a LoadingView widget
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ThemedProgressCircle(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: MacosTheme.of(context).typography.body),
          ],
        ],
      ),
    );
  }
}
