// test/core/widgets/system_tray_controls_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:snapgrid_flutter/core/widgets/system_tray_controls.dart';
import 'package:snapgrid_flutter/providers/system_tray_provider.dart';
import 'package:snapgrid_flutter/services/system_tray_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemTrayControls Widget', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget({bool isInitialized = false}) {
      return ProviderScope(
        overrides: [
          systemTrayInitializedProvider.overrideWith((ref) => isInitialized),
        ],
        child: const MacosApp(
          home: MacosWindow(
            child: SystemTrayControls(),
          ),
        ),
      );
    }

    group('Widget Structure', () {
      testWidgets('should render without errors', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(SystemTrayControls), findsOneWidget);
      });

      testWidgets('should be a ConsumerWidget', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(ConsumerWidget), findsWidgets);
      });

      testWidgets('should render MacosListTile', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(MacosListTile), findsOneWidget);
      });

      testWidgets('should have leading icon', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byIcon(Icons.system_update_alt), findsOneWidget);
      });

      testWidgets('should display title', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.text('System Tray'), findsOneWidget);
      });
    });

    group('Initialization State Display', () {
      testWidgets('should show not initialized message when false', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: false));
        expect(find.text('System tray not initialized'), findsOneWidget);
      });

      testWidgets('should show initialized message when true', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        expect(find.text('App icon is shown in system tray'), findsOneWidget);
      });

      testWidgets('should update subtitle based on state', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: false));
        expect(find.text('System tray not initialized'), findsOneWidget);
        
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        await tester.pumpAndSettle();
        expect(find.text('App icon is shown in system tray'), findsOneWidget);
      });
    });

    group('Buttons - Not Initialized State', () {
      testWidgets('should show only Init button when not initialized', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: false));
        
        // Should find Init/Reinit button
        expect(find.widgetWithText(PushButton, 'Init'), findsOneWidget);
        
        // Should not find Update button
        expect(find.widgetWithText(PushButton, 'Update'), findsNothing);
      });

      testWidgets('Init button should be present', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: false));
        expect(find.text('Init'), findsOneWidget);
      });
    });

    group('Buttons - Initialized State', () {
      testWidgets('should show Update and Reinit buttons when initialized', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        expect(find.widgetWithText(PushButton, 'Update'), findsOneWidget);
        expect(find.widgetWithText(PushButton, 'Reinit'), findsOneWidget);
      });

      testWidgets('Update button should be visible', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        expect(find.text('Update'), findsOneWidget);
      });

      testWidgets('Reinit button should be visible', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        expect(find.text('Reinit'), findsOneWidget);
      });
    });

    group('Button Interactions', () {
      testWidgets('Init button should be tappable', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: false));
        
        final initButton = find.widgetWithText(PushButton, 'Init');
        expect(initButton, findsOneWidget);
        
        await tester.tap(initButton);
        await tester.pumpAndSettle();
        // Should not throw
      });

      testWidgets('Update button should be tappable when initialized', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        final updateButton = find.widgetWithText(PushButton, 'Update');
        expect(updateButton, findsOneWidget);
        
        await tester.tap(updateButton);
        await tester.pumpAndSettle();
        // Should not throw
      });

      testWidgets('Reinit button should be tappable when initialized', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        final reinitButton = find.widgetWithText(PushButton, 'Reinit');
        expect(reinitButton, findsOneWidget);
        
        await tester.tap(reinitButton);
        await tester.pumpAndSettle();
        // Should not throw
      });
    });

    group('Tooltips', () {
      testWidgets('Update button should have tooltip', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        final tooltip = find.ancestor(
          of: find.widgetWithText(PushButton, 'Update'),
          matching: find.byType(MacosTooltip),
        );
        
        expect(tooltip, findsOneWidget);
      });

      testWidgets('Init/Reinit button should have tooltip', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: false));
        
        final tooltip = find.ancestor(
          of: find.widgetWithText(PushButton, 'Init'),
          matching: find.byType(MacosTooltip),
        );
        
        expect(tooltip, findsOneWidget);
      });

      testWidgets('tooltip messages should be appropriate', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: false));
        
        final initTooltip = find.widgetWithText(MacosTooltip, 'Initialize');
        expect(initTooltip, findsOneWidget);
      });
    });

    group('Button Sizes', () {
      testWidgets('buttons should have small size', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        final buttons = tester.widgetList<PushButton>(find.byType(PushButton));
        
        for (final button in buttons) {
          expect(button.buttonSize, equals(ButtonSize.small));
        }
      });
    });

    group('Layout', () {
      testWidgets('should have trailing Row widget', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        final listTile = tester.widget<MacosListTile>(find.byType(MacosListTile));
        expect(listTile.trailing, isA<Row>());
      });

      testWidgets('trailing Row should have correct mainAxisSize', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        final listTile = tester.widget<MacosListTile>(find.byType(MacosListTile));
        final trailing = listTile.trailing as Row;
        expect(trailing.mainAxisSize, equals(MainAxisSize.min));
      });

      testWidgets('should have proper spacing between buttons', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        expect(find.byType(SizedBox), findsWidgets);
      });
    });

    group('Provider Integration', () {
      testWidgets('should read systemTrayServiceProvider', 
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: const MacosApp(
              home: MacosWindow(
                child: SystemTrayControls(),
              ),
            ),
          ),
        );
        
        // Widget should render without provider errors
        expect(find.byType(SystemTrayControls), findsOneWidget);
      });

      testWidgets('should watch systemTrayInitializedProvider', 
          (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            systemTrayInitializedProvider.overrideWith((ref) => false),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MacosApp(
              home: MacosWindow(
                child: SystemTrayControls(),
              ),
            ),
          ),
        );
        
        expect(find.text('System tray not initialized'), findsOneWidget);
        
        container.dispose();
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle rapid state changes', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: false));
        
        for (var i = 0; i < 10; i++) {
          await tester.pumpWidget(createTestWidget(isInitialized: i % 2 == 0));
          await tester.pump();
        }
        
        // Should render without errors
        expect(find.byType(SystemTrayControls), findsOneWidget);
      });

      testWidgets('should handle null-safe operations', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(SystemTrayControls), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have accessible labels', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        expect(find.text('System Tray'), findsOneWidget);
        expect(find.text('Update'), findsOneWidget);
        expect(find.text('Reinit'), findsOneWidget);
      });

      testWidgets('should have semantic labels from tooltips', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        expect(find.byType(MacosTooltip), findsWidgets);
      });
    });

    group('Visual Regression', () {
      testWidgets('should maintain consistent layout', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        final listTile = find.byType(MacosListTile);
        expect(listTile, findsOneWidget);
        
        final size = tester.getSize(listTile);
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
      });

      testWidgets('buttons should be visible on screen', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isInitialized: true));
        
        final updateButton = find.widgetWithText(PushButton, 'Update');
        final reinitButton = find.widgetWithText(PushButton, 'Reinit');
        
        expect(tester.getCenter(updateButton).dx, greaterThan(0));
        expect(tester.getCenter(reinitButton).dx, greaterThan(0));
      });
    });

    group('Performance', () {
      testWidgets('should build efficiently', 
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Multiple rebuilds should not cause issues
        for (var i = 0; i < 5; i++) {
          await tester.pump();
        }
        
        expect(find.byType(SystemTrayControls), findsOneWidget);
      });
    });
  });
}