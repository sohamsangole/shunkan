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
  static void showKanjiDetail(BuildContext context, Kanji kanji) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF27272A)),
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          kanji.character,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                ),
                              ),
                              const SizedBox(height: 4),
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
                    const SizedBox(height: 16),
                    // Copy Kanji Button (Full Width)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 18,
                        ),
                        label: Text(
                          copied ? 'Copied to Clipboard!' : 'Copy Kanji (${kanji.character})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: copied ? Colors.black : Colors.white,
                          backgroundColor: copied ? Colors.white : Colors.transparent,
                          side: BorderSide(
                            color: copied ? Colors.white : const Color(0xFF27272A),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: copyAction,
                      ),
                    ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF27272A)),
                const SizedBox(height: 12),
                Text(
                  'ON:  ${kanji.onyomiHiraganaDisplay}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'KUN:  ${kanji.kunyomiDisplay}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (kanji.examples.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'EXAMPLES',
                    style: TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...kanji.examples.take(4).map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            '• ${e.word} (${e.reading}) — ${e.meaning}',
                            style: const TextStyle(
                              color: Color(0xFFE4E4E7),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                ],
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
