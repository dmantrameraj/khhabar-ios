import 'package:flutter/material.dart';

import '../../widgets/banner_ad_widget.dart';
import '../auth/account_screen.dart';
import '../categories/categories_screen.dart';
import '../home/home_screen.dart';
import '../search/search_screen.dart';

/// Root bottom-navigation shell — Home / Categories / Search / Account.
/// Article and category-detail screens are pushed on top of whichever tab
/// is active, not part of the tab bar itself.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CategoriesScreen(),
    SearchScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      // A persistent banner sits above the nav bar rather than inside any
      // one tab, so it's a single ad slot for the whole app instead of
      // one per screen — the common, non-intrusive placement pattern.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'Categories',
              ),
              NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(Icons.account_circle),
                label: 'Account',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
