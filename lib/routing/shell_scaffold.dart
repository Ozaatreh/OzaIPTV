import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/tokens/colors.dart';
import 'route_names.dart';

/// Adaptive navigation shell that switches between:
/// - Bottom navigation on mobile
/// - Side navigation rail on desktop/wide screens
/// - Larger rail on Android TV
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    required this.state,
    required this.child,
    super.key,
  });

  final GoRouterState state;
  final Widget child;

  static const _destinations = [
    _NavItem(RouteNames.home, Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(RouteNames.liveTv, Icons.live_tv_outlined, Icons.live_tv_rounded, 'Live TV'),
    _NavItem(RouteNames.search, Icons.search_outlined, Icons.search_rounded, 'Search'),
    _NavItem(RouteNames.favorites, Icons.favorite_outline_rounded, Icons.favorite_rounded, 'Favorites'),
    _NavItem(RouteNames.settings, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  int _currentIndex(String location) {
    if (location.startsWith(RoutePaths.home)) return 0;
    if (location.startsWith(RoutePaths.liveTv)) return 1;
    if (location.startsWith(RoutePaths.search)) return 2;
    if (location.startsWith(RoutePaths.favorites)) return 3;
    if (location.startsWith(RoutePaths.settings)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    context.goNamed(_destinations[index].route);
  }

  bool get _isTV =>
      defaultTargetPlatform == TargetPlatform.android &&
      // Heuristic: will be refined with actual TV detection
      false;

  @override
  Widget build(BuildContext context) {
    final location = state.uri.toString();
    final selectedIndex = _currentIndex(location);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 800 || _isTV;

    if (useRail) {
      return _buildWithRail(context, selectedIndex, width >= 1200);
    }
    return _buildWithBottomNav(context, selectedIndex);
  }

  // ── Mobile: bottom navigation ────────────────────────────

  Widget _buildWithBottomNav(BuildContext context, int selectedIndex) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => _onTap(context, i),
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _destinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.activeIcon),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ── Desktop / TV: side navigation rail ───────────────────

  Widget _buildWithRail(
    BuildContext context,
    int selectedIndex,
    bool extended,
  ) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => _onTap(context, i),
            extended: extended,
            backgroundColor: AppColors.backgroundSecondary,
            indicatorColor: AppColors.accentGoldSubtle,
            selectedIconTheme:
                const IconThemeData(color: AppColors.accentGold),
            unselectedIconTheme:
                const IconThemeData(color: AppColors.textTertiary),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.accentGold,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
            leading: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: extended ? 16 : 0,
              ),
              child: extended
                  ? Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.live_tv_rounded,
                            color: AppColors.textOnAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'OzaIPTV',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.live_tv_rounded,
                        color: AppColors.textOnAccent,
                        size: 20,
                      ),
                    ),
            ),
            destinations: _destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.activeIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          Container(width: 0.5, color: AppColors.borderSubtle),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.icon, this.activeIcon, this.label);
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
