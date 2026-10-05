import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jlpt_level.dart';
import '../services/lockscreen_manager.dart';
import '../state/app_state.dart';

/// Minimalist Home tab in pure black and white.
/// Focused on passive habit telemetry (glances, Kanji cycled, streak).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  TelemetryData _telemetry = const TelemetryData();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTelemetry();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTelemetry();
    }
  }

  Future<void> _loadTelemetry() async {
    final data = await LockscreenManager.getTelemetry();
    if (mounted) {
      setState(() => _telemetry = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentLevel = appState.currentLevel ?? JLPTLevel.n5;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // App Title & Brand Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shunkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Passive lock-screen Kanji',
                        style: TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icons/app_logo.png',
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Active Level Card (Minimalist B&W)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF27272A), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT LEVEL',
                      style: TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentLevel.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentLevel.displayName,
                      style: const TextStyle(
                        color: Color(0xFFE4E4E7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Passive Habit Telemetry Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF27272A), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TODAY\'S LOCK ACTIVITY',
                      style: TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTelemetryMetric(
                            value: '${_telemetry.glancesToday}',
                            label: 'Glances',
                            sublabel: 'Screen locks',
                          ),
                        ),
                        Container(width: 1, height: 42, color: const Color(0xFF27272A)),
                        Expanded(
                          child: _buildTelemetryMetric(
                            value: '${_telemetry.uniqueKanjiToday}',
                            label: 'Kanji Seen',
                            sublabel: 'Unique chars',
                          ),
                        ),
                        Container(width: 1, height: 42, color: const Color(0xFF27272A)),
                        Expanded(
                          child: _buildTelemetryMetric(
                            value: '${_telemetry.streakDays}d',
                            label: 'Habit Streak',
                            sublabel: 'Days active',
                          ),
                        ),
                      ],
                    ),
                    if (_telemetry.lastKanji.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF1F1F23)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'LAST ON LOCK: ',
                            style: TextStyle(
                              color: Color(0xFF71717A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${_telemetry.lastKanji}  (${_telemetry.lastMeaning})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Lock Screen Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF27272A), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0x14FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active on Lock Screen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'New Kanji preloads seamlessly each time you lock your phone.',
                            style: TextStyle(
                              color: Color(0xFFA1A1AA),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryMetric({
    required String value,
    required String label,
    required String sublabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE4E4E7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: const TextStyle(
            color: Color(0xFF71717A),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
