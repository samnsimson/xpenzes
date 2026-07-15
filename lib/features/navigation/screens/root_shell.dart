import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../expenses/screens/home_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../account/screens/account_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;

  static const _screens = [HomeScreen(), AnalyticsScreen(), AccountScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.pie_chart_outline_rounded,
              color: AppColors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.pie_chart_rounded,
              color: AppColors.primary,
            ),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
            ),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
