part of 'settings_bloc.dart';

abstract class SettingsEvent {
  const SettingsEvent();
}

class ChangeThemeModeEvent extends SettingsEvent {
  final ThemeMode themeMode;

  const ChangeThemeModeEvent(this.themeMode);
}

class ChangeLanguageEvent extends SettingsEvent {
  final String language;

  const ChangeLanguageEvent(this.language);
}

class ToggleSoundsEvent extends SettingsEvent {
  final bool enabled;

  const ToggleSoundsEvent(this.enabled);
}

class ToggleNotificationsEvent extends SettingsEvent {
  final bool enabled;

  const ToggleNotificationsEvent(this.enabled);
}
