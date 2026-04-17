part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load dashboard statistics
class LoadDashboardStatsEvent extends DashboardEvent {
  const LoadDashboardStatsEvent();
}

/// Event to refresh dashboard data
class RefreshDashboardEvent extends DashboardEvent {
  const RefreshDashboardEvent();
}

/// Event to update storage info
class UpdateStorageInfoEvent extends DashboardEvent {
  const UpdateStorageInfoEvent();
}

/// Event to get scan statistics
class GetScanStatsEvent extends DashboardEvent {
  const GetScanStatsEvent();
}

/// Event to clear dashboard cache
class ClearDashboardCacheEvent extends DashboardEvent {
  const ClearDashboardCacheEvent();
}
