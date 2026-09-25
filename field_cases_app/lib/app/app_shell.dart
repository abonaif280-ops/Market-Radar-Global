import 'package:flutter/material.dart';

import '../features/cases/presentation/cases_list_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'routes.dart';

/// الهيكل الرئيسي: شريط تنقل سفلي + زر "حالة جديدة" في منطقة الإبهام.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _homeTab = 0;
  static const int _casesTab = 1;
  static const int _settingsTab = 2;

  int _currentTab = _homeTab;

  void _selectTab(int index) => setState(() => _currentTab = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          HomeScreen(onOpenCases: () => _selectTab(_casesTab)),
          const CasesListScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: _currentTab != _settingsTab
          ? FloatingActionButton.extended(
              onPressed: () => AppRoutes.openNewCase(context),
              icon: const Icon(Icons.add, size: 28),
              label: const Text('حالة جديدة'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'الحالات',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
