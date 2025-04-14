import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../domain/models/category.dart';
import '../providers/category_providers.dart';

/// Screen for managing categories (viewing, adding, potentially editing/deleting).
class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen> {
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  void _addCategory() {
    final newCategoryName = _newCategoryController.text.trim();
    if (newCategoryName.isNotEmpty) {
      final categoryListNotifier = ref.read(categoryListProvider.notifier);
      final newCategory = Category(
        // Using timestamp for a simple unique ID, consider a more robust approach if needed
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: newCategoryName,
        // Default icon, could be made selectable later
        icon: CupertinoIcons.folder,
      );
      categoryListNotifier.addCategory(newCategory);
      _newCategoryController.clear(); // Clear the text field after adding
      print('Creating category: ${newCategory.title}'); // For debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Gérer les catégories'),
        leading: MacosBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section to add a new category
                  Row(
                    children: [
                      Expanded(
                        child: MacosTextField(
                          controller: _newCategoryController,
                          placeholder: 'Nom de la nouvelle catégorie',
                          onSubmitted: (_) => _addCategory(), // Allow adding via Enter key
                        ),
                      ),
                      const SizedBox(width: 10),
                      PushButton(
                        controlSize: ControlSize.regular,
                        onPressed: _addCategory,
                        child: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Catégories existantes:',
                    style: MacosTheme.of(context).typography.headline,
                  ),
                  const SizedBox(height: 10),
                  // List of existing categories
                  Expanded(
                    child: categories.when(
                      data: (categoryList) {
                        if (categoryList.isEmpty) {
                          return const Center(child: Text('Aucune catégorie créée.'));
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: categoryList.length,
                          itemBuilder: (context, index) {
                            final category = categoryList[index];
                            return MacosListTile(
                              leading: MacosIcon(category.icon),
                              title: Text(category.title),
                              // TODO: Add trailing delete/edit buttons later if needed
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: ProgressCircle()),
                      error: (error, stackTrace) => Center(
                        child: Text('Erreur lors du chargement des catégories: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}