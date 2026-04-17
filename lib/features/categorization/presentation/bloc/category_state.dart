part of 'category_bloc.dart';

abstract class CategoryState {
  const CategoryState();
}

/// Initial state - no categories loaded
class CategoryInitial extends CategoryState {
  const CategoryInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryInitial;

  @override
  int get hashCode => 0;
}

/// Loading categories
class CategoryLoading extends CategoryState {
  const CategoryLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryLoading;

  @override
  int get hashCode => 1;
}

/// Categories loaded successfully
class CategoriesLoaded extends CategoryState {
  final List<CategoryModel> categories;

  const CategoriesLoaded({required this.categories});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriesLoaded &&
          runtimeType == other.runtimeType &&
          categories == other.categories;

  @override
  int get hashCode => categories.hashCode;
}

/// No categories available
class CategoryEmpty extends CategoryState {
  const CategoryEmpty();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryEmpty;

  @override
  int get hashCode => 2;
}

/// Category added successfully
class CategoryAdded extends CategoryState {
  final CategoryModel category;

  const CategoryAdded({required this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdded &&
          runtimeType == other.runtimeType &&
          category == other.category;

  @override
  int get hashCode => category.hashCode;
}

/// Category updated successfully
class CategoryUpdated extends CategoryState {
  final CategoryModel category;

  const CategoryUpdated({required this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryUpdated &&
          runtimeType == other.runtimeType &&
          category == other.category;

  @override
  int get hashCode => category.hashCode;
}

/// Category deleted successfully
class CategoryDeleted extends CategoryState {
  const CategoryDeleted();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryDeleted;

  @override
  int get hashCode => 3;
}

/// Category selected
class CategorySelected extends CategoryState {
  final CategoryModel category;

  const CategorySelected({required this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySelected &&
          runtimeType == other.runtimeType &&
          category == other.category;

  @override
  int get hashCode => category.hashCode;
}

/// Error occurred
class CategoryError extends CategoryState {
  final String message;

  const CategoryError({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
