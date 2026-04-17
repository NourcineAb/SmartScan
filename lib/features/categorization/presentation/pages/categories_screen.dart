import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../bloc/category_bloc.dart';
import '../widgets/category_card.dart';
import '../dialogs/add_edit_category_dialog.dart';
import 'category_documents_screen.dart';
import '../../../../core/services/feedback_service.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryBloc(
        categoryRepository: CategoryRepository(),
      )..add(const LoadCategoriesEvent()),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView();

  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  late final CategoryRepository _repository = CategoryRepository();
  bool _isGridView = true;

  void _addCategory() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddEditCategoryDialog(),
    );

    if (result != null && mounted) {
      if (context.mounted) {
        context.read<CategoryBloc>().add(
              AddCategoryEvent(
                name: result['name'],
                icon: result['icon'],
                color: result['color'],
              ),
            );
      }
    }
  }

  void _editCategory(CategoryModel category) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddEditCategoryDialog(category: category),
    );

    if (result != null && mounted) {
      if (context.mounted) {
        context.read<CategoryBloc>().add(
              UpdateCategoryEvent(
                id: category.id,
                name: result['name'],
                icon: result['icon'],
                color: result['color'],
              ),
            );
      }
    }
  }

  void _deleteCategory(String categoryId, String categoryName) {
    // Get the CategoryBloc reference before showing the dialog to avoid context scope issues
    final categoryBloc = context.read<CategoryBloc>();

    // Add delay to allow PopupMenu to close properly before showing dialog
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete Category?'),
          content: Text('Are you sure you want to delete "$categoryName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Use the captured bloc reference
                categoryBloc.add(DeleteCategoryEvent(id: categoryId));
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _openCategoryDocuments(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDocumentsScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_3x3),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: BlocListener<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${state.category.name} created!')),
            );
            context.read<CategoryBloc>().add(const LoadCategoriesEvent());
          } else if (state is CategoryUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category updated!')),
            );
            context.read<CategoryBloc>().add(const LoadCategoriesEvent());
          } else if (state is CategoryDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category deleted!')),
            );
            context.read<CategoryBloc>().add(const LoadCategoriesEvent());
          } else if (state is CategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoryEmpty) {
              return _buildEmptyState();
            } else if (state is CategoriesLoaded) {
              if (state.categories.isEmpty) {
                return _buildEmptyState();
              }
              return _isGridView
                  ? _buildGridView(state.categories)
                  : _buildListView(state.categories);
            } else if (state is CategoryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<CategoryBloc>()
                            .add(const LoadCategoriesEvent());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FeedbackService().onTap();
          _addCategory();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Categories Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Create a category to organize your documents'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(Icons.add),
            label: const Text('Create Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<CategoryModel> categories) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCard(
          category: categories[index],
          documentCount: _repository.getDocumentCountForCategory(
            categories[index].id,
          ),
          onTap: () => _openCategoryDocuments(categories[index]),
          onEdit: () => _editCategory(categories[index]),
          onDelete: () =>
              _deleteCategory(categories[index].id, categories[index].name),
        );
      },
    );
  }

  Widget _buildListView(List<CategoryModel> categories) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final documentCount = _repository.getDocumentCountForCategory(
          category.id,
        );

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(category.color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(category.icon),
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '$documentCount document${documentCount != 1 ? 's' : ''}',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                  onTap: () => _editCategory(category),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                  onTap: () => _deleteCategory(category.id, category.name),
                ),
              ],
            ),
            onTap: () => _openCategoryDocuments(category),
          ),
        );
      },
    );
  }

  IconData _getIconData(String? iconName) {
    final icons = {
      'receipt': Icons.receipt,
      'shopping_cart': Icons.shopping_cart,
      'credit_card': Icons.credit_card,
      'description': Icons.description,
      'folder': Icons.folder,
      'image': Icons.image,
      'note': Icons.note,
      'assignment': Icons.assignment,
    };
    return icons[iconName] ?? Icons.category;
  }
}
