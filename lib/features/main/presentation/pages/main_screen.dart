import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:smart_scan/features/settings/presentation/bloc/settings_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return const Scaffold(
          body: DashboardScreen(),
        );
      },
    );
  }
}
