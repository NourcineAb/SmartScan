import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'core/services/locale_service.dart';
import 'core/utils/vibration_manager.dart';
import 'core/utils/sound_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/main/presentation/pages/main_screen.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

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

  // Initialize haptic and sound managers
  await VibrationManager().initialize(prefs);
  await SoundManager().initialize(prefs);

  runApp(
    BlocProvider(
      create: (context) => SettingsBloc(prefs: prefs),
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
        // Convertir le code de langue en Locale
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

          home: const MainScreen(),
        );
      },
    );
  }
}
