part of 'category_bloc.dart';

abstract class CategoryEvent {
  const CategoryEvent();
}

/// Load all categories from repository
class LoadCategoriesEvent extends CategoryEvent {
  const LoadCategoriesEvent();
}

/// Add a new category
class AddCategoryEvent extends CategoryEvent {
  final String name;
  final String icon;
  final int color;

  const AddCategoryEvent({
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Update an existing category
class UpdateCategoryEvent extends CategoryEvent {
  final String id;
  final String name;
  final String icon;
  final int color;

  const UpdateCategoryEvent({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Delete a category by ID
class DeleteCategoryEvent extends CategoryEvent {
  final String id;

  const DeleteCategoryEvent({required this.id});
}

/// Select a category
class SelectCategoryEvent extends CategoryEvent {
  final String categoryId;

  const SelectCategoryEvent({required this.categoryId});
}
