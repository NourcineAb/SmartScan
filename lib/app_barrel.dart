/// SmartScan - Barrel exports and feature shortcuts
/// 
/// This file provides convenient shortcuts for importing commonly used classes
/// from SmartScan without needing to know the exact file paths.
/// 
/// Examples:
/// ```dart
/// // Instead of:
/// import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
/// import 'package:smart_scan/features/scan/presentation/bloc/scan_bloc.dart';
/// 
/// // You can use:
/// import 'package:smart_scan/features/scan/scan.dart';
/// ```

// ============================================================================
// FEATURES - Complete feature exports
// ============================================================================

export 'features/main/main.dart';
export 'features/scan/scan.dart';
export 'features/ocr/ocr.dart';
export 'features/translation/translation.dart';
export 'features/categorization/categorization.dart';
export 'features/history/history.dart';
export 'features/export/export.dart';
export 'features/settings/settings.dart';
export 'features/dashboard/dashboard.dart';

// ============================================================================
// CORE - App-wide services and theme
// ============================================================================

export 'core/theme/theme.dart';
export 'core/services/services.dart';
export 'core/utils/utils.dart';
export 'core/constants/constants.dart';
export 'core/repositories/repositories.dart';

// ============================================================================
// SHARED - Common models and widgets
// ============================================================================

export 'shared/models/models.dart';
export 'shared/widgets/widgets.dart';

// ============================================================================
// LOCALIZATION
// ============================================================================

export 'l10n/gen_l10n/app_localizations.dart';
