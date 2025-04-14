import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../domain/models/category.dart';
import '../providers/category_providers.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final Category? categoryToEdit;

  const AddEditCategoryScreen({super.key, this.categoryToEdit});

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  IconData _selectedIcon = CupertinoIcons.folder;
  String? _titleError;

  final List<IconData> _availableIcons = [
    CupertinoIcons.folder, CupertinoIcons.doc_text, CupertinoIcons.paintbrush,
    CupertinoIcons.lightbulb, CupertinoIcons.tag, CupertinoIcons.bookmark,
    // Add more icons as needed
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.categoryToEdit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.categoryToEdit?.description ?? '');
    _selectedIcon = widget.categoryToEdit?.icon ?? _availableIcons.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    setState(() {
      _titleError = title.isEmpty ? 'Title cannot be empty' : null;
    });

    if (_titleError != null) return;

    final notifier = ref.read(categoryListProvider.notifier);

    try {
      if (widget.categoryToEdit == null) {
        final newCategory = Category(
          id: '', // ID will be generated
          title: title,
          description: description,
          icon: _selectedIcon,
        );
        await notifier.addCategory(newCategory);
      } else {
        final updatedCategory = Category(
          id: widget.categoryToEdit!.id,
          title: title,
          description: description,
          icon: _selectedIcon,
        );
        await notifier.updateCategory(updatedCategory);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showMacosAlertDialog(
          context: context,
          builder: (_) => MacosAlertDialog(
            appIcon: const MacosIcon(CupertinoIcons.exclamationmark_octagon),
            title: const Text('Error'),
            message: Text('Failed to save category: $e'),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: Text(widget.categoryToEdit == null ? 'Add Category' : 'Edit Category'),
        leading: MacosBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          ToolBarIconButton(
            label: 'Save',
            icon: const MacosIcon(CupertinoIcons.checkmark_circle),
            onPressed: _saveCategory,
            showLabel: true,
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Title'),
                const SizedBox(height: 8),
                MacosTextField(
                  controller: _titleController,
                  placeholder: 'Enter category title',
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _titleError!,
                    style: TextStyle(color: MacosColors.systemRedColor),
                  ),
                ],
                
                const SizedBox(height: 20),
                const Text('Description'),
                const SizedBox(height: 8),
                MacosTextField(
                  controller: _descriptionController,
                  placeholder: 'Enter category description',
                  maxLines: 3,
                ),
                
                const SizedBox(height: 20),
                const Text('Icon'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _availableIcons.map((icon) {
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? MacosTheme.of(context).primaryColor.withAlpha(26) : null, // 0.1 opacity = ~26 alpha
                          border: Border.all(
                            color: isSelected ? MacosTheme.of(context).primaryColor : MacosTheme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MacosIcon(icon),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}