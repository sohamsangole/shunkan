import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jlpt_level.dart';
import '../state/app_state.dart';

/// Minimalist zen Settings screen matching the Shunkan mockup.
/// Divided into 学習 (Learning) and その他 (Other).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static void showLevelPicker(BuildContext context) {
    final appState = context.read<AppState>();
    final currentLevel = appState.currentLevel ?? JLPTLevel.n4;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131514),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF222624)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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
                const Text(
                  '学習レベルを選択',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...JLPTLevel.values.map((level) {
                  final isSelected = level == currentLevel;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1F2A20) : const Color(0xFF0F100F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF8ECE64) : const Color(0xFF222624),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      title: Text(
                        '${level.code} — ${level.japaneseRank}',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF8ECE64) : Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        level.rankTitle,
                        style: const TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 13,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF8ECE64), size: 22)
                          : null,
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await appState.updateLevel(level);
                      },
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131514),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF222624)),
        ),
        title: const Row(
          children: [
            Text(
              '春 ',
              style: TextStyle(color: Color(0xFF8ECE64), fontSize: 24, fontFamily: 'serif'),
            ),
            Text(
              'Shunkan',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Made for the moments in between.',
              style: TextStyle(color: Color(0xFF8ECE64), fontSize: 14, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 12),
            Text(
              'Shunkan (瞬間) helps you master Japanese Kanji naturally by presenting a single character each time you glance at your device.\n\nPassive, effortless, and zen.',
              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる', style: TextStyle(color: Color(0xFF8ECE64))),
          ),
        ],
      ),
    );
  }

  void _showOpenSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131514),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF222624)),
        ),
        title: const Text(
          'オープンソース',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shunkan is free and open source software.\nBuilt with Flutter & Dart.',
              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる', style: TextStyle(color: Color(0xFF8ECE64))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentLevel = appState.currentLevel ?? JLPTLevel.n4;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: 設定
              const SizedBox(height: 8),
              const Text(
                '設定',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),

              // Section 1: 学習 (Learning)
              const Text(
                '学習',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Card 1: 学習レベル
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131514),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222624)),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => showLevelPicker(context),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            color: Color(0xFF8ECE64),
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '学習レベル',
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentLevel.japaneseDisplayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
              ),

              const SizedBox(height: 12),

              // Card 2: ロック画面での学習
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF131514),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222624)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.smartphone_outlined,
                      color: Color(0xFF8ECE64),
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ロック画面での学習',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ロック画面を見るたびに新しい漢字を表示します',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch.adaptive(
                      value: appState.settings.lockscreenRefreshEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF8ECE64),
                      inactiveThumbColor: const Color(0xFF71717A),
                      inactiveTrackColor: const Color(0xFF27272A),
                      onChanged: (val) => appState.toggleLockscreenRefresh(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Section 2: その他 (Other)
              const Text(
                'その他',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Other Grouped Container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131514),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222624)),
                ),
                child: Column(
                  children: [
                    // About Row
                    Material(
                      color: Colors.transparent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: InkWell(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        onTap: () => _showAboutDialog(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF8ECE64),
                                size: 24,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Shunkanについて',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Color(0xFF52525B),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Divider(
                      color: Color(0xFF222624),
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                    ),

                    // Open Source Row
                    Material(
                      color: Colors.transparent,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: InkWell(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        onTap: () => _showOpenSourceDialog(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite_border,
                                color: Color(0xFF8ECE64),
                                size: 24,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'オープンソース',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Color(0xFF52525B),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
