part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardStatsEvent extends DashboardEvent {
  const LoadDashboardStatsEvent();
}

class RefreshDashboardEvent extends DashboardEvent {
  const RefreshDashboardEvent();
}

class UpdateStorageInfoEvent extends DashboardEvent {
  const UpdateStorageInfoEvent();
}

class GetScanStatsEvent extends DashboardEvent {
  const GetScanStatsEvent();
}

class ClearDashboardCacheEvent extends DashboardEvent {
  const ClearDashboardCacheEvent();
}
