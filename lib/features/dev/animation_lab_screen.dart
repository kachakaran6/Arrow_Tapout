import 'package:arrowtapout/data/level_repository.dart';
import 'package:arrowtapout/design/app_tokens.dart';
import 'package:arrowtapout/design/component_tokens.dart';
import 'package:arrowtapout/design/primitives.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/features/game/board_view.dart';
import 'package:arrowtapout/features/game/thread_animator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dev-only animation lab screen for inspecting slide curves and frame steps.
class AnimationLabScreen extends ConsumerStatefulWidget {
  const AnimationLabScreen({super.key});

  @override
  ConsumerState<AnimationLabScreen> createState() => _AnimationLabScreenState();
}

class _AnimationLabScreenState extends ConsumerState<AnimationLabScreen>
    with SingleTickerProviderStateMixin {
  late BoardAnimator _animator;
  Level? _level;
  int _selectedLevelId = 1;
  double _speed = 1.0;
  Set<int> _activeIds = {};

  @override
  void initState() {
    super.initState();
    _animator = BoardAnimator(vsync: this);
    _loadLevel(_selectedLevelId);
  }

  Future<void> _loadLevel(int id) async {
    try {
      final level = await ref.read(levelRepositoryProvider).loadLevel(id);
      if (mounted) {
        setState(() {
          _level = level;
          _selectedLevelId = id;
          _activeIds = {for (final t in level.threads) t.id};
        });
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cellSize = ComponentTokens.computeLatticeCellSize(
          screenWidth: MediaQuery.sizeOf(context).width,
          boardRegionHeight: MediaQuery.sizeOf(context).height * 0.45,
          rows: level.rows,
          cols: level.cols,
          devicePixelRatio: dpr,
        );
        _animator.setLevel(level, cellSize);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text('Animation Lab', style: tokens.typography.title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tokens.ink),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Controls row: level picker & speed slider
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text('Level:', style: tokens.typography.label),
                  const SizedBox(width: 8.0),
                  DropdownButton<int>(
                    value: _selectedLevelId,
                    dropdownColor: tokens.surface,
                    items: [1, 5, 20, 60, 100, 120, 185, 200]
                        .map((id) => DropdownMenuItem(
                              value: id,
                              child: Text('$id', style: tokens.typography.body),
                            ))
                        .toList(),
                    onChanged: (id) {
                      if (id != null) _loadLevel(id);
                    },
                  ),
                  const Spacer(),
                  Text('Speed: ${(_speed * 100).toInt()}%',
                      style: tokens.typography.label),
                  SizedBox(
                    width: 120.0,
                    child: Slider(
                      value: _speed,
                      min: 0.05,
                      max: 1.0,
                      activeColor: tokens.accent,
                      onChanged: (v) => setState(() => _speed = v),
                    ),
                  ),
                ],
              ),
            ),

            // Live p(u) Curve Plot
            Container(
              height: 90.0,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(Primitives.radiusCard),
                border: Border.all(color: tokens.threadFaint),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 74.0),
                painter: _MotionPlotPainter(tokens: tokens),
              ),
            ),

            const SizedBox(height: 8.0),

            // Interactive Board
            Expanded(
              child: _level != null
                  ? BoardView(
                      level: _level!,
                      activeIds: _activeIds,
                      animator: _animator,
                      reduceMotion: false,
                      onThreadTap: (id) {
                        _animator.triggerExit(id, reduceMotion: false);
                        setState(() {
                          _activeIds.remove(id);
                        });
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            // Reset button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton(
                onPressed: () => _loadLevel(_selectedLevelId),
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: tokens.onAccent,
                  minimumSize: const Size(double.infinity, 44.0),
                ),
                child: const Text('Reset Level Board'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotionPlotPainter extends CustomPainter {
  _MotionPlotPainter({required this.tokens});
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = tokens.threadFaint
      ..strokeWidth = 1.0;

    final curvePaint = Paint()
      ..color = tokens.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw baseline
    final zeroY = size.height * 0.75;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), axisPaint);

    // Plot p(u)
    final path = Path();
    const d = 1.0;
    const a = 0.16;

    for (var i = 0; i <= 200; i++) {
      final u = i / 200.0;
      final val = calculateExitDisplacement(
        u: u,
        totalDistanceD: d,
        anticipationA: a,
      );
      final x = u * size.width;
      final y = zeroY - val * (size.height * 0.65);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(covariant _MotionPlotPainter old) => old.tokens != tokens;
}
