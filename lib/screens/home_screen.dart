import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jlpt_level.dart';
import '../state/app_state.dart';
import '../widgets/github_yearly_graph.dart';
import '../widgets/rolling_week_pixel_matrix.dart';

/// Minimalist Home tab in pure black and white.
/// Focused on passive habit telemetry, pool coverage, and immersion time.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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

  String _formatExposure(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds ~/ 60;
    final remainingSec = totalSeconds % 60;
    if (minutes < 60) {
      return remainingSec == 0 ? '${minutes}m' : '${minutes}m ${remainingSec}s';
    }
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    return remainingMin == 0 ? '${hours}h' : '${hours}h ${remainingMin}m';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentLevel = appState.currentLevel ?? JLPTLevel.n5;
    final telemetry = appState.telemetry;
    final pool = appState.currentEligiblePool;
    final windowHours = _getWindowHours(pool.length);
    final totalCycleDays = (windowHours / 24).ceil();
    final startMs = telemetry.windowStartMs > 0
        ? telemetry.windowStartMs
        : DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - startMs;
    final daysElapsed =
        elapsedMs > 0 ? (elapsedMs / (24 * 3600 * 1000)).floor() : 0;
    final currentCycleDay = (daysElapsed + 1).clamp(1, totalCycleDays);
    final unseenCount = pool.isNotEmpty
        ? (pool.length - telemetry.windowSeenCount).clamp(0, pool.length)
        : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Brand & App Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Shunkan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icons/shunkan_logo.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Current Level (Unboxed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT LEVEL',
                      style: TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentLevel.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 3),
                const Divider(color: Color(0xFF27272A), height: 1),
                const Spacer(flex: 3),

                // 0. CURRENT CYCLE: Live Window Telemetry (Option 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT CYCLE',
                      style: TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTelemetryMetric(
                              value: 'Day $currentCycleDay / $totalCycleDays',
                              label: 'CYCLE DAY',
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0xFF27272A),
                          ),
                          Expanded(
                            child: _buildTelemetryMetric(
                              value: '${telemetry.windowSeenCount} / ${pool.length}',
                              label: 'SEEN',
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0xFF27272A),
                          ),
                          Expanded(
                            child: _buildTelemetryMetric(
                              value: '$unseenCount',
                              label: 'UNSEEN',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 3),
                const Divider(color: Color(0xFF27272A), height: 1),
                const Spacer(flex: 3),

                // 1. TODAY: Today's Lock Activity (Unboxed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TODAY',
                      style: TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTelemetryMetric(
                              value: '${telemetry.glancesToday}',
                              label: 'GLANCES',
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0xFF27272A),
                          ),
                          Expanded(
                            child: _buildTelemetryMetric(
                              value: '${telemetry.uniqueKanjiToday}',
                              label: 'KANJI SEEN',
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0xFF27272A),
                          ),
                          Expanded(
                            child: _buildTelemetryMetric(
                              value: _formatExposure(telemetry.estimatedSecondsToday),
                              label: 'IMMERSION',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 3),
                const Divider(color: Color(0xFF27272A), height: 1),
                const Spacer(flex: 3),

                // 2. WEEK: Rolling 7-Day Modern Minimal Micro-Cards
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LAST 7 DAYS',
                      style: TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RollingWeekPixelMatrix(
                      activities: appState.dailyActivities,
                      todayGlances: telemetry.glancesToday,
                      todayUniqueKanji: telemetry.uniqueKanjiToday,
                      windowSeenCount: telemetry.windowSeenCount,
                      poolSize: pool.length,
                      windowHours: windowHours,
                      windowStartMs: telemetry.windowStartMs,
                      cyclesCompleted: telemetry.cyclesCompleted,
                    ),
                  ],
                ),

                const Spacer(flex: 3),
                const Divider(color: Color(0xFF27272A), height: 1),
                const Spacer(flex: 3),

                // 3. CYCLE & ACTIVITY: Normalized Heatmap
                GitHubYearlyKanjiGraph(
                  activities: appState.dailyActivities,
                  todayGlances: telemetry.glancesToday,
                  todayUniqueKanji: telemetry.uniqueKanjiToday,
                  cyclesCompleted: telemetry.cyclesCompleted,
                ),
              ],
            );

            // If the viewport has ample vertical space, lock to zero-scroll with Spacers.
            // If on an unusually constrained screen (< 520px), allow fallback scroll.
            if (constraints.maxHeight >= 520) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: content,
              );
            }

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: content,
            );
          },
        ),
      ),
    );
  }

  int _getWindowHours(int poolSize) {
    if (poolSize <= 150) return 24;
    if (poolSize <= 450) return 48;
    if (poolSize <= 850) return 96;
    if (poolSize <= 1500) return 168;
    return 336;
  }

  Widget _buildTelemetryMetric({
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF71717A),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
