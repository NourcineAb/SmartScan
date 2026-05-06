import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/settings_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings_title ?? 'Settings'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildThemeSection(context, state),
                _buildLanguageSection(context, state),
                _buildAISection(context),
                _buildAccountSection(context),
                _buildFeaturesSection(context, state),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, SettingsState state) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSection(
      title: l10n?.settings_appearance ?? 'Appearance',
      icon: Icons.palette,
      children: [
        _SettingsCard(
          title: l10n?.settings_theme ?? 'Theme',
          subtitle: l10n?.settings_choose_theme ?? 'Choose display mode',
          child: Column(
            children: [
              _ThemeOption(
                label: l10n?.theme_light ?? 'Light',
                value: ThemeMode.light,
                groupValue: state.themeMode,
                onChanged: (themeMode) async {
                  await FeedbackService().onTap();
                  context.read<SettingsBloc>().add(
                        ChangeThemeModeEvent(themeMode),
                      );
                },
                icon: Icons.light_mode,
              ),
              _ThemeOption(
                label: l10n?.theme_dark ?? 'Dark',
                value: ThemeMode.dark,
                groupValue: state.themeMode,
                onChanged: (themeMode) async {
                  await FeedbackService().onTap();
                  context.read<SettingsBloc>().add(
                        ChangeThemeModeEvent(themeMode),
                      );
                },
                icon: Icons.dark_mode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context, SettingsState state) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSection(
      title: l10n?.language_settings ?? 'Language',
      icon: Icons.language,
      children: [
        _SettingsCard(
          title: l10n?.settings_app_language ?? 'Application Language',
          subtitle: l10n?.settings_select_language ?? 'Select your language',
          child: _LanguageDropdown(
            value: state.language,
            onChanged: (language) async {
              if (language != null) {
                await FeedbackService().onTap();
                context.read<SettingsBloc>().add(
                      ChangeLanguageEvent(language),
                    );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAISection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSection(
      title: l10n?.settings_generative_ai ?? 'Generative AI',
      icon: Icons.auto_awesome,
      children: [
        _SettingsCard(
          title: l10n?.settings_gemini_api_key ?? 'Gemini API Key',
          subtitle: l10n?.settings_gemini_desc ?? 'Enable smart parsing & data extraction',
          trailing: const Icon(Icons.chevron_right),
          child: InkWell(
            onTap: () async {
              await FeedbackService().onTap();
              final currentKey = await GeminiService().getApiKey();
              if (!context.mounted) return;
              
              final controller = TextEditingController(text: currentKey);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n?.settings_gemini_api_key ?? 'Gemini API Key'),
                  content: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: l10n?.settings_enter_gemini_key ?? 'Enter your Google Gemini API Key',
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await GeminiService().setApiKey(controller.text);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(l10n?.save ?? 'Save'),
                    ),
                  ],
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                l10n?.settings_configure_api_key ?? 'Configure API Key',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoggedIn = user != null;

        return _SettingsSection(
          title: l10n?.settings_account_sync ?? 'Account & Sync',
          icon: Icons.account_circle,
          children: [
            if (!isLoggedIn)
              _SettingsCard(
                title: l10n?.settings_sign_in ?? 'Sign In',
                subtitle: l10n?.settings_sign_in_desc ?? 'Sign in to sync your scans across devices',
                trailing: const Icon(Icons.login),
                child: InkWell(
                  onTap: () async {
                    await FeedbackService().onTap();
                    final userCredential = await AuthService().signInWithGoogle();
                    if (userCredential != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n?.settings_sign_in_success ?? 'Successfully signed in!')),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      l10n?.settings_continue_google ?? 'Continue with Google',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (isLoggedIn)
              _SettingsCard(
                title: user.displayName ?? l10n?.settings_account_sync ?? 'Account',
                subtitle: user.email ?? '',
                trailing: const Icon(Icons.logout),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        await FeedbackService().onTap();
                        await AuthService().signOut();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n?.settings_sign_out_success ?? 'Successfully signed out')),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          l10n?.settings_sign_out ?? 'Sign Out',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n?.settings_cloud_sync_label ?? 'Cloud Sync'),
                                Switch(
                                  value: CloudSyncService().cloudSyncEnabled,
                                  onChanged: (value) async {
                                    await FeedbackService().onTap();
                                    CloudSyncService().setCloudSyncEnabled(value);
                                    setState(() {});
                                    if (value) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n?.settings_sync_enabled_msg ?? 'Sync enabled')),
                                      );
                                      // Trigger initial sync
                                      final scans = await DatabaseService().getAllScans();
                                      CloudSyncService().syncAllScans(scans);
                                    }
                                  },
                                  activeThumbColor: AppColors.primary,
                                ),
                              ],
                            ),
                            ValueListenableBuilder<double?>(
                              valueListenable: CloudSyncService().syncProgress,
                              builder: (context, progress, child) {
                                if (progress == null) return const SizedBox.shrink();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                      child: Text(
                                        l10n?.syncing ?? 'Syncing...',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[200],
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturesSection(BuildContext context, SettingsState state) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSection(
      title: l10n?.settings_features ?? 'Features',
      icon: Icons.tune,
      children: [
        _SettingsCard(
          title: l10n?.settings_sounds ?? 'Sounds',
          subtitle: l10n?.settings_sound_effects ?? 'Sound effects for actions',
          trailing: Switch(
            value: state.soundsEnabled,
            onChanged: (value) async {
              await FeedbackService().onTap();
              context.read<SettingsBloc>().add(ToggleSoundsEvent(value));
            },
            activeThumbColor: AppColors.primary,
          ),
        ),
        _SettingsCard(
          title: l10n?.settings_vibration ?? 'Vibration',
          subtitle: l10n?.settings_vibration_desc ?? 'Haptic feedback for actions',
          trailing: Switch(
            value: state.vibrationEnabled,
            onChanged: (value) async {
              context.read<SettingsBloc>().add(ToggleVibrationEvent(value));
              await FeedbackService().onVibrationToggled(value);
            },
            activeThumbColor: AppColors.primary,
          ),
        ),
        _SettingsCard(
          title: l10n?.settings_notifications ?? 'Notifications',
          subtitle: l10n?.settings_app_reminders ?? 'Reminders to use the app',
          trailing: Switch(
            value: state.notificationsEnabled,
            onChanged: (value) async {
              await FeedbackService().onTap();
              context.read<SettingsBloc>().add(ToggleNotificationsEvent(value));
            },
            activeThumbColor: AppColors.primary,
          ),
        ),
        _SettingsCard(
          title: l10n?.settings_lock_orientation ?? 'Lock Orientation',
          subtitle: l10n?.settings_lock_orientation_desc ?? 'Keep app in portrait mode',
          trailing: StatefulBuilder(
            builder: (context, setState) {
              return FutureBuilder<bool>(
                future: Future.value(
                  state.soundsEnabled, // Use any boolean from state
                ).then((_) async {
                  final prefs = await _getOrientationLock();
                  return prefs;
                }),
                builder: (context, snapshot) {
                  final isLocked = snapshot.data ?? true;
                  return Switch(
                    value: isLocked,
                    onChanged: (value) async {
                      await FeedbackService().onTap();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('lock_orientation', value);

                      if (value) {
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
                      setState(() {});
                    },
                    activeThumbColor: AppColors.primary,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<bool> _getOrientationLock() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('lock_orientation') ?? true;
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? child;
  final Widget? trailing;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 16),
              child!,
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;
  final Function(ThemeMode) onChanged;
  final IconData icon;

  const _ThemeOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // ignore: deprecated_member_use
            Radio<ThemeMode>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              // ignore: deprecated_member_use
              onChanged: (theme) => onChanged(theme!),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 12),
            Icon(icon,
                color: isSelected ? AppColors.primary : AppColors.neutral500),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String value;
  final Function(String?) onChanged;

  const _LanguageDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      underline: const SizedBox(),
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Row(
            children: [
              Text('🇬🇧 ', style: TextStyle(fontSize: 18)),
              Text('English'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'fr',
          child: Row(
            children: [
              Text('🇫🇷 ', style: TextStyle(fontSize: 18)),
              Text('Français'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'ar',
          child: Row(
            children: [
              Text('🇸🇦 ', style: TextStyle(fontSize: 18)),
              Text('العربية'),
            ],
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
