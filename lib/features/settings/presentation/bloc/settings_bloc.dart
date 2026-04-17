import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences prefs;

  SettingsBloc({required this.prefs})
      : super(
          SettingsState(
            themeMode: _getThemeModeFromPrefs(prefs),
            language: prefs.getString(AppConstants.prefLanguage) ??
                AppConstants.defaultLanguage,
            soundsEnabled: prefs.getBool(AppConstants.prefEnableSounds) ??
                AppConstants.defaultSoundEnabled,
            notificationsEnabled:
                prefs.getBool(AppConstants.prefEnableNotifications) ??
                    AppConstants.defaultNotificationsEnabled,
          ),
        ) {
    on<ChangeThemeModeEvent>(_onChangeThemeMode);
    on<ChangeLanguageEvent>(_onChangeLanguage);
    on<ToggleSoundsEvent>(_onToggleSounds);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
  }

  static ThemeMode _getThemeModeFromPrefs(SharedPreferences prefs) {
    final themeString = prefs.getString(AppConstants.prefThemeMode) ?? 'light';
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await prefs.setString(
      AppConstants.prefThemeMode,
      event.themeMode.toString().split('.').last,
    );
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onChangeLanguage(
    ChangeLanguageEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await prefs.setString(AppConstants.prefLanguage, event.language);
    emit(state.copyWith(language: event.language));
  }

  Future<void> _onToggleSounds(
    ToggleSoundsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await prefs.setBool(AppConstants.prefEnableSounds, event.enabled);
    emit(state.copyWith(soundsEnabled: event.enabled));
  }

  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await prefs.setBool(AppConstants.prefEnableNotifications, event.enabled);
    emit(state.copyWith(notificationsEnabled: event.enabled));
  }
}
