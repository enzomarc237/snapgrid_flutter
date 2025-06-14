import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_providers.dart';
import 'core/utils/platform_menu_bar.dart';
import 'core/utils/platform_utils.dart';
import 'core/utils/window_utils.dart';
import 'features/categories/presentation/providers/category_providers.dart';
import 'features/screenshots/presentation/screens/main_screen.dart';
import 'services/system_tray_service.dart';
import 'providers/system_tray_provider.dart';

/// Global navigator key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Configure window options
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });

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
class SnapGridApp extends ConsumerStatefulWidget {
  /// Creates the main application widget
  const SnapGridApp({super.key});

  @override
  ConsumerState<SnapGridApp> createState() => _SnapGridAppState();
}

class _SnapGridAppState extends ConsumerState<SnapGridApp> with WindowListener {

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initializeSystemTray();
  }

  Future<void> _initializeSystemTray() async {
    try {
      await SystemTrayService().initialize();
      if (mounted) {
        ref.read(systemTrayInitializedProvider.notifier).state = true;
      }
    } catch (e) {
      debugPrint('Failed to initialize system tray: $e');
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Prevent the window from closing and hide it instead
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

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
