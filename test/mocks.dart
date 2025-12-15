import 'package:mockito/annotations.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

// Generate mocks for SystemTray and WindowManager
@GenerateMocks([SystemTray])
class MockSystemTray {}

// Note: WindowManager is a singleton with static methods, 
// so we'll need to test it differently or mock at a higher level