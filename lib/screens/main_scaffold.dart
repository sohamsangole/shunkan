import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kanji.dart';
import '../services/lockscreen_manager.dart';
import '../state/app_state.dart';
import '../widgets/floating_glass_dock.dart';
import '../widgets/kanji_detail_sheet.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

/// Main navigation scaffold providing a floating frosted glass dock
/// with 3 zen tabs: 家 (Home), 今日 (Today), and 設定 (Settings).
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
      final kanjiToOpen = target;
      setState(() {
        _currentIndex = 1; // Switch to Today tab
      });
      // Show detail modal for this Kanji
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (_isModalOpen) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _isModalOpen = true;
        try {
          debugPrint('[MainScaffold] Opening modal for ${kanjiToOpen.character}');
          await KanjiDetailSheet.show(context, kanjiToOpen);
        } finally {
          _isModalOpen = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Screens Stack
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: List.generate(_screens.length, (index) {
                return TickerMode(
                  enabled: index == _currentIndex,
                  child: _screens[index],
                );
              }),
            ),
          ),

          // Floating Glass Capsule Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 18,
            child: Center(
              child: FloatingGlassDock(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
