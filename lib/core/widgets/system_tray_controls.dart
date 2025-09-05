import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import '../../providers/system_tray_provider.dart';

/// Widget that provides system tray controls in the UI
class SystemTrayControls extends ConsumerWidget {
  const SystemTrayControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemTrayService = ref.read(systemTrayServiceProvider);
    final isInitialized = ref.watch(systemTrayInitializedProvider);

    return MacosListTile(
      leading: const MacosIcon(
        Icons.system_update_alt,
      ),
      title: const Text('System Tray'),
      subtitle: Text(
        isInitialized 
          ? 'App icon is shown in system tray'
          : 'System tray not initialized',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isInitialized) ...[
            MacosTooltip(
              message: 'Update tooltip',
              child: PushButton(
                buttonSize: ButtonSize.small,
                onPressed: () async {
                  await systemTrayService.updateTooltip(
                    'SnapGrid - ${DateTime.now().toString().split(' ')[1].split('.')[0]}',
                  );
                },
                child: const Text('Update'),
              ),
            ),
            const SizedBox(width: 8),
          ],
          MacosTooltip(
            message: isInitialized ? 'Reinitialize' : 'Initialize',
            child: PushButton(
              buttonSize: ButtonSize.small,
              onPressed: () async {
                if (isInitialized) {
                  await systemTrayService.destroy();
                  ref.read(systemTrayInitializedProvider.notifier).state = false;
                }
                await systemTrayService.initialize();
                ref.read(systemTrayInitializedProvider.notifier).state = 
                  systemTrayService.isInitialized;
              },
              child: Text(isInitialized ? 'Reinit' : 'Init'),
            ),
          ),
        ],
      ),
    );
  }
}