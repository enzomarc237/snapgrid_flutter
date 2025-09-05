import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/system_tray_service.dart';

/// Provider for the system tray service
final systemTrayServiceProvider = Provider<SystemTrayService>((ref) {
  return SystemTrayService();
});

/// Provider for system tray initialization status
final systemTrayInitializedProvider = StateProvider<bool>((ref) {
  return false;
});