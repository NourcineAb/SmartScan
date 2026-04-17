import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/shared/models/scan_model.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
import 'package:smart_scan/core/services/database_service.dart';

part 'scans_event.dart';
part 'scans_state.dart';

class ScansBloc extends Bloc<ScansEvent, ScansState> {
  final ScanRepository scanRepository;

  ScansBloc({required this.scanRepository}) : super(const ScansInitial()) {
    on<LoadScansEvent>(_onLoadScans);
    on<DeleteScanEvent>(_onDeleteScan);
    on<RefreshScansEvent>(_onRefreshScans);
    on<SearchScansEvent>(_onSearchScans);
    on<FilterScansByCategoryEvent>(_onFilterByCategory);
  }

  // Build category lookup maps from DatabaseService
  Future<Map<String, dynamic>> _loadCategoryMaps() async {
    final Map<String, String> names = {};
    final Map<String, int> colors = {};
    try {
      final cats = await DatabaseService().getAllCategories();
      for (final c in cats) {
        final id = c['id'] as String;
        names[id] = c['name'] as String? ?? '';
        colors[id] = c['color'] as int? ?? 0xFF9E9E9E;
      }
    } catch (_) {}
    return {'names': names, 'colors': colors};
  }

  Future<void> _onLoadScans(
    LoadScansEvent event,
    Emitter<ScansState> emit,
  ) async {
    try {
      emit(const ScansLoading());
      final scans = await scanRepository.getAllScans(limit: event.limit);
      final catMaps = await _loadCategoryMaps();
      if (scans.isEmpty) {
        emit(const ScansEmpty());
      } else {
        emit(ScansLoaded(
          scans: scans,
          categoryNames: catMaps['names'] as Map<String, String>,
          categoryColors: catMaps['colors'] as Map<String, int>,
        ));
      }
    } catch (e) {
      emit(ScansError(message: 'Error loading scans: $e'));
    }
  }

  Future<void> _onDeleteScan(
    DeleteScanEvent event,
    Emitter<ScansState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is ScansLoaded) {
        final updated =
            currentState.scans.where((s) => s.id != event.scanId).toList();
        if (updated.isEmpty) {
          emit(const ScansEmpty());
        } else {
          emit(ScansLoaded(
            scans: updated,
            categoryNames: currentState.categoryNames,
            categoryColors: currentState.categoryColors,
          ));
        }
      }
      await scanRepository.deleteScan(event.scanId);
    } catch (e) {
      emit(ScansError(message: 'Error deleting scan: $e'));
    }
  }

  Future<void> _onRefreshScans(
    RefreshScansEvent event,
    Emitter<ScansState> emit,
  ) async {
    try {
      emit(const ScansLoading());
      final scans = await scanRepository.getAllScans(limit: event.limit);
      final catMaps = await _loadCategoryMaps();
      if (scans.isEmpty) {
        emit(const ScansEmpty());
      } else {
        emit(ScansLoaded(
          scans: scans,
          categoryNames: catMaps['names'] as Map<String, String>,
          categoryColors: catMaps['colors'] as Map<String, int>,
        ));
      }
    } catch (e) {
      emit(ScansError(message: 'Error refreshing scans: $e'));
    }
  }

  Future<void> _onSearchScans(
    SearchScansEvent event,
    Emitter<ScansState> emit,
  ) async {
    try {
      emit(const ScansLoading());
      final results = await scanRepository.searchScans(
        event.query,
        limit: event.limit,
      );
      final catMaps = await _loadCategoryMaps();
      if (results.isEmpty) {
        emit(const ScansEmpty());
      } else {
        emit(ScansLoaded(
          scans: results,
          categoryNames: catMaps['names'] as Map<String, String>,
          categoryColors: catMaps['colors'] as Map<String, int>,
        ));
      }
    } catch (e) {
      emit(ScansError(message: 'Error searching scans: $e'));
    }
  }

  Future<void> _onFilterByCategory(
    FilterScansByCategoryEvent event,
    Emitter<ScansState> emit,
  ) async {
    try {
      emit(const ScansLoading());
      final scans = await scanRepository.getAllScans(limit: event.limit);
      final filtered =
          scans.where((s) => s.categoryId == event.categoryId).toList();
      final catMaps = await _loadCategoryMaps();
      if (filtered.isEmpty) {
        emit(const ScansEmpty());
      } else {
        emit(ScansLoaded(
          scans: filtered,
          categoryNames: catMaps['names'] as Map<String, String>,
          categoryColors: catMaps['colors'] as Map<String, int>,
        ));
      }
    } catch (e) {
      emit(ScansError(message: 'Error filtering scans: $e'));
    }
  }
}
