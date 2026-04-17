part of 'settings_bloc.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String language;
  final bool soundsEnabled;
  final bool notificationsEnabled;

  const SettingsState({
    required this.themeMode,
    required this.language,
    required this.soundsEnabled,
    required this.notificationsEnabled,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? soundsEnabled,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
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
          notificationsEnabled == other.notificationsEnabled;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      language.hashCode ^
      soundsEnabled.hashCode ^
      notificationsEnabled.hashCode;
}
