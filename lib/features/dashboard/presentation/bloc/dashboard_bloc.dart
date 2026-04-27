import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/core/services/file_storage_service.dart';
import 'package:smart_scan/features/categorization/data/repositories/category_repository.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
import 'package:smart_scan/shared/models/scan_model.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ScanRepository scanRepository;
  final CategoryRepository categoryRepository;
  final FileStorageService fileStorageService = FileStorageService();

  DashboardBloc({
    required this.scanRepository,
    required this.categoryRepository,
  }) : super(const DashboardInitial()) {
    on<LoadDashboardStatsEvent>(_onLoadDashboardStats);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
    on<UpdateStorageInfoEvent>(_onUpdateStorageInfo);
    on<GetScanStatsEvent>(_onGetScanStats);
    on<ClearDashboardCacheEvent>(_onClearDashboardCache);
  }

  /// Handle loading dashboard statistics
  Future<void> _onLoadDashboardStats(
    LoadDashboardStatsEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(const DashboardLoading());
      final stats = await _calculateDashboardStats();
      emit(DashboardLoaded(stats: stats));
    } catch (e) {
      emit(DashboardError(message: 'Error loading dashboard stats: $e'));
    }
  }

  /// Handle refreshing dashboard
  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(const DashboardLoading());
      final stats = await _calculateDashboardStats();
      emit(DashboardLoaded(stats: stats));
    } catch (e) {
      emit(DashboardError(message: 'Error refreshing dashboard: $e'));
    }
  }

  /// Handle updating storage info
  Future<void> _onUpdateStorageInfo(
    UpdateStorageInfoEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      if (state is DashboardLoaded) {
        final updatedStats = await _calculateDashboardStats();
        emit(DashboardLoaded(stats: updatedStats));
      }
    } catch (e) {
      emit(DashboardError(message: 'Error updating storage info: $e'));
    }
  }

  /// Handle getting scan statistics
  Future<void> _onGetScanStats(
    GetScanStatsEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      if (state is! DashboardLoading) {
        final stats = await _calculateDashboardStats();
        emit(DashboardLoaded(stats: stats));
      }
    } catch (e) {
      emit(DashboardError(message: 'Error getting scan stats: $e'));
    }
  }

  /// Handle clearing dashboard cache
  Future<void> _onClearDashboardCache(
    ClearDashboardCacheEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(const DashboardCacheCleared());
      final stats = await _calculateDashboardStats();
      emit(DashboardLoaded(stats: stats));
    } catch (e) {
      emit(DashboardError(message: 'Error clearing cache: $e'));
    }
  }

  /// Calculate all dashboard statistics
  Future<DashboardStats> _calculateDashboardStats() async {
    try {
      // Get ALL scans for statistics calculation (unlimited)
      final allScans = await scanRepository.getAllScans(limit: 100000);

      // Get total categories
      final categories = await categoryRepository.getAllCategoriesAsync();

      // Calculate metrics
      final totalScans = allScans.length;
      final totalCategories = categories.length;

      // Get recent scans (last 5)
      final recentScans =
          allScans.length > 5 ? allScans.sublist(0, 5) : allScans;

      // Calculate language distribution
      final languageDistribution = _calculateLanguageDistribution(allScans);
      final totalLanguagesUsed = languageDistribution.keys.length;

      // Calculate category distribution
      final categoryDistribution = _calculateCategoryDistribution(allScans);

      // Calculate total storage used
      final totalStorage = fileStorageService.getTotalScansSize();
      final totalStorageUsed = _formatStorageSize(await totalStorage);

      return DashboardStats(
        totalScans: totalScans,
        totalCategories: totalCategories,
        totalLanguagesUsed: totalLanguagesUsed,
        totalStorageUsed: totalStorageUsed,
        recentScans: recentScans,
        categoryDistribution: categoryDistribution,
        languageDistribution: languageDistribution,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error calculating dashboard stats: $e');
    }
  }

  /// Calculate language distribution from scans
  Map<String, int> _calculateLanguageDistribution(List<ScanModel> scans) {
    final distribution = <String, int>{};

    for (final scan in scans) {
      final lang = scan.detectedLanguage ?? 'Unknown';
      distribution[lang] = (distribution[lang] ?? 0) + 1;
    }

    return distribution;
  }

  /// Calculate category distribution from scans
  Map<String, int> _calculateCategoryDistribution(List<ScanModel> scans) {
    final distribution = <String, int>{};

    for (final scan in scans) {
      if (scan.categoryId != null) {
        final categoryId = scan.categoryId.toString();
        distribution[categoryId] = (distribution[categoryId] ?? 0) + 1;
      }
    }

    return distribution;
  }

  /// Format storage size in human-readable format
  String _formatStorageSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
