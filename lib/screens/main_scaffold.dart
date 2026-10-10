import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kanji.dart';
import '../services/lockscreen_manager.dart';
import '../state/app_state.dart';
import 'home_screen.dart';
import 'pool_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

/// Main navigation scaffold providing 4 minimal tabs: Home, Today, Pool, and Settings.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _lastNavigatedKanjiId;
  DateTime? _lastNavigatedTime;
  bool _isModalOpen = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    TodayScreen(),
    PoolScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LockscreenManager.setKanjiOpenHandler(_navigateToKanji);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingKanji();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingKanji();
    }
  }

  Future<void> _checkPendingKanji() async {
    final kanjiId = await LockscreenManager.getPendingKanjiId();
    if (kanjiId != null && kanjiId.isNotEmpty) {
      _navigateToKanji(kanjiId);
    }
  }

  void _navigateToKanji(String kanjiId) {
    debugPrint('[MainScaffold] _navigateToKanji called with id: $kanjiId');
    if (!mounted) return;

    // Guard against duplicate invocations within 1.5 seconds for the same kanji
    final now = DateTime.now();
    if (_lastNavigatedKanjiId == kanjiId &&
        _lastNavigatedTime != null &&
        now.difference(_lastNavigatedTime!) < const Duration(milliseconds: 1500)) {
      debugPrint('[MainScaffold] Debouncing duplicate navigation for $kanjiId');
      return;
    }
    _lastNavigatedKanjiId = kanjiId;
    _lastNavigatedTime = now;

    final appState = context.read<AppState>();
    Kanji? target;
    try {
      target = appState.currentEligiblePool
          .firstWhere((k) => k.id == kanjiId || k.character == kanjiId);
    } catch (_) {
      try {
        target = appState.repository.getById(kanjiId) ??
            appState.repository.getAll().firstWhere((k) => k.character == kanjiId);
      } catch (_) {}
    }

    debugPrint('[MainScaffold] Found target: ${target?.character}');
    if (target != null && mounted) {
      setState(() {
        _currentIndex = 2; // Switch to Pool tab (now index 2)
      });
      // Show detail modal for this Kanji
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (_isModalOpen) {
          // If modal is already open, pop it before showing the new one
          Navigator.of(context, rootNavigator: true).pop();
        }
        _isModalOpen = true;
        try {
          debugPrint('[MainScaffold] Opening modal for ${target!.character}');
          await PoolScreen.showKanjiDetail(context, target!);
        } finally {
          _isModalOpen = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_screens.length, (index) {
          return TickerMode(
            enabled: index == _currentIndex,
            child: _screens[index],
          );
        }),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Color(0xFF27272A), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color(0xFF71717A),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_toggle_off),
              activeIcon: Icon(Icons.history),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.layers_outlined),
              activeIcon: Icon(Icons.layers),
              label: 'Pool',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
