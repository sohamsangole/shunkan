import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating Glass Capsule / Dock navigation bar.
/// Detached from screen edges with frosted glass blur,
/// animated active pill, and matcha green accents.
class FloatingGlassDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingGlassDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF8ECE64);
    const unselectedColor = Color(0xFF71717A);

    const items = [
      _DockItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: '家',
      ),
      _DockItemData(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: '今日',
      ),
      _DockItemData(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: '設定',
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF141715).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: const Color(0xFF2E352F).withValues(alpha: 0.65),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              final item = items[index];

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(index);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1F3523).withValues(alpha: 0.9)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: isSelected
                        ? Border.all(
                            color: accentGreen.withValues(alpha: 0.4),
                            width: 1.0,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? accentGreen : unselectedColor,
                        size: 21,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: isSelected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 7.0),
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: accentGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DockItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _DockItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
