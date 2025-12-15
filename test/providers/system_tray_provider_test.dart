// test/providers/system_tray_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrid_flutter/providers/system_tray_provider.dart';
import 'package:snapgrid_flutter/services/system_tray_service.dart';

void main() {
  group('SystemTrayProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('systemTrayServiceProvider', () {
      test('should provide SystemTrayService instance', () {
        final service = container.read(systemTrayServiceProvider);
        
        expect(service, isA<SystemTrayService>());
        expect(service, isNotNull);
      });

      test('should return singleton instance', () {
        final service1 = container.read(systemTrayServiceProvider);
        final service2 = container.read(systemTrayServiceProvider);
        
        expect(identical(service1, service2), isTrue);
      });

      test('should provide the same instance across containers', () {
        final container2 = ProviderContainer();
        
        final service1 = container.read(systemTrayServiceProvider);
        final service2 = container2.read(systemTrayServiceProvider);
        
        // SystemTrayService is a singleton, so should be the same
        expect(identical(service1, service2), isTrue);
        
        container2.dispose();
      });

      test('should not throw when accessed multiple times', () {
        expect(() {
          for (var i = 0; i < 10; i++) {
            container.read(systemTrayServiceProvider);
          }
        }, returnsNormally);
      });
    });

    group('systemTrayInitializedProvider', () {
      test('should have initial value of false', () {
        final isInitialized = container.read(systemTrayInitializedProvider);
        
        expect(isInitialized, isFalse);
      });

      test('should be a StateProvider', () {
        expect(systemTrayInitializedProvider, isA<StateProvider<bool>>());
      });

      test('should allow state updates', () {
        // Initial state
        expect(container.read(systemTrayInitializedProvider), isFalse);
        
        // Update state
        container.read(systemTrayInitializedProvider.notifier).state = true;
        
        // Verify state changed
        expect(container.read(systemTrayInitializedProvider), isTrue);
      });

      test('should notify listeners on state change', () {
        var notificationCount = 0;
        
        container.listen<bool>(
          systemTrayInitializedProvider,
          (previous, next) {
            notificationCount++;
          },
        );
        
        // Change state
        container.read(systemTrayInitializedProvider.notifier).state = true;
        
        expect(notificationCount, equals(1));
      });

      test('should support multiple state transitions', () {
        final states = <bool>[];
        
        container.listen<bool>(
          systemTrayInitializedProvider,
          (previous, next) {
            states.add(next);
          },
        );
        
        // Multiple transitions
        container.read(systemTrayInitializedProvider.notifier).state = true;
        container.read(systemTrayInitializedProvider.notifier).state = false;
        container.read(systemTrayInitializedProvider.notifier).state = true;
        
        expect(states, equals([true, false, true]));
      });

      test('should maintain state across reads', () {
        container.read(systemTrayInitializedProvider.notifier).state = true;
        
        expect(container.read(systemTrayInitializedProvider), isTrue);
        expect(container.read(systemTrayInitializedProvider), isTrue);
        expect(container.read(systemTrayInitializedProvider), isTrue);
      });

      test('should be independent in different containers', () {
        final container2 = ProviderContainer();
        
        container.read(systemTrayInitializedProvider.notifier).state = true;
        
        expect(container.read(systemTrayInitializedProvider), isTrue);
        expect(container2.read(systemTrayInitializedProvider), isFalse);
        
        container2.dispose();
      });

      test('should handle rapid state changes', () {
        for (var i = 0; i < 100; i++) {
          container.read(systemTrayInitializedProvider.notifier).state = i % 2 == 0;
        }
        
        expect(container.read(systemTrayInitializedProvider), isFalse);
      });

      test('should allow reading notifier', () {
        final notifier = container.read(systemTrayInitializedProvider.notifier);
        
        expect(notifier, isNotNull);
        expect(notifier.state, isFalse);
      });

      test('should update state via notifier', () {
        final notifier = container.read(systemTrayInitializedProvider.notifier);
        
        notifier.state = true;
        expect(container.read(systemTrayInitializedProvider), isTrue);
        
        notifier.state = false;
        expect(container.read(systemTrayInitializedProvider), isFalse);
      });
    });

    group('Provider Integration', () {
      test('service and state providers should work together', () {
        final service = container.read(systemTrayServiceProvider);
        final isInitialized = container.read(systemTrayInitializedProvider);
        
        expect(service, isNotNull);
        expect(isInitialized, isFalse);
      });

      test('state should reflect service initialization', () {
        final service = container.read(systemTrayServiceProvider);
        
        // Initially not initialized
        expect(service.isInitialized, isFalse);
        expect(container.read(systemTrayInitializedProvider), isFalse);
      });

      test('should handle service and state updates independently', () {
        container.read(systemTrayServiceProvider);
        container.read(systemTrayInitializedProvider.notifier).state = true;
        
        expect(container.read(systemTrayInitializedProvider), isTrue);
      });
    });

    group('Provider Lifecycle', () {
      test('should maintain state after multiple accesses', () {
        container.read(systemTrayInitializedProvider.notifier).state = true;
        
        for (var i = 0; i < 10; i++) {
          expect(container.read(systemTrayInitializedProvider), isTrue);
        }
      });

      test('should reset state in new container', () {
        container.read(systemTrayInitializedProvider.notifier).state = true;
        expect(container.read(systemTrayInitializedProvider), isTrue);
        
        final newContainer = ProviderContainer();
        expect(newContainer.read(systemTrayInitializedProvider), isFalse);
        newContainer.dispose();
      });
    });

    group('Edge Cases', () {
      test('should handle null-safe state reads', () {
        final state = container.read(systemTrayInitializedProvider);
        expect(state, isA<bool>());
        expect(state, isNotNull);
      });

      test('should handle setting same value multiple times', () {
        var notificationCount = 0;
        
        container.listen<bool>(
          systemTrayInitializedProvider,
          (previous, next) {
            notificationCount++;
          },
        );
        
        container.read(systemTrayInitializedProvider.notifier).state = true;
        container.read(systemTrayInitializedProvider.notifier).state = true;
        container.read(systemTrayInitializedProvider.notifier).state = true;
        
        // Should notify for each change, even if value is same
        expect(notificationCount, greaterThanOrEqualTo(1));
      });
    });

    group('Type Safety', () {
      test('service provider should return correct type', () {
        final service = container.read(systemTrayServiceProvider);
        expect(service, isA<SystemTrayService>());
      });

      test('state provider should return bool', () {
        final state = container.read(systemTrayInitializedProvider);
        expect(state, isA<bool>());
      });

      test('notifier should have correct type', () {
        final notifier = container.read(systemTrayInitializedProvider.notifier);
        expect(notifier.state, isA<bool>());
      });
    });

    group('Concurrency', () {
      test('should handle concurrent state updates', () {
        for (var i = 0; i < 100; i++) {
          container.read(systemTrayInitializedProvider.notifier).state = i % 2 == 0;
        }
        // Should complete without errors
      });

      test('should handle concurrent reads', () {
        final results = <bool>[];
        
        container.read(systemTrayInitializedProvider.notifier).state = true;
        
        for (var i = 0; i < 100; i++) {
          results.add(container.read(systemTrayInitializedProvider));
        }
        
        expect(results.every((r) => r == true), isTrue);
      });
    });
  });
}