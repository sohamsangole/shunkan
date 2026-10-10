import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/jlpt_level.dart';
import '../models/kanji.dart';
import '../state/app_state.dart';

/// Pool tab displaying all Kanji from the active cumulative level in a minimal B&W layout.
class PoolScreen extends StatelessWidget {
  const PoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentLevel = appState.currentLevel;
    final pool = appState.currentEligiblePool;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching Today screen
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pool',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pool.length} Kanji active (${currentLevel?.code ?? ''})',
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: pool.isEmpty
                    ? const Center(
                        child: Text(
                          'No Kanji available in this pool.',
                          style: TextStyle(color: Color(0xFF71717A), fontSize: 14),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: pool.length,
                        itemBuilder: (context, index) {
                          final kanji = pool[index];
                          return _buildMinimalKanjiCard(context, kanji);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalKanjiCard(BuildContext context, Kanji kanji) {
    return GestureDetector(
      onTap: () => showKanjiDetail(context, kanji),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 8),
            // Meaning
            Text(
              kanji.primaryMeaning.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            // Readings (Hiragana only)
            Text(
              kanji.onyomiHiraganaDisplay,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFA1A1AA),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays detail modal for a Kanji entry with full readings, examples, and copy button.
  static Future<void> showKanjiDetail(BuildContext context, Kanji kanji) {
    const accentGreen = Color(0xFF8ECE64);
    const surfaceDark = Color(0xFF131514);
    const borderDark = Color(0xFF222624);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: borderDark),
      ),
      builder: (_) {
        bool copied = false;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            void copyAction() {
              Clipboard.setData(ClipboardData(text: kanji.character));
              HapticFeedback.lightImpact();
              setModalState(() {
                copied = true;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (modalContext.mounted) {
                  setModalState(() {
                    copied = false;
                  });
                }
              });
            }

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top drag pill
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F3F46),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kanji Character + Primary Meaning
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0F0E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderDark),
                          ),
                          child: Text(
                            kanji.character,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 54,
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w400,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kanji.primaryMeaning.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                kanji.meaningsDisplay,
                                style: const TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Copy Kanji Button with Green Accent
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 18,
                          color: copied ? Colors.black : accentGreen,
                        ),
                        label: Text(
                          copied ? 'Copied to Clipboard!' : 'Copy Kanji (${kanji.character})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: copied ? Colors.black : accentGreen,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: copied ? accentGreen : const Color(0xFF162519),
                          side: BorderSide(
                            color: copied ? accentGreen : accentGreen.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: copyAction,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: borderDark, height: 1),
                    const SizedBox(height: 16),

                    // ON Reading
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const SizedBox(
                          width: 52,
                          child: Text(
                            'ON',
                            style: TextStyle(
                              color: accentGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            kanji.onyomiHiraganaDisplay.isNotEmpty && kanji.onyomiHiraganaDisplay != '-'
                                ? kanji.onyomiHiraganaDisplay
                                : '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // KUN Reading
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const SizedBox(
                          width: 52,
                          child: Text(
                            'KUN',
                            style: TextStyle(
                              color: accentGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            kanji.kunyomiDisplay.isNotEmpty && kanji.kunyomiDisplay != '-'
                                ? kanji.kunyomiDisplay
                                : '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (kanji.examples.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'EXAMPLES',
                        style: TextStyle(
                          color: accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...kanji.examples.take(4).map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0, right: 8.0),
                                    child: Icon(
                                      Icons.circle,
                                      size: 5,
                                      color: accentGreen,
                                    ),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${e.word} ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '(${e.reading}) ',
                                            style: const TextStyle(
                                              color: Color(0xFF9E9E9E),
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '— ${e.meaning}',
                                            style: const TextStyle(
                                              color: Color(0xFFE4E4E7),
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
