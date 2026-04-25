import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_scan/core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/l10n/app_localizations.dart';
import 'main_screen.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToMainScreen();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isDark = settingsState.themeMode == ThemeMode.dark ||
        (settingsState.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _goToMainScreen,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: isDark ? AppColors.coral : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPresentationPage(context, l10n, isDark),
                  _buildFeaturesPage(context, l10n, isDark),
                  _buildAboutPage(context, l10n, isDark),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? (isDark ? AppColors.coral : AppColors.primary)
                          : (isDark ? Colors.grey[600] : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l10n.previous),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black54,
                      ),
                    )
                  else
                    const SizedBox(width: 100),

                  // Next/Get Started button
                  ElevatedButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(_currentPage == 2 ? Icons.check : Icons.arrow_forward),
                    label: Text(
                      _currentPage == 2 ? l10n.welcome_get_started : l10n.next,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.coral : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresentationPage(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo/icon
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.coral, AppColors.coralLight]
                    : [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.coral : AppColors.primary).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner,
              size: 80,
              color: Colors.white,
            ),
          ).animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 400.ms),

          const SizedBox(height: 40),

          // Title
          Text(
            l10n.welcome_title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0, duration: 500.ms),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            l10n.welcome_subtitle,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(delay: 400.ms, duration: 500.ms),

          const SizedBox(height: 24),

          // Description
          Text(
            l10n.welcome_description,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(delay: 600.ms, duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(BuildContext context, AppLocalizations l10n, bool isDark) {
    final features = [
      (l10n.welcome_feature_ocr, Icons.text_fields, isDark ? Colors.blue : Colors.blue.shade700),
      (l10n.welcome_feature_entities, Icons.smart_toy, isDark ? Colors.green : Colors.green.shade700),
      (l10n.welcome_feature_types, Icons.category, isDark ? Colors.orange : Colors.orange.shade700),
      (l10n.welcome_feature_translation, Icons.translate, isDark ? Colors.purple : Colors.purple.shade700),
      (l10n.welcome_feature_reminders, Icons.notifications_active, isDark ? Colors.pink : Colors.pink.shade700),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            l10n.welcome_features_title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 30),

          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final (text, icon, color) = entry.value;
            return _buildFeatureItem(
              text,
              icon,
              color,
              isDark,
              delay: (index * 100).ms,
            );
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon, Color color, bool isDark, {required Duration delay}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: delay, duration: 400.ms)
      .slideX(begin: 0.2, end: 0, delay: delay, duration: 400.ms);
  }

  Widget _buildAboutPage(BuildContext context, AppLocalizations l10n, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              l10n.about_title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 8),

          Center(
            child: Text(
              l10n.about_version,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 32),

          _buildAboutSection(
            l10n.about_api_title,
            [
              (Icons.api, l10n.about_api_mlk, Colors.blue),
              (Icons.analytics, l10n.about_api_firebase, Colors.orange),
              ( Icons.document_scanner, l10n.about_api_ocr, Colors.green),
            ],
            isDark,
            delay: 200.ms,
          ),

          const SizedBox(height: 24),

          _buildAboutSection(
            l10n.about_privacy,
            [
              (Icons.security, l10n.about_privacy_desc, isDark ? AppColors.coral : AppColors.primary),
            ],
            isDark,
            delay: 400.ms,
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              l10n.about_copyright,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, List<(IconData, String, Color)> items, bool isDark, {required Duration delay}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ).animate().fadeIn(delay: delay, duration: 400.ms),

        const SizedBox(height: 12),

        ...items.map((item) {
          final (icon, text, color) = item;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(delay: delay + const Duration(milliseconds: 100), duration: 400.ms)
            .slideX(begin: 0.1, end: 0, delay: delay + const Duration(milliseconds: 100));
        }),
      ],
    );
  }
}
