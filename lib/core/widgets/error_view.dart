import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// A reusable widget for displaying errors
class ErrorView extends StatelessWidget {
  /// The error message to display
  final String message;

  /// Optional icon to display
  final IconData icon;

  /// Optional action button
  final Widget? actionButton;

  /// Creates an ErrorView widget
  const ErrorView({
    super.key,
    required this.message,
    this.icon = CupertinoIcons.exclamationmark_triangle,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MacosIcon(icon, size: 48, color: MacosColors.systemRedColor),
          const SizedBox(height: 16),
          Text('Error', style: MacosTheme.of(context).typography.title3),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: MacosTheme.of(context).typography.body,
              textAlign: TextAlign.center,
            ),
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 16),
            actionButton!,
          ],
        ],
      ),
    );
  }
}
