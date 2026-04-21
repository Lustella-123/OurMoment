import 'package:flutter/material.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../state/main_shell_controller.dart';
import '../screens/calendar_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import 'milestones_onboarding_layer.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _bodies = <Widget>[
    HomeScreen(),
    FeedScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tab = context.watch<MainShellController>().index;
    final labels = [
      l10n.navHomeScreen,
      l10n.navFeed,
      l10n.navCalendar,
      l10n.navSettings,
    ];

    return MilestonesOnboardingLayer(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: tab, children: _bodies),
        bottomNavigationBar: Material(
          color: Colors.white,
          child: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: List.generate(4, (i) {
                  final selected = tab == i;
                  return Expanded(
                    child: TextButton(
                      onPressed: () =>
                          context.read<MainShellController>().setIndex(i),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? Colors.black : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
