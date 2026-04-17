part of 'dashboard_bloc.dart';

/// Model for dashboard statistics
class DashboardStats {
  final int totalScans;
  final int totalCategories;
  final int totalLanguagesUsed;
  final String totalStorageUsed;
  final List<ScanModel> recentScans;
  final Map<String, int> categoryDistribution;
  final Map<String, int> languageDistribution;
  final DateTime lastUpdated;

  const DashboardStats({
    required this.totalScans,
    required this.totalCategories,
    required this.totalLanguagesUsed,
    required this.totalStorageUsed,
    required this.recentScans,
    required this.categoryDistribution,
    required this.languageDistribution,
    required this.lastUpdated,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStats &&
          runtimeType == other.runtimeType &&
          totalScans == other.totalScans &&
          totalCategories == other.totalCategories &&
          totalLanguagesUsed == other.totalLanguagesUsed &&
          totalStorageUsed == other.totalStorageUsed &&
          recentScans == other.recentScans &&
          categoryDistribution == other.categoryDistribution &&
          languageDistribution == other.languageDistribution &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      totalScans.hashCode ^
      totalCategories.hashCode ^
      totalLanguagesUsed.hashCode ^
      totalStorageUsed.hashCode ^
      recentScans.hashCode ^
      categoryDistribution.hashCode ^
      languageDistribution.hashCode ^
      lastUpdated.hashCode;
}

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial dashboard state
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Loading dashboard data
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Dashboard stats loaded successfully
class DashboardLoaded extends DashboardState {
  final DashboardStats stats;

  const DashboardLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

/// Dashboard loading error
class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Dashboard cache cleared
class DashboardCacheCleared extends DashboardState {
  const DashboardCacheCleared();
}
