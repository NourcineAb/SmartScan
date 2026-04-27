import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/shared/models/category_model.dart';
import 'package:smart_scan/features/categorization/data/repositories/category_repository.dart';
import 'package:smart_scan/core/services/feedback_service.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc({required this.categoryRepository})
      : super(const CategoryInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<AddCategoryEvent>(_onAddCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<SelectCategoryEvent>(_onSelectCategory);
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(const CategoryLoading());
      final categories = await categoryRepository.getAllCategoriesAsync();
      
      if (categories.isEmpty) {
        emit(const CategoryEmpty());
      } else {
        final counts = await _getCategoryCounts(categories);
        emit(CategoriesLoaded(categories: categories, documentCounts: counts));
      }
    } catch (e) {
      emit(CategoryError(message: 'Error loading categories: $e'));
    }
  }

  Future<Map<String, int>> _getCategoryCounts(List<CategoryModel> categories) async {
    final Map<String, int> counts = {};
    for (final category in categories) {
      counts[category.id] = await categoryRepository.getScanCountByCategoryAsync(category.id);
    }
    return counts;
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(const CategoryLoading());
      final newCategory = await categoryRepository.addCategory(
        name: event.name,
        icon: event.icon,
        color: event.color,
      );
      await FeedbackService().onSuccess();
      final updatedCategories =
          await categoryRepository.getAllCategoriesAsync();
      final counts = await _getCategoryCounts(updatedCategories);
      emit(CategoriesLoaded(categories: updatedCategories, documentCounts: counts));
      emit(CategoryAdded(category: newCategory));
    } catch (e) {
      await FeedbackService().onError();
      emit(CategoryError(message: 'Error adding category: $e'));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(const CategoryLoading());
      final updatedCategory = await categoryRepository.updateCategory(
        id: event.id,
        name: event.name,
        icon: event.icon,
        color: event.color,
      );
      if (updatedCategory != null) {
        await FeedbackService().onTap();
        await Future.delayed(const Duration(milliseconds: 100));
        await FeedbackService().onSuccess();
        final updatedCategories =
            await categoryRepository.getAllCategoriesAsync();
        final counts = await _getCategoryCounts(updatedCategories);
        emit(CategoriesLoaded(categories: updatedCategories, documentCounts: counts));
        emit(CategoryUpdated(category: updatedCategory));
      } else {
        await FeedbackService().onError();
        emit(const CategoryError(message: 'Category not found'));
      }
    } catch (e) {
      await FeedbackService().onError();
      emit(CategoryError(message: 'Error updating category: $e'));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final success = await categoryRepository.deleteCategory(event.id);
      if (success) {
        await FeedbackService().onDelete();
        await Future.delayed(const Duration(milliseconds: 100));
        await FeedbackService().onSuccess();
        // Just emit CategoryDeleted - let the listener reload
        emit(const CategoryDeleted());
      } else {
        await FeedbackService().onError();
        emit(const CategoryError(message: 'Could not delete category'));
      }
    } catch (e) {
      await FeedbackService().onError();
      emit(CategoryError(message: 'Error deleting category: $e'));
    }
  }

  Future<void> _onSelectCategory(
    SelectCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final category =
          await categoryRepository.getCategoryByIdAsync(event.categoryId);
      if (category != null) {
        emit(CategorySelected(category: category));
      } else {
        emit(const CategoryError(message: 'Category not found'));
      }
    } catch (e) {
      emit(CategoryError(message: 'Error selecting category: $e'));
    }
  }
}
