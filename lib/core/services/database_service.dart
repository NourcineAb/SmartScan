import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import '../constants/app_constants.dart';

// Check if running on web
bool _isWeb() {
  try {
    return !Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isWindows &&
        !Platform.isLinux &&
        !Platform.isMacOS;
  } catch (e) {
    return true; // Assume web if Platform throws
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // In-memory storage for web platform
  static final Map<String, List<Map<String, dynamic>>> _webStorage = {
    AppConstants.tableScans: [],
    AppConstants.tableCategories: _getDefaultCategories(),
  };

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static List<Map<String, dynamic>> _getDefaultCategories() {
    return [
      {
        'id': '1',
        'name': 'Invoice',
        'color': 0xFFFF6B6B,
        'icon': 'receipt',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Ticket',
        'color': 0xFF4ECDC4,
        'icon': 'confirmation_number',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '3',
        'name': 'Document',
        'color': 0xFFFFE66D,
        'icon': 'description',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '4',
        'name': 'Label',
        'color': 0xFF95E1D3,
        'icon': 'label',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '5',
        'name': 'Other',
        'color': 0xFFC7CEEA,
        'icon': 'category',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  Future<Database> get database async {
    if (_isWeb()) {
      throw UnsupportedError('Database not supported on web platform');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create scans table with all new fields
    await db.execute('''
      CREATE TABLE ${AppConstants.tableScans} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        image_path TEXT,
        raw_text TEXT,
        translated_text TEXT,
        detected_language TEXT,
        target_language TEXT,
        category_id TEXT,
        entities_json TEXT,
        bounding_boxes_json TEXT,
        document_type TEXT,
        document_type_confidence REAL,
        reminder_suggestion TEXT,
        suggested_reminder_date TEXT,
        reminder_dismissed INTEGER DEFAULT 0,
        image_width INTEGER,
        image_height INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCategories} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color INTEGER,
        icon TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Create saved translations table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSavedTranslations} (
        id TEXT PRIMARY KEY,
        source_language TEXT NOT NULL,
        target_language TEXT NOT NULL,
        original_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create default categories
    await _createDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Upgrade from version 1 to 2: Add saved_translations table
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE ${AppConstants.tableSavedTranslations} (
          id TEXT PRIMARY KEY,
          source_language TEXT NOT NULL,
          target_language TEXT NOT NULL,
          original_text TEXT NOT NULL,
          translated_text TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    // Upgrade from version 2 to 3: Add new scan fields
    if (oldVersion < 3) {
      // Add bounding boxes column
      await db.execute('''
        ALTER TABLE ${AppConstants.tableScans}
        ADD COLUMN bounding_boxes_json TEXT
      ''');
      // Add document type columns
      await db.execute('''
        ALTER TABLE ${AppConstants.tableScans}
        ADD COLUMN document_type TEXT
      ''');
      await db.execute('''
        ALTER TABLE ${AppConstants.tableScans}
        ADD COLUMN document_type_confidence REAL
      ''');
      // Add reminder columns
      await db.execute('''
        ALTER TABLE ${AppConstants.tableScans}
        ADD COLUMN reminder_suggestion TEXT
      ''');
      await db.execute('''
        ALTER TABLE ${AppConstants.tableScans}
        ADD COLUMN suggested_reminder_date TEXT
      ''');
      await db.execute('''
        ALTER TABLE ${AppConstants.tableScans}
        ADD COLUMN reminder_dismissed INTEGER DEFAULT 0
      ''');
      // Add image dimensions columns
      await db.execute('''
        ALTER TABLE ${AppConstants.tableScans}
        ADD COLUMN image_width INTEGER
      ''');
      await db.execute('''
        ALTER TABLE ${AppConstants.tableScans}
        ADD COLUMN image_height INTEGER
      ''');
    }
  }

  Future<void> _createDefaultCategories(Database db) async {
    final defaultCategories = _getDefaultCategories();

    for (final category in defaultCategories) {
      await db.insert(
        AppConstants.tableCategories,
        category,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // Scan operations
  Future<String> insertScan(Map<String, dynamic> scan) async {
    if (_isWeb()) {
      _webStorage[AppConstants.tableScans]!.add(scan);
      return scan['id'];
    }
    final db = await database;
    await db.insert(
      AppConstants.tableScans,
      scan,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return scan['id'];
  }

  Future<Map<String, dynamic>?> getScan(String id) async {
    if (_isWeb()) {
      try {
        return _webStorage[AppConstants.tableScans]!
            .firstWhere((scan) => scan['id'] == id);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final results = await db.query(
      AppConstants.tableScans,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllScans({
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    if (_isWeb()) {
      final scans = _webStorage[AppConstants.tableScans]!;
      // Sort by created_at DESC
      scans.sort((a, b) => DateTime.parse(b['created_at'] as String)
          .compareTo(DateTime.parse(a['created_at'] as String)));
      return scans.skip(offset).take(limit).toList();
    }
    final db = await database;
    return db.query(
      AppConstants.tableScans,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getScansByCategory(
    String categoryId, {
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    if (_isWeb()) {
      final scans = _webStorage[AppConstants.tableScans]!
          .where((scan) => scan['category_id'] == categoryId)
          .toList();
      scans.sort((a, b) => DateTime.parse(b['created_at'] as String)
          .compareTo(DateTime.parse(a['created_at'] as String)));
      return scans.skip(offset).take(limit).toList();
    }
    final db = await database;
    return db.query(
      AppConstants.tableScans,
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> searchScans(
    String query, {
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    if (_isWeb()) {
      final queryLower = query.toLowerCase();
      final scans = _webStorage[AppConstants.tableScans]!.where((scan) {
        final titleMatch =
            (scan['title'] as String?)?.toLowerCase().contains(queryLower) ??
                false;
        final rawTextMatch =
            (scan['raw_text'] as String?)?.toLowerCase().contains(queryLower) ??
                false;
        final translatedTextMatch = (scan['translated_text'] as String?)
                ?.toLowerCase()
                .contains(queryLower) ??
            false;
        final languageMatch = (scan['detected_language'] as String?)
                ?.toLowerCase()
                .contains(queryLower) ??
            false;
        return titleMatch ||
            rawTextMatch ||
            translatedTextMatch ||
            languageMatch;
      }).toList();
      scans.sort((a, b) => DateTime.parse(b['created_at'] as String)
          .compareTo(DateTime.parse(a['created_at'] as String)));
      return scans.skip(offset).take(limit).toList();
    }
    final db = await database;
    return db.query(
      AppConstants.tableScans,
      where:
          'title LIKE ? OR raw_text LIKE ? OR translated_text LIKE ? OR detected_language LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<int> updateScan(String id, Map<String, dynamic> updates) async {
    if (_isWeb()) {
      final scans = _webStorage[AppConstants.tableScans]!;
      final index = scans.indexWhere((scan) => scan['id'] == id);
      if (index != -1) {
        updates['updated_at'] = DateTime.now().toIso8601String();
        scans[index] = {...scans[index], ...updates};
        return 1;
      }
      return 0;
    }
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    return db.update(
      AppConstants.tableScans,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteScan(String id) async {
    if (_isWeb()) {
      final scans = _webStorage[AppConstants.tableScans]!;
      scans.removeWhere((scan) => scan['id'] == id);
      return 1;
    }
    final db = await database;
    return db.delete(AppConstants.tableScans, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getScanCount() async {
    if (_isWeb()) {
      return _webStorage[AppConstants.tableScans]!.length;
    }
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableScans}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Saved Translations operations
  Future<String> insertSavedTranslation(
      Map<String, dynamic> translation) async {
    if (_isWeb()) {
      _webStorage.putIfAbsent(AppConstants.tableSavedTranslations, () => []);
      _webStorage[AppConstants.tableSavedTranslations]!.add(translation);
      return translation['id'];
    }
    final db = await database;
    await db.insert(
      AppConstants.tableSavedTranslations,
      translation,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return translation['id'];
  }

  Future<List<Map<String, dynamic>>> getAllSavedTranslations({
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    if (_isWeb()) {
      final translations =
          _webStorage[AppConstants.tableSavedTranslations] ?? [];
      translations.sort((a, b) => DateTime.parse(b['created_at'] as String)
          .compareTo(DateTime.parse(a['created_at'] as String)));
      return translations.skip(offset).take(limit).toList();
    }
    final db = await database;
    return db.query(
      AppConstants.tableSavedTranslations,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<int> deleteSavedTranslation(String id) async {
    if (_isWeb()) {
      final translations =
          _webStorage[AppConstants.tableSavedTranslations] ?? [];
      translations.removeWhere((trans) => trans['id'] == id);
      return 1;
    }
    final db = await database;
    return db.delete(
      AppConstants.tableSavedTranslations,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateSavedTranslation(String id, String newText) async {
    if (_isWeb()) {
      final translations =
          _webStorage[AppConstants.tableSavedTranslations] ?? [];
      final index = translations.indexWhere((trans) => trans['id'] == id);
      if (index != -1) {
        translations[index]['translated_text'] = newText;
        return 1;
      }
      return 0;
    }
    final db = await database;
    return db.update(
      AppConstants.tableSavedTranslations,
      {'translated_text': newText},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getSavedTranslationCount() async {
    if (_isWeb()) {
      return _webStorage[AppConstants.tableSavedTranslations]?.length ?? 0;
    }
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableSavedTranslations}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Category operations
  Future<String> insertCategory(Map<String, dynamic> category) async {
    if (_isWeb()) {
      _webStorage[AppConstants.tableCategories]!.add(category);
      return category['id'];
    }
    final db = await database;
    await db.insert(
      AppConstants.tableCategories,
      category,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return category['id'];
  }

  Future<Map<String, dynamic>?> getCategory(String id) async {
    if (_isWeb()) {
      try {
        return _webStorage[AppConstants.tableCategories]!
            .firstWhere((cat) => cat['id'] == id);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final results = await db.query(
      AppConstants.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    if (_isWeb()) {
      final cats = List<Map<String, dynamic>>.from(
          _webStorage[AppConstants.tableCategories]!);
      cats.sort((a, b) => DateTime.parse(a['created_at'] as String)
          .compareTo(DateTime.parse(b['created_at'] as String)));
      return cats;
    }
    final db = await database;
    return db.query(AppConstants.tableCategories, orderBy: 'created_at ASC');
  }

  Future<int> updateCategory(String id, Map<String, dynamic> updates) async {
    if (_isWeb()) {
      final cats = _webStorage[AppConstants.tableCategories]!;
      final index = cats.indexWhere((cat) => cat['id'] == id);
      if (index != -1) {
        cats[index] = {...cats[index], ...updates};
        return 1;
      }
      return 0;
    }
    final db = await database;
    final result = await db.update(
      AppConstants.tableCategories,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> deleteCategory(String id) async {
    if (_isWeb()) {
      int deleted = 0;
      // Check if category exists
      final cats = _webStorage[AppConstants.tableCategories]!;
      final index = cats.indexWhere((cat) => cat['id'] == id);
      if (index != -1) {
        cats.removeAt(index);
        deleted = 1;
      }
      // Also clear category from all scans
      for (final scan in _webStorage[AppConstants.tableScans]!) {
        if (scan['category_id'] == id) {
          scan['category_id'] = null;
        }
      }
      return deleted;
    }
    final db = await database;
    // Also clear category from all scans
    await db.update(
      AppConstants.tableScans,
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [id],
    );
    return db.delete(
      AppConstants.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllData() async {
    if (_isWeb()) {
      _webStorage[AppConstants.tableScans]!.clear();
      _webStorage[AppConstants.tableCategories]!.clear();
      _webStorage[AppConstants.tableCategories] = _getDefaultCategories();
      return;
    }
    final db = await database;
    await db.delete(AppConstants.tableScans);
    await db.delete(AppConstants.tableCategories);
    await _createDefaultCategories(db);
  }

  Future<void> close() async {
    if (_isWeb()) {
      // No-op for web
      return;
    }
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
