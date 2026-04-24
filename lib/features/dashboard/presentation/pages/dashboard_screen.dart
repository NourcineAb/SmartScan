import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../../scan/presentation/pages/scan_screen.dart';
import '../../../settings/presentation/pages/settings_screen.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../categorization/presentation/pages/categories_screen.dart';
import '../../../translation/presentation/pages/translation_screen.dart';
import '../../../history/presentation/pages/scans_screen.dart';
import '../../../history/presentation/pages/history_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/page_transition_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/action_history_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../categorization/data/repositories/category_repository.dart';
import '../../../scan/data/repositories/scan_repository.dart';
import '../../../../core/services/feedback_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ActionHistoryRepository _historyRepository =
      ActionHistoryRepository();

  void _recordAction({
    required String actionName,
    required String actionLabel,
    required String description,
    required String icon,
  }) {
    _historyRepository.recordAction(
      actionName: actionName,
      actionLabel: actionLabel,
      description: description,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        scanRepository: ScanRepository(),
        categoryRepository: CategoryRepository(),
      )..add(const LoadDashboardStatsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SmartScan'),
          elevation: 0,
          actions: [
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                final isDarkMode = settingsState.themeMode == ThemeMode.dark;
                return IconButton(
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () async {
                    await FeedbackService().onTap();
                    final newThemeMode =
                        isDarkMode ? ThemeMode.light : ThemeMode.dark;
                    context
                        .read<SettingsBloc>()
                        .add(ChangeThemeModeEvent(newThemeMode));
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await FeedbackService().onTap();
                _recordAction(
                  actionName: 'settings',
                  actionLabel: 'Paramètres',
                  description: 'Accès aux paramètres de l\'application',
                  icon: 'settings',
                );
                Navigator.of(context).push(
                  PageTransitionUtils.sharedAxisTransition<void>(
                    context: context,
                    builder: (context) => const SettingsScreen(),
                    routeName: '/settings',
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildQuickActions(context),
                _buildStatisticsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isDarkMode = settingsState.themeMode == ThemeMode.dark;
        final startGradient =
            isDarkMode ? Color(0xFF3D3D5C) : Color(0xFFF0E7FF);
        final endGradient = isDarkMode ? Color(0xFF2D2D44) : Color(0xFFE8F0FE);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // Glassmorphic background with backdrop filter
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [startGradient, endGradient],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? AppColors.coral.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated Scan Icon
                    _buildAnimatedScanIcon(isDarkMode),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      'SmartScan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Color(0xFF1A1A2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Smart Document Scanning & OCR',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedScanIcon(bool isDarkMode) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [AppColors.coral, AppColors.coralLight]
                    : [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? AppColors.coral.withValues(alpha: 0.4)
                      : AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.document_scanner,
              size: 32,
              color: Colors.white,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {});
          }
        });
      },
    );
  }

  Widget _buildStatisticsSection() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        if (state is DashboardLoading) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildGlassmorphicLoadingCard(),
          );
        } else if (state is DashboardLoaded) {
          final stats = state.stats;
          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              final isDarkMode = settingsState.themeMode == ThemeMode.dark;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.home_statistics ?? 'Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildGlassmorphicStatCard(
                            icon: Icons.description,
                            label: l10n?.stats_scans ?? 'Scans',
                            value: stats.totalScans.toString(),
                            color: AppColors.primary,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 12),
                          _buildGlassmorphicStatCard(
                            icon: Icons.category,
                            label: l10n?.stats_categories ?? 'Categories',
                            value: stats.totalCategories.toString(),
                            color: AppColors.secondary,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 12),
                          _buildGlassmorphicStatCard(
                            icon: Icons.language,
                            label: l10n?.stats_languages ?? 'Languages',
                            value: stats.totalLanguagesUsed.toString(),
                            color: AppColors.accent,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 12),
                          _buildGlassmorphicStatCard(
                            icon: Icons.storage,
                            label: l10n?.stats_storage ?? 'Storage',
                            value: stats.totalStorageUsed,
                            color: Colors.orange,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else if (state is DashboardError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildErrorCard(state.message),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGlassmorphicStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      width: 160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: isDarkMode ? 0.2 : 0.15),
                  color.withValues(alpha: isDarkMode ? 0.1 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon with circular background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // Large Bold Value (DM Sans equivalent)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtle Label
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicLoadingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.1),
                Colors.blue.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading statistics...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.15),
                Colors.red.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1),
                blurRadius: 16,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final actions = [
      {
        'icon': Icons.camera_alt,
        'label': l10n?.action_new_scan ?? 'New Scan',
        'color': const Color(0xFFA7F3D0), // Mint
        'onTap': () async {
          await FeedbackService().onTap();
          _recordAction(
            actionName: 'scan',
            actionLabel: l10n?.action_new_scan ?? 'New Scan',
            description: 'Access to document scanner',
            icon: 'camera',
          );
          Navigator.of(context).push(
            PageTransitionUtils.sharedAxisTransition<void>(
              context: context,
              builder: (context) => const ScanScreen(),
              routeName: '/scan',
            ),
          );
        },
      },
      {
        'icon': Icons.translate,
        'label': l10n?.action_translation ?? 'Translation',
        'color': const Color(0xFFFECACA), // Warm Peach
        'onTap': () async {
          await FeedbackService().onTap();
          _recordAction(
            actionName: 'translate',
            actionLabel: l10n?.action_translation ?? 'Translation',
            description: 'Access multilingual translation',
            icon: 'translate',
          );
          Navigator.of(context).push(
            PageTransitionUtils.sharedAxisTransition<void>(
              context: context,
              builder: (context) => const TranslationScreen(),
              routeName: '/translation',
            ),
          );
        },
      },
      {
        'icon': Icons.category,
        'label': l10n?.action_categories ?? 'Categories',
        'color': const Color(0xFFE9D5FF), // Lavender
        'onTap': () async {
          await FeedbackService().onTap();
          _recordAction(
            actionName: 'categories',
            actionLabel: l10n?.action_categories ?? 'Categories',
            description: 'Manage document categories',
            icon: 'category',
          );
          Navigator.of(context).push(
            PageTransitionUtils.sharedAxisTransition<void>(
              context: context,
              builder: (context) => const CategoriesScreen(),
              routeName: '/categories',
            ),
          );
        },
      },
      {
        'icon': Icons.history,
        'label': l10n?.action_history ?? 'History',
        'color': const Color(0xFFC7D2FE), // Indigo
        'onTap': () async {
          await FeedbackService().onTap();
          _recordAction(
            actionName: 'history',
            actionLabel: l10n?.action_history ?? 'History',
            description: 'View scans and translations',
            icon: 'history',
          );
          Navigator.of(context).push(
            PageTransitionUtils.sharedAxisTransition<void>(
              context: context,
              builder: (context) => const HistoryScreen(),
              routeName: '/history',
            ),
          );
        },
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final isDarkMode = settingsState.themeMode == ThemeMode.dark;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.home_quick_actions ?? 'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: List.generate(
                  actions.length,
                  (index) => _buildGlassmorphicActionCard(
                    context: context,
                    icon: actions[index]['icon'] as IconData,
                    label: actions[index]['label'] as String,
                    color: actions[index]['color'] as Color,
                    onTap: actions[index]['onTap'] as VoidCallback,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassmorphicActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isDarkMode = settingsState.themeMode == ThemeMode.dark;

        return GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: isDarkMode ? 0.3 : 0.4),
                          color.withValues(alpha: isDarkMode ? 0.15 : 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: color.withValues(alpha: 0.08),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon Circle
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Label
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDarkMode ? Colors.white : Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
