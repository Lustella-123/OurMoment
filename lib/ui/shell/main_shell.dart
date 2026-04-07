import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../state/main_shell_controller.dart';
import '../screens/calendar_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/home_screen.dart';
import '../screens/memo_screen.dart';
import '../screens/settings_screen.dart';
import 'milestones_onboarding_layer.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _bodies = <Widget>[
    HomeScreen(),
    FeedScreen(),
    MemoScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tab = context.watch<MainShellController>().index;

    return MilestonesOnboardingLayer(
      child: Scaffold(
      body: IndexedStack(index: tab, children: _bodies),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) =>
            context.read<MainShellController>().setIndex(i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.dynamic_feed_outlined),
            selectedIcon: const Icon(Icons.dynamic_feed_rounded),
            label: l10n.navFeed,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist_rounded),
            label: l10n.navMemo,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.navSettings,
          ),
        ],
      ),
      ),
    );
  }
}
