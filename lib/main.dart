import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_providers.dart';
import 'core/utils/platform_menu_bar.dart';
import 'core/utils/platform_utils.dart';
import 'core/utils/window_utils.dart';
import 'features/categories/presentation/providers/category_providers.dart';
import 'features/screenshots/presentation/screens/main_screen.dart';

/// Global navigator key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Configure macOS window if running on macOS
  if (PlatformUtils.isMacOS) {
    await WindowUtils.configureMacosWindow();
  }

  runApp(
    ProviderScope(
      overrides: [
        // Override the sharedPreferencesProvider with the actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SnapGridApp(),
    ),
  );
}

/// The main application widget
class SnapGridApp extends ConsumerWidget {
  /// Creates the main application widget
  const SnapGridApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme settings
    final themeSettings = ref.watch(themeSettingsProvider);

    return MacosApp(
      navigatorKey: navigatorKey,
      builder: (context, child) {
        return PlatformMenuBar(
          menus:
              AppPlatformMenuBar.build(
                navigatorKey.currentContext ?? context,
                ref,
              ).menus,
          child: child!,
        );
      },
      title: 'SnapGrid',
      theme: AppTheme.lightTheme(
        accentColor: themeSettings.accentColor,
        highContrast: themeSettings.highContrast,
      ),
      darkTheme: AppTheme.darkTheme(
        accentColor: themeSettings.accentColor,
        highContrast: themeSettings.highContrast,
      ),
      themeMode: themeSettings.themeMode,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}
