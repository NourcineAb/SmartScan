import 'package:uuid/uuid.dart';
import 'package:smart_scan/core/services/database_service.dart';
import 'package:smart_scan/shared/models/category_model.dart';

/// Category repository backed by SQLite via [DatabaseService].
/// Categories are persisted to the database and survive app restarts.
class CategoryRepository {
  static final CategoryRepository _instance = CategoryRepository._internal();
  final DatabaseService _db = DatabaseService();

  factory CategoryRepository() => _instance;
  CategoryRepository._internal();

  /// Get all categories (async, from DB)
  Future<List<CategoryModel>> getAllCategoriesAsync() async {
    final maps = await _db.getAllCategories();
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  /// Synchronous version kept for backward compatibility.
  /// Returns an empty list; callers that need real data should use
  /// [getAllCategoriesAsync].
  List<CategoryModel> getAllCategories() => [];

  /// Get a single category by ID (async, from DB)
  Future<CategoryModel?> getCategoryByIdAsync(String id) async {
    final map = await _db.getCategory(id);
    if (map == null) return null;
    return CategoryModel.fromMap(map);
  }

  /// Synchronous version kept for backward compatibility — always returns null.
  CategoryModel? getCategoryById(String id) => null;

  /// Add a new category to the database
  Future<CategoryModel> addCategory({
    required String name,
    required String icon,
    required int color,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await _db.insertCategory({
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'created_at': now,
    });
    return CategoryModel(
      id: id,
      name: name,
      color: color,
      icon: icon,
      createdAt: DateTime.parse(now),
    );
  }

  /// Update an existing category in the database
  Future<CategoryModel?> updateCategory({
    required String id,
    required String name,
    required String icon,
    required int color,
  }) async {
    await _db.updateCategory(id, {
      'name': name,
      'icon': icon,
      'color': color,
    });
    final updated = await getCategoryByIdAsync(id);
    return updated;
  }

  /// Delete a category from the database
  Future<bool> deleteCategory(String id) async {
    final count = await _db.deleteCategory(id);
    return count > 0;
  }

  // ── Legacy in-memory document assignment (kept for compatibility) ──────────
  final Map<String, String> _categoryDocuments = {};

  void assignDocumentToCategory(String documentId, String categoryId) {
    _categoryDocuments[documentId] = categoryId;
  }

  List<String> getDocumentsForCategory(String categoryId) {
    return _categoryDocuments.entries
        .where((e) => e.value == categoryId)
        .map((e) => e.key)
        .toList();
  }

  int getDocumentCountForCategory(String categoryId) {
    return _categoryDocuments.values.where((c) => c == categoryId).length;
  }

  Future<int> getScanCountByCategoryAsync(String categoryId) async {
    return await _db.getScanCountByCategory(categoryId);
  }
}
