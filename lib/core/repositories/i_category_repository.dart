import 'package:smart_scan/shared/models/category_model.dart';
import 'base_repository.dart';

/// Abstract repository for category operations
/// Implementations handle persistence of categories to database
abstract class ICategoryRepository extends BaseRepository {
  /// Get all categories
  Future<List<CategoryModel>> getAllCategoriesAsync();

  /// Get a category by ID
  Future<CategoryModel?> getCategoryByIdAsync(String id);

  /// Create a new category
  Future<String> createCategory(CategoryModel category);

  /// Update an existing category
  Future<bool> updateCategory(CategoryModel category);

  /// Delete a category
  Future<bool> deleteCategory(String categoryId);

  /// Search categories by name
  Future<List<CategoryModel>> searchCategories(String query);
}
