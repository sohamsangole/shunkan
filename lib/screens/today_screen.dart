import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kanji.dart';
import '../state/app_state.dart';
import 'pool_screen.dart';

/// Screen displaying today's Kanji list in the Shunkan zen card layout.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshTelemetry();
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
      context.read<AppState>().refreshTelemetry();
    }
  }

  String _formatJapaneseDate() {
    final now = DateTime.now();
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[now.weekday - 1];
    return '${now.month}月 ${now.day}日 ($weekday)';
  }

  String _getReading(Kanji kanji) {
    if (kanji.onyomiHiraganaDisplay.isNotEmpty && kanji.onyomiHiraganaDisplay != '-') {
      return kanji.onyomiHiraganaDisplay;
    }
    if (kanji.kunyomiDisplay.isNotEmpty && kanji.kunyomiDisplay != '-') {
      return kanji.kunyomiDisplay;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final kanjisToday = appState.kanjisViewedToday;
    
    // If no kanji viewed yet today, provide the initial daily batch from pool
    final displayList = kanjisToday.isNotEmpty
        ? kanjisToday
        : appState.currentEligiblePool.take(12).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Japanese Header: 今日 + Date
              const SizedBox(height: 8),
              const Text(
                '今日',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatJapaneseDate(),
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),

              // List of Kanji cards
              Expanded(
                child: displayList.isEmpty
                    ? const Center(
                        child: Text(
                          'まだ漢字がありません',
                          style: TextStyle(color: Color(0xFF71717A), fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayList.length,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 96),
                        itemBuilder: (context, index) {
                          final kanji = displayList[index];
                          final reading = _getReading(kanji);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131514),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF222624),
                                width: 1.0,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => PoolScreen.showKanjiDetail(context, kanji),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                    vertical: 16.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Large Kanji character
                                      SizedBox(
                                        width: 52,
                                        child: Text(
                                          kanji.character,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 38,
                                            fontFamily: 'serif',
                                            fontWeight: FontWeight.w400,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Meaning and Reading
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              kanji.primaryMeaning.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (reading.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                reading,
                                                style: const TextStyle(
                                                  color: Color(0xFF9E9E9E),
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Right chevron
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF52525B),
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
