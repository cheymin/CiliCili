import 'package:flutter/material.dart';

import 'home_feed_screen.dart';
import 'search_screen.dart';
import 'live_screen.dart';
import 'bangumi_screen.dart';
import 'mine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // IndexedStack 保活，切页不丢状态
  final _pages = const <Widget>[
    HomeFeedScreen(),
    SearchScreen(),
    LiveScreen(),
    BangumiScreen(),
    MineScreen(),
  ];

  final _navItems = const [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '首页'),
    (icon: Icons.search_outlined, activeIcon: Icons.search, label: '搜索'),
    (icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv, label: '直播'),
    (icon: Icons.movie_outlined, activeIcon: Icons.movie, label: '番剧'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 宽屏（电视/横屏平板）用侧边 NavigationRail，窄屏（手机竖屏）用底部导航
    final isWide = MediaQuery.of(context).size.width >= 720;

    final body = IndexedStack(index: _currentIndex, children: _pages);

    if (isWide) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) =>
                  setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: cs.surface,
              destinations: _navItems
                  .map((e) => NavigationRailDestination(
                        icon: Icon(e.icon),
                        selectedIcon: Icon(e.activeIcon),
                        label: Text(e.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1, thickness: 0.5),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _navItems
            .map((e) => NavigationDestination(
                  icon: Icon(e.icon),
                  selectedIcon: Icon(e.activeIcon),
                  label: e.label,
                ))
            .toList(),
      ),
    );
  }
}
