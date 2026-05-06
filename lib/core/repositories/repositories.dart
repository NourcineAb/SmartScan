/// Core repository interfaces
/// 
/// This barrel file exports all abstract repository contracts.
/// Concrete implementations in each feature should extend these interfaces.
/// 
/// Usage:
/// ```dart
/// import 'package:smart_scan/core/repositories/repositories.dart';
/// 
/// class ScanRepository implements IScanRepository {
///   // implementation
/// }
/// ```

export 'base_repository.dart';
export 'i_scan_repository.dart';
export 'i_category_repository.dart';
export 'i_export_repository.dart';
export 'i_translation_repository.dart';
export 'i_history_repository.dart';
