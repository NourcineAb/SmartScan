part of 'settings_bloc.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String language;
  final bool soundsEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;

  const SettingsState({
    required this.themeMode,
    required this.language,
    required this.soundsEnabled,
    required this.vibrationEnabled,
    required this.notificationsEnabled,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? soundsEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          language == other.language &&
          soundsEnabled == other.soundsEnabled &&
          vibrationEnabled == other.vibrationEnabled &&
          notificationsEnabled == other.notificationsEnabled;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      language.hashCode ^
      soundsEnabled.hashCode ^
      vibrationEnabled.hashCode ^
      notificationsEnabled.hashCode;
}
