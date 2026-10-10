import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jlpt_level.dart';
import '../state/app_state.dart';

/// Zen-minimalist Home tab matching the Shunkan design mockup.
/// Features a realistic dark botanical photographic backdrop,
/// authentic brand emblem, tagline, and current JLPT level indicator.
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentLevel = appState.currentLevel ?? JLPTLevel.n4;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Realistic dark botanical photographic backdrop
          Positioned.fill(
            child: Image.asset(
              'assets/icons/home_backdrop.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Subtle gradient overlay to ensure perfect contrast in the center
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Authentic App Brand Logo (Transparent PNG)
                    Image.asset(
                      'assets/icons/shunkan_logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),

                    // App Title
                    const Text(
                      'Shunkan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    const Text(
                      'Made for the moments in between.',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 44),

                    // Elegant green accent divider
                    Container(
                      width: 36,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8ECE64),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 44),

                    // Learning Level Section (Display only)
                    Column(
                      children: [
                        const Text(
                          'YOUR LEARNING LEVEL',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          currentLevel.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontFamily: 'serif',
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentLevel.levelSubTitle,
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
