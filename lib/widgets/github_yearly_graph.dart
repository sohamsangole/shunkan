import 'package:flutter/material.dart';
import '../models/daily_activity.dart';

/// GitHub-style yearly contribution/activity heatmap for Kanji learning habits.
/// Displays 7 rows (days of week) across 52 weeks with monochrome luminance levels.
class GitHubYearlyKanjiGraph extends StatefulWidget {
  final Map<String, DailyActivity> activities;
  final int todayGlances;
  final int todayUniqueKanji;
  final int cyclesCompleted;

  const GitHubYearlyKanjiGraph({
    super.key,
    required this.activities,
    required this.todayGlances,
    this.todayUniqueKanji = 0,
    this.cyclesCompleted = 0,
  });

  @override
  State<GitHubYearlyKanjiGraph> createState() => _GitHubYearlyKanjiGraphState();
}

class _GitHubYearlyKanjiGraphState extends State<GitHubYearlyKanjiGraph> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll automatically to the right (most recent days) after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Color mapping based on unique Kanji encountered that day (Option B: Heavy Immersion)
  Color _getColorForUniqueKanji(int uniqueKanji) {
    if (uniqueKanji <= 0) return Colors.transparent;       // Inactive / hollow
    if (uniqueKanji <= 35) return const Color(0xFF27272A); // 1-35 unique Kanji
    if (uniqueKanji <= 75) return const Color(0xFF52525B); // 36-75 unique Kanji
    if (uniqueKanji <= 110) return const Color(0xFFA1A1AA); // 76-110 unique Kanji
    return Colors.white;                                   // 111+ unique Kanji
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 52 weeks trailing
    final startOfRange = now.subtract(const Duration(days: 52 * 7));
    final startMonday =
        startOfRange.subtract(Duration(days: startOfRange.weekday - 1));

    final totalWeeks = (now.difference(startMonday).inDays / 7).ceil() + 1;
    const cellSize = 11.0;
    const cellSpacing = 3.0;
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    // Compute month headers positioned at each month's starting week (GitHub-style)
    final totalWidth = totalWeeks * (cellSize + cellSpacing);
    final monthWidgets = <Widget>[];
    int lastPlacedWeek = -4;

    for (int w = 0; w < totalWeeks; w++) {
      final weekStart = startMonday.add(Duration(days: w * 7));
      final prevWeekStart = startMonday.add(Duration(days: (w - 1) * 7));
      final isNewMonth = (w == 0) ? true : (weekStart.month != prevWeekStart.month);

      if (isNewMonth) {
        // If week 0, skip if the next month begins within 2 weeks
        if (w == 0) {
          final nextMonthDate = startMonday.add(const Duration(days: 2 * 7));
          if (nextMonthDate.month != weekStart.month) {
            continue;
          }
        }

        // Avoid overlapping month labels (require at least 3 weeks / ~42px gap)
        if (w - lastPlacedWeek >= 3) {
          monthWidgets.add(
            Positioned(
              left: w * (cellSize + cellSpacing),
              top: 0,
              child: Text(
                monthNames[weekStart.month - 1],
                style: const TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          );
          lastPlacedWeek = w;
        }
      }
    }

    final cyclesCompletedText = widget.cyclesCompleted == 1
        ? '1 cycle completed in the past year'
        : '${widget.cyclesCompleted} cycles completed in the past year';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'UNIQUE KANJI',
              style: TextStyle(
                color: Color(0xFF71717A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            Flexible(
              child: Text(
                cyclesCompletedText,
                style: const TextStyle(
                  color: Color(0xFFA1A1AA),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Scrollable Grid of 52 weeks
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels row with precise coordinates matching GitHub
              SizedBox(
                height: 16,
                width: totalWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: monthWidgets,
                ),
              ),

              const SizedBox(height: 6),

              // 7 rows of days
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(totalWeeks, (w) {
                  return Padding(
                    padding: const EdgeInsets.only(right: cellSpacing),
                    child: Column(
                      children: List.generate(7, (d) {
                        final date = startMonday.add(Duration(days: w * 7 + d));
                        final isFuture = date.isAfter(now);
                        final isToday = date.year == now.year &&
                            date.month == now.month &&
                            date.day == now.day;

                        final dateKey =
                            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                        final uniqueKanji = isToday
                            ? widget.todayUniqueKanji
                            : (widget.activities[dateKey]?.uniqueKanji ?? 0);

                        if (isFuture) {
                          return const SizedBox(
                            width: cellSize,
                            height: cellSize + cellSpacing,
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: cellSpacing),
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            decoration: BoxDecoration(
                              color: _getColorForUniqueKanji(uniqueKanji),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: isToday
                                    ? Colors.white
                                    : (uniqueKanji <= 0
                                        ? const Color(0xFF1E1E22)
                                        : const Color(0xFF3F3F46)),
                                width: isToday ? 1.0 : 0.5,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Legend at bottom
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              '0',
              style: TextStyle(
                color: Color(0xFF71717A),
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            _buildLegendTile(Colors.transparent),
            _buildLegendTile(const Color(0xFF27272A)),
            _buildLegendTile(const Color(0xFF52525B)),
            _buildLegendTile(const Color(0xFFA1A1AA)),
            _buildLegendTile(Colors.white),
            const SizedBox(width: 5),
            const Text(
              '150+',
              style: TextStyle(
                color: Color(0xFF71717A),
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendTile(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
        border: Border.all(
          color: color == Colors.transparent
              ? const Color(0xFF27272A)
              : const Color(0xFF3F3F46),
          width: 0.5,
        ),
      ),
    );
  }
}
