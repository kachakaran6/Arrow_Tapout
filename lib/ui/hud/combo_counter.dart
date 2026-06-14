import 'package:flutter/material.dart';
import 'package:arrowtapout/design/colors.dart';
import 'package:arrowtapout/design/typography.dart';

/// Animated combo counter HUD widget
class ComboCounter extends StatefulWidget {
  final int combo;
  const ComboCounter({super.key, required this.combo});

  @override
  State<ComboCounter> createState() => _ComboCounterState();
}

class _ComboCounterState extends State<ComboCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(ComboCounter old) {
    super.didUpdateWidget(old);
    if (widget.combo != old.combo && widget.combo > old.combo) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo < 2) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: GameColors.hudBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameColors.comboHighlight.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.comboHighlight.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '×${widget.combo}',
              style: GameTypography.comboMultiplier,
            ),
            const SizedBox(width: 6),
            Text(
              'COMBO',
              style: GameTypography.hudLabel.copyWith(
                color: GameColors.comboHighlight.withOpacity(0.8),
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
