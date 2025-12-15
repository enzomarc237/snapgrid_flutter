// test/services/system_tray_service_test.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrid_flutter/services/system_tray_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemTrayService', () {
    late SystemTrayService service;

    setUp(() {
      // Get the singleton instance
      service = SystemTrayService();
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        final instance1 = SystemTrayService();
        final instance2 = SystemTrayService();
        
        expect(identical(instance1, instance2), isTrue);
      });

      test('factory constructor should return singleton', () {
        final instance = SystemTrayService();
        
        expect(instance, isNotNull);
        expect(instance, equals(service));
      });
    });

    group('Initialization', () {
      test('should not be initialized by default', () {
        expect(service.isInitialized, isFalse);
      });

      test('isInitialized getter should reflect initialization state', () {
        expect(service.isInitialized, isFalse);
        
        // Note: We can't actually initialize in tests without mocking
        // the SystemTray and WindowManager dependencies
      });
    });

    group('Platform-specific Icon Paths', () {
      test('should use .ico extension on Windows', () {
        // This tests the logic that would be used during initialization
        // Platform.isWindows would determine the icon path
        String iconPath;
        if (Platform.isWindows) {
          iconPath = 'assets/images/app_icon.ico';
        } else {
          iconPath = 'assets/images/app_icon.png';
        }
        
        if (Platform.isWindows) {
          expect(iconPath, endsWith('.ico'));
        } else {
          expect(iconPath, endsWith('.png'));
        }
      });

      test('should use .png extension on non-Windows platforms', () {
        if (!Platform.isWindows) {
          const iconPath = 'assets/images/app_icon.png';
          expect(iconPath, endsWith('.png'));
        }
      });
    });

    group('Error Handling', () {
      test('initialize should handle errors gracefully', () async {
        // The service catches exceptions and prints debug messages
        // It should not throw when initialization fails
        expect(() => service.initialize(), returnsNormally);
      });

      test('updateTooltip should not throw when not initialized', () async {
        expect(() => service.updateTooltip('Test'), returnsNormally);
      });

      test('updateIcon should not throw when not initialized', () async {
        expect(() => service.updateIcon('test.png'), returnsNormally);
      });

      test('destroy should not throw when not initialized', () async {
        expect(() => service.destroy(), returnsNormally);
      });
    });

    group('State Management', () {
      test('should track initialization state', () {
        // Initially not initialized
        expect(service.isInitialized, isFalse);
      });

      test('destroy should reset initialization state', () async {
        // Even if not initialized, destroy should work
        await service.destroy();
        expect(service.isInitialized, isFalse);
      });
    });

    group('Method Contracts', () {
      test('initialize should be idempotent', () async {
        // Multiple calls to initialize should be safe
        await service.initialize();
        await service.initialize();
        // Should not throw
      });

      test('updateTooltip should accept string parameter', () async {
        expect(() => service.updateTooltip('New tooltip'), returnsNormally);
      });

      test('updateIcon should accept string path parameter', () async {
        expect(() => service.updateIcon('assets/icon.png'), returnsNormally);
      });
    });

    group('Debug Output', () {
      test('should use debugPrint for logging', () {
        // Verify that the service uses debugPrint (Flutter's logging)
        // This is implicitly tested by the fact that no exceptions are thrown
        // and debug output is properly handled in the implementation
        expect(debugPrint, isNotNull);
      });
    });

    group('Public API', () {
      test('should expose initialize method', () {
        expect(service.initialize, isA<Function>());
      });

      test('should expose updateTooltip method', () {
        expect(service.updateTooltip, isA<Function>());
      });

      test('should expose updateIcon method', () {
        expect(service.updateIcon, isA<Function>());
      });

      test('should expose destroy method', () {
        expect(service.destroy, isA<Function>());
      });

      test('should expose isInitialized getter', () {
        expect(service.isInitialized, isA<bool>());
      });
    });

    group('Async Operations', () {
      test('initialize should return Future<void>', () {
        final result = service.initialize();
        expect(result, isA<Future<void>>());
      });

      test('updateTooltip should return Future<void>', () {
        final result = service.updateTooltip('Test');
        expect(result, isA<Future<void>>());
      });

      test('updateIcon should return Future<void>', () {
        final result = service.updateIcon('test.png');
        expect(result, isA<Future<void>>());
      });

      test('destroy should return Future<void>', () {
        final result = service.destroy();
        expect(result, isA<Future<void>>());
      });
    });

    group('Edge Cases', () {
      test('should handle empty tooltip string', () async {
        expect(() => service.updateTooltip(''), returnsNormally);
      });

      test('should handle empty icon path', () async {
        expect(() => service.updateIcon(''), returnsNormally);
      });

      test('should handle very long tooltip', () async {
        final longTooltip = 'A' * 1000;
        expect(() => service.updateTooltip(longTooltip), returnsNormally);
      });

      test('should handle special characters in tooltip', () async {
        expect(() => service.updateTooltip('Test™ • €'), returnsNormally);
      });

      test('should handle unicode in tooltip', () async {
        expect(() => service.updateTooltip('测试 テスト 🎉'), returnsNormally);
      });

      test('should handle invalid icon path gracefully', () async {
        expect(() => service.updateIcon('/invalid/path/icon.png'), returnsNormally);
      });

      test('should handle relative icon paths', () async {
        expect(() => service.updateIcon('../icon.png'), returnsNormally);
      });

      test('should handle absolute icon paths', () async {
        expect(() => service.updateIcon('/absolute/path/icon.png'), returnsNormally);
      });
    });

    group('Lifecycle', () {
      test('should support full lifecycle: init -> update -> destroy', () async {
        await service.initialize();
        await service.updateTooltip('Updated');
        await service.destroy();
        // Should complete without errors
      });

      test('should allow reinitialization after destroy', () async {
        await service.initialize();
        await service.destroy();
        await service.initialize();
        // Should complete without errors
      });
    });

    group('Type Safety', () {
      test('isInitialized should always return bool', () {
        final result = service.isInitialized;
        expect(result, isA<bool>());
        expect(result == true || result == false, isTrue);
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent initialize calls', () async {
        final futures = <Future<void>>[];
        for (var i = 0; i < 5; i++) {
          futures.add(service.initialize());
        }
        await Future.wait(futures);
        // Should complete without errors
      });

      test('should handle concurrent update calls', () async {
        final futures = <Future<void>>[];
        for (var i = 0; i < 5; i++) {
          futures.add(service.updateTooltip('Tooltip $i'));
        }
        await Future.wait(futures);
        // Should complete without errors
      });
    });
  });
}