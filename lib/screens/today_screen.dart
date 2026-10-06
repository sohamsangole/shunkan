import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kanji.dart';
import '../state/app_state.dart';
import 'pool_screen.dart';

/// Screen displaying the Kanji encountered today.
/// Dedicated 100% to displaying Kanji viewed today with 2x enlarged cards.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

enum TodayFilter { all, repeated }

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  TodayFilter _selectedFilter = TodayFilter.all;

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

  String _formatDateToday() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  int _getGlanceCount(Kanji k, telemetry) {
    return telemetry.kanjiGlanceCountsToday[k.id] ??
        telemetry.kanjiGlanceCountsToday[k.character] ??
        1;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final kanjisToday = appState.kanjisViewedToday;
    final telemetry = appState.telemetry;

    final twiceKanjis = kanjisToday
        .where((k) => _getGlanceCount(k, telemetry) == 2)
        .toList();

    final displayedKanjis = _selectedFilter == TodayFilter.repeated
        ? twiceKanjis
        : kanjisToday;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateToday(),
                        style: const TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // Refresh button
                  IconButton(
                    onPressed: () => appState.refreshTelemetry(),
                    icon: const Icon(Icons.refresh, color: Color(0xFFA1A1AA), size: 22),
                    tooltip: 'Refresh Activity',
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Filter Pills Row
              if (kanjisToday.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Row(
                    children: [
                      _buildFilterPill(
                        label: 'ALL',
                        count: kanjisToday.length,
                        isSelected: _selectedFilter == TodayFilter.all,
                        onTap: () => setState(() => _selectedFilter = TodayFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        label: '2 GLANCES',
                        count: twiceKanjis.length,
                        isSelected: _selectedFilter == TodayFilter.repeated,
                        onTap: () => setState(() => _selectedFilter = TodayFilter.repeated),
                      ),
                    ],
                  ),
                ),

              // Direct Kanji Grid (or Empty State)
              Expanded(
                child: kanjisToday.isEmpty
                    ? _buildEmptyState(context, appState)
                    : (_selectedFilter == TodayFilter.repeated && twiceKanjis.isEmpty)
                        ? _buildNoRepeatsState()
                        : _buildKanjiGrid(context, appState, displayedKanjis, telemetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF121214),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF27272A),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFFA1A1AA),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE4E4E7) : const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFFA1A1AA),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRepeatsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF18181B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.repeat,
                color: Color(0xFF71717A),
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Kanji Viewed 2x Yet Today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'When a Kanji appears on your lock screen twice today, it will be gathered here for quick reinforcement.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA1A1AA),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF18181B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off,
                color: Color(0xFF71717A),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Kanji Viewed Yet Today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lock and unlock your phone or test a notification to encounter Kanji throughout the day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA1A1AA),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await appState.triggerTestNotification();
                await appState.refreshTelemetry();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF3F3F46)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.bolt, size: 18),
              label: const Text(
                'Trigger Test Lock Kanji',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanjiGrid(
    BuildContext context,
    AppState appState,
    List<Kanji> kanjisToday,
    telemetry,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: kanjisToday.length,
      itemBuilder: (context, index) {
        final kanji = kanjisToday[index];
        final glanceCount = telemetry.kanjiGlanceCountsToday[kanji.id] ??
            telemetry.kanjiGlanceCountsToday[kanji.character] ??
            1;

        return GestureDetector(
          onTap: () {
            appState.recordKanjiView(kanji.id);
            PoolScreen.showKanjiDetail(context, kanji);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF27272A), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Text(
                        '${glanceCount}x today',
                        style: const TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF52525B)),
                  ],
                ),
                // Character (Enlarged ~2x)
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        kanji.character,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Meaning
                Text(
                  kanji.primaryMeaning.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                // Reading
                Text(
                  kanji.onyomiHiraganaDisplay.isNotEmpty
                      ? kanji.onyomiHiraganaDisplay
                      : kanji.kunyomiDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
