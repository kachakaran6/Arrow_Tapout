import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrowtapout/game/arrow_tap_out_game.dart';
import 'package:arrowtapout/state/game_notifier.dart';
import 'package:arrowtapout/ui/hud/combo_counter.dart';
import 'package:arrowtapout/ui/hud/arrows_remaining.dart';
import 'package:arrowtapout/ui/overlay/level_complete_overlay.dart';
import 'package:arrowtapout/ui/overlay/help_overlay.dart';
import 'package:arrowtapout/design/colors.dart';
import 'package:arrowtapout/design/constants.dart';

/// Root game screen — overlays Flutter HUD on top of the Flame game
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late ArrowTapOutGame _game;
  bool _showHelp = false;
  bool _restartPending = false;
  int _restartTapMs = 0;

  @override
  void initState() {
    super.initState();
    _game = ArrowTapOutGame(ref: ref);
  }

  void _onRestartTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_restartPending && now - _restartTapMs < GameConstants.restartConfirmWindowMs) {
      // Second tap — actually restart
      ref.read(gameProvider.notifier).resetLevel();
      setState(() => _restartPending = false);
    } else {
      // First tap — enter pending state
      setState(() {
        _restartPending = true;
        _restartTapMs = now;
      });
      // Auto-cancel after window
      Future.delayed(
        Duration(milliseconds: GameConstants.restartConfirmWindowMs),
        () {
          if (mounted) setState(() => _restartPending = false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: GameColors.backgroundDark,
      body: Stack(
        children: [
          // Flame game layer
          GameWidget(
            game: _game,
            overlayBuilderMap: {
              'levelComplete': (context, game) => LevelCompleteOverlay(
                onRestart: () {
                  ref.read(gameProvider.notifier).resetLevel();
                },
              ),
            },
          ),

          // Top HUD bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GameConstants.hudPadding,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Combo counter
                  ComboCounter(combo: gameState.combo),

                  // Arrows remaining
                  ArrowsRemaining(
                    remaining: gameState.remaining,
                    total: gameState.arrows.length,
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GameConstants.hudPadding,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Restart button
                    _HudButton(
                      icon: _restartPending ? Icons.warning_amber_rounded : Icons.refresh_rounded,
                      color: _restartPending
                          ? const Color(0xFFFF6B6B)
                          : GameColors.textPrimary,
                      onTap: _onRestartTap,
                      tooltip: _restartPending ? 'Tap again to restart' : 'Restart',
                    ),

                    // Help button
                    _HudButton(
                      icon: Icons.help_outline_rounded,
                      color: GameColors.textPrimary,
                      onTap: () => setState(() => _showHelp = true),
                      tooltip: 'How to play',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Restart pending tooltip
          if (_restartPending)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'Tap again to restart',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: Color(0xFFFF6B6B),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

          // Help overlay
          if (_showHelp)
            HelpOverlay(
              onDismiss: () => setState(() => _showHelp = false),
            ),
        ],
      ),
    );
  }
}

/// A glass-style HUD button
class _HudButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _HudButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: GameColors.hudBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: GameColors.buttonBorder,
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
