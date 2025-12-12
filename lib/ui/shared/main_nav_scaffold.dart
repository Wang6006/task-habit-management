import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Adaptive Navigation Scaffold
/// - Portrait: Bottom Navigation Bar
/// - Landscape: Navigation Rail (compact)
class MainNavScaffold extends StatelessWidget {
  final Widget child;

  const MainNavScaffold({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 600;

        if (isWideScreen) {
          return _buildWideLayout(context);
        } else {
          return _buildNarrowLayout(context);
        }
      },
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const _BottomNavBar());
  }

  Widget _buildWideLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _NavigationRailWidget(),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (currentRoute.startsWith('/habits')) {
      currentIndex = 1;
    } else if (currentRoute.startsWith('/settings')) {
      currentIndex = 2;
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        _navigateToIndex(context, index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.check_circle_outline),
          selectedIcon: Icon(Icons.check_circle),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Habits',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  void _navigateToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/tasks');
        break;
      case 1:
        context.go('/habits');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }
}

class _NavigationRailWidget extends StatelessWidget {
  const _NavigationRailWidget();

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (currentRoute.startsWith('/habits')) {
      currentIndex = 1;
    } else if (currentRoute.startsWith('/settings')) {
      currentIndex = 2;
    }

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        _navigateToIndex(context, index);
      },
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Image.asset(
          'assets/images/icon_splash.png',
          width: 64,
          height: 64,
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.check_circle_outline),
          selectedIcon: Icon(Icons.check_circle),
          label: Text('Tasks'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: Text('Habits'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  void _navigateToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/tasks');
        break;
      case 1:
        context.go('/habits');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }
}
