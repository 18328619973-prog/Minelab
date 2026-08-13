import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/experiments/experiments_screen.dart';

class MineLabApp extends StatefulWidget {
  const MineLabApp({super.key, required this.store});
  final LocalStore store;
  @override
  State<MineLabApp> createState() => _MineLabAppState();
}

class _MineLabAppState extends State<MineLabApp> {
  int index = 0;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MineLab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF789A91),
                surface: const Color(0xFFF8F8F5)),
            scaffoldBackgroundColor: const Color(0xFFF8F8F5),
            useMaterial3: true,
            cardTheme: const CardThemeData(elevation: 0, color: Colors.white)),
        home: Scaffold(
          body: IndexedStack(index: index, children: [
            DashboardScreen(store: widget.store),
            ExperimentsScreen(store: widget.store),
            const _Placeholder(title: '计算', icon: Icons.calculate),
            const _Placeholder(title: '样本', icon: Icons.ac_unit),
            const _Placeholder(title: '我的', icon: Icons.person)
          ]),
          bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (v) => setState(() => index = v),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.today_outlined),
                    selectedIcon: Icon(Icons.today),
                    label: '今日'),
                NavigationDestination(
                    icon: Icon(Icons.science_outlined),
                    selectedIcon: Icon(Icons.science),
                    label: '实验'),
                NavigationDestination(
                    icon: Icon(Icons.calculate_outlined),
                    selectedIcon: Icon(Icons.calculate),
                    label: '计算'),
                NavigationDestination(
                    icon: Icon(Icons.ac_unit_outlined),
                    selectedIcon: Icon(Icons.ac_unit),
                    label: '样本'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: '我的')
              ]),
        ),
      );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SafeArea(
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Icon(icon, size: 54),
            const SizedBox(height: 12),
            Text('$title · 后续阶段')
          ])));
}
