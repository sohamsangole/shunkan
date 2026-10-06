import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/daily_activity.dart';

class _DayElement {
  final String kanji;
  final String englishShort;

  const _DayElement(this.kanji, this.englishShort);
}

class _WaterBoxData {
  final DateTime date;
  final _DayElement element;
  final bool isToday;
  final int uniqueKanji;
  final double coverageRatio;

  _WaterBoxData({
    required this.date,
    required this.element,
    required this.isToday,
    required this.uniqueKanji,
    required this.coverageRatio,
  });
}

/// Option B: Modern Minimal Micro-Cards for Rolling 7-Day Activity
/// - Sleek rounded micro-cards (BorderRadius.circular(8))
/// - Monochrome dark zinc surfaces matching Shunkan's core design language
/// - Today highlighted with crisp white border and subtle indicator
/// - Smooth, anti-aliased rising liquid level for daily coverage
/// - Refined spring tap interaction
class RollingWeekPixelMatrix extends StatefulWidget {
  final Map<String, DailyActivity> activities;
  final int todayGlances;
  final int todayUniqueKanji;
  final int windowSeenCount;
  final int poolSize;
  final int windowHours;
  final int windowStartMs;
  final int cyclesCompleted;

  const RollingWeekPixelMatrix({
    super.key,
    required this.activities,
    required this.todayGlances,
    required this.todayUniqueKanji,
    required this.windowSeenCount,
    required this.poolSize,
    required this.windowHours,
    required this.windowStartMs,
    this.cyclesCompleted = 0,
  });

  @override
  State<RollingWeekPixelMatrix> createState() => _RollingWeekPixelMatrixState();
}

class _RollingWeekPixelMatrixState extends State<RollingWeekPixelMatrix>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedDayIndex = 6; // Default to today (index 6 in 0..6)
  late AnimationController _waveController;
  late AnimationController _tapScaleController;

  static const _dayElements = {
    1: _DayElement('月', 'Mon'),
    2: _DayElement('火', 'Tue'),
    3: _DayElement('水', 'Wed'),
    4: _DayElement('木', 'Thu'),
    5: _DayElement('金', 'Fri'),
    6: _DayElement('土', 'Sat'),
    7: _DayElement('日', 'Sun'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Continuous subtle smooth wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _tapScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveController.dispose();
    _tapScaleController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted && !_waveController.isAnimating) {
        _waveController.repeat();
      }
    } else {
      if (_waveController.isAnimating) {
        _waveController.stop();
      }
    }
  }

  void _onDayTap(int index) {
    setState(() {
      _selectedDayIndex = index;
    });
    _tapScaleController.reverse().then((_) {
      if (mounted) _tapScaleController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Build rolling 7-day list (index 0 = 6 days ago, index 6 = today)
    final days = <_WaterBoxData>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final isToday = (i == 0);

      int uniqueKanji = 0;
      if (isToday) {
        uniqueKanji = widget.todayUniqueKanji;
      } else if (widget.activities.containsKey(dateKey)) {
        uniqueKanji = widget.activities[dateKey]!.uniqueKanji;
      }

      final ratio = widget.poolSize > 0
          ? (isToday
                  ? (widget.windowSeenCount / widget.poolSize)
                  : (uniqueKanji / widget.poolSize))
              .clamp(0.0, 1.0)
          : 0.0;

      final element = _dayElements[date.weekday] ??
          const _DayElement('日', 'Sun');

      days.add(
        _WaterBoxData(
          date: date,
          element: element,
          isToday: isToday,
          uniqueKanji: isToday ? widget.windowSeenCount : uniqueKanji,
          coverageRatio: ratio,
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, _) {
          final wavePhase = _waveController.value * 2 * math.pi;

          return Row(
            children: List.generate(days.length, (idx) {
              final d = days[idx];
              final isSelected = (_selectedDayIndex == idx);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: idx == 0 ? 0 : 2.5,
                    right: idx == days.length - 1 ? 0 : 2.5,
                  ),
                  child: GestureDetector(
                    onTap: () => _onDayTap(idx),
                    child: ScaleTransition(
                      scale: (isSelected && _tapScaleController.isAnimating)
                          ? _tapScaleController
                          : const AlwaysStoppedAnimation(1.0),
                      child: SizedBox(
                        height: 66,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF121214),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: d.isToday
                                  ? Colors.white
                                  : (isSelected
                                      ? const Color(0xFF52525B)
                                      : const Color(0xFF27272A)),
                              width: d.isToday ? 1.2 : 0.8,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7.0),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Smooth Liquid Fill
                                if (d.coverageRatio > 0 || (d.isToday && d.uniqueKanji > 0))
                                  RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _SmoothLiquidPainter(
                                        coverageRatio: d.coverageRatio,
                                        wavePhase: wavePhase + (idx * 0.7),
                                      ),
                                    ),
                                  ),

                              // Today indicator dot at top
                              if (d.isToday)
                                Positioned(
                                  top: 5,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      width: 3.5,
                                      height: 3.5,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),

                              // Center Day Kanji
                              Center(
                                child: Text(
                                  d.element.kanji,
                                  style: TextStyle(
                                    color: d.isToday
                                        ? Colors.white
                                        : (d.coverageRatio > 0 || d.uniqueKanji > 0
                                            ? const Color(0xFFE4E4E7)
                                            : const Color(0xFF52525B)),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    ),
  );
  }
}

/// Smooth, anti-aliased rising wave liquid painter for modern micro-cards
class _SmoothLiquidPainter extends CustomPainter {
  final double coverageRatio;
  final double wavePhase;

  _SmoothLiquidPainter({
    required this.coverageRatio,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final targetH = math.max(6.0, size.height * coverageRatio);
    final baseTop = size.height - targetH;

    final wavePath = Path();
    wavePath.moveTo(0, size.height);
    wavePath.lineTo(0, baseTop);

    // Smooth sinusoidal crest across width
    const steps = 24;
    for (int i = 0; i <= steps; i++) {
      final x = (size.width / steps) * i;
      final normX = i / steps;
      final waveOffset = math.sin(normX * 2 * math.pi + wavePhase) * 1.5;
      final y = (baseTop + waveOffset).clamp(0.0, size.height);
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    // Liquid body paint: refined translucent cyan ocean
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF0369A1).withValues(alpha: 0.45),
          const Color(0xFF0284C7).withValues(alpha: 0.25),
        ],
      ).createShader(Rect.fromLTWH(0, baseTop, size.width, targetH))
      ..style = PaintingStyle.fill;

    canvas.drawPath(wavePath, bodyPaint);

    // Crisp crest line
    final crestPath = Path();
    for (int i = 0; i <= steps; i++) {
      final x = (size.width / steps) * i;
      final normX = i / steps;
      final waveOffset = math.sin(normX * 2 * math.pi + wavePhase) * 1.5;
      final y = (baseTop + waveOffset).clamp(0.0, size.height);
      if (i == 0) {
        crestPath.moveTo(x, y);
      } else {
        crestPath.lineTo(x, y);
      }
    }

    final crestPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(crestPath, crestPaint);
  }

  @override
  bool shouldRepaint(covariant _SmoothLiquidPainter oldDelegate) {
    return oldDelegate.coverageRatio != coverageRatio ||
        oldDelegate.wavePhase != wavePhase;
  }
}
