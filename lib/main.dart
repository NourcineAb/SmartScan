import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'core/services/locale_service.dart';
import 'core/utils/vibration_manager.dart';
import 'core/utils/sound_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/main/presentation/pages/splash_screen.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'core/services/notification_service.dart';
import 'core/services/model_download_service.dart';
import 'core/services/lifecycle_service.dart';
import 'core/services/analytics_service.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/scan/data/repositories/scan_repository.dart';
import 'features/categorization/data/repositories/category_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/cloud_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: \$e');
  }

  // ── Image Cache Limits ────────────────────────────────────────────────────
  // Keep these conservative on budget devices. The ML Kit document scanner
  // is a RAM-heavy native activity; leaving too much headroom for Flutter's
  // image cache means there is less RAM available when the scanner launches.
  PaintingBinding.instance.imageCache.maximumSize = 20; // Lower limit for stable startup
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      15 * 1024 * 1024; // 15 MB (was 50 MB)

  // Initialize Lifecycle Service for global cleanup
  AppLifecycleService().initialize();

  final prefs = await SharedPreferences.getInstance();
  await CloudSyncService().initialize(prefs);

  // Set orientation based on preference (default: portrait locked)
  final isOrientationLocked = prefs.getBool('lock_orientation') ?? true;
  if (isOrientationLocked) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize analytics service
  await AnalyticsService().initialize();
  await AnalyticsService().logAppOpen();

  // Initialize haptic and sound managers
  await VibrationManager().initialize(prefs);
  await SoundManager().initialize(prefs);

  // Removed automatic model downloads at startup to conserve memory.
  // Models will be downloaded on demand in TranslationScreen.


  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SettingsBloc(prefs: prefs)),
        BlocProvider(
          create: (context) => DashboardBloc(
            scanRepository: ScanRepository(),
            categoryRepository: CategoryRepository(),
          )..add(const LoadDashboardStatsEvent()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final locale = LocaleService.getLocaleByCode(settingsState.language);
        final isRTL = LocaleService.isLocaleRTL(locale);

        return MaterialApp(
          title: 'SmartScan',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: LocaleService.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,

          // Theme based on settings
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsState.themeMode,

          // RTL support for Arabic
          builder: (context, child) {
            return Directionality(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },

          home: const SplashScreen(),
        );
      },
    );
  }
}