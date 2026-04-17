import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:smart_scan/features/history/presentation/pages/scans_screen.dart';
import 'package:smart_scan/features/translation/presentation/pages/translation_screen.dart';
import 'package:smart_scan/features/settings/presentation/pages/settings_screen.dart';
import 'package:smart_scan/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:smart_scan/l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _transitionController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    _transitionController.forward(from: 0.0);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: const [
              DashboardScreen(),
              ScansScreen(),
              TranslationScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabChanged,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard),
                label: l10n?.dashboard_title ?? 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history),
                label: l10n?.history_title ?? 'History',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.translate),
                label: l10n?.translation_settings ?? 'Translate',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: l10n?.settings_title ?? 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
