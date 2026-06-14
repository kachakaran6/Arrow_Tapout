import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arrowtapout/design/colors.dart';
import 'package:arrowtapout/design/typography.dart';

/// Help overlay showing a quick demo of free vs blocked arrows
class HelpOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const HelpOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: GameColors.backgroundMid,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GameColors.buttonBorder, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How to Play', style: GameTypography.hudValue.copyWith(fontSize: 22)),
                const SizedBox(height: 20),
                _HelpRow(
                  color: const Color(0xFF78FFB8),
                  label: 'Tap arrows that have a clear path to the edge',
                  icon: Icons.arrow_forward_rounded,
                  isGlowing: true,
                ),
                const SizedBox(height: 16),
                _HelpRow(
                  color: const Color(0xFFFF6B6B),
                  label: 'Blocked arrows shake — clear the path first!',
                  icon: Icons.block_rounded,
                  isGlowing: false,
                ),
                const SizedBox(height: 16),
                _HelpRow(
                  color: GameColors.comboHighlight,
                  label: 'Chain removals to build a combo streak',
                  icon: Icons.bolt_rounded,
                  isGlowing: true,
                ),
                const SizedBox(height: 28),
                Text(
                  'Tap anywhere to dismiss',
                  style: GameTypography.levelSubtitle,
                ),
              ],
            ),
          ).animate().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            curve: Curves.easeOutBack,
            duration: 300.ms,
          ),
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  final bool isGlowing;

  const _HelpRow({
    required this.color,
    required this.label,
    required this.icon,
    required this.isGlowing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GameTypography.levelSubtitle,
          ),
        ),
      ],
    );
  }
}
