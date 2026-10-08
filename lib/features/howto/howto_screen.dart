import 'dart:async';

import 'package:arrowtapout/design/app_tokens.dart';
import 'package:arrowtapout/design/primitives.dart';
import 'package:arrowtapout/engine/board_state.dart';
import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:arrowtapout/features/game/board_painter.dart';
import 'package:arrowtapout/features/game/thread_animator.dart';
import 'package:arrowtapout/platform/haptics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen>
    with TickerProviderStateMixin {
  late BoardAnimator _animator1;
  late BoardAnimator _animator2;
  late BoardAnimator _animator3;

  late Level _level1;
  late Level _level2;
  late Level _level3;

  final Set<int> _active1 = {1};
  final Set<int> _active2 = {1, 2};
  final Set<int> _active3 = {1, 2};

  Timer? _loopTimer;

  @override
  void initState() {
    super.initState();
    _animator1 = BoardAnimator(vsync: this);
    _animator2 = BoardAnimator(vsync: this);
    _animator3 = BoardAnimator(vsync: this);

    _level1 = Level(
      id: 101,
      rows: 3,
      cols: 4,
      threads: [
        Thread(1, [const Cell(1, 1), const Cell(1, 2)]),
      ],
    );
    _animator1.setLevel(_level1, 20.0);

    _level2 = Level(
      id: 102,
      rows: 3,
      cols: 4,
      threads: [
        Thread(1, [const Cell(1, 0), const Cell(1, 1)]),
        Thread(2, [const Cell(0, 2), const Cell(1, 2), const Cell(2, 2)]),
      ],
    );
    _animator2.setLevel(_level2, 20.0);

    _level3 = Level(
      id: 103,
      rows: 3,
      cols: 4,
      threads: [
        Thread(1, [const Cell(0, 3), const Cell(1, 3), const Cell(2, 3)]),
        Thread(2, [const Cell(1, 0), const Cell(1, 1), const Cell(1, 2)]),
      ],
    );
    _animator3.setLevel(_level3, 20.0);

    _startDiagramLoops();
  }

  void _startDiagramLoops() {
    _loopTimer = Timer.periodic(const Duration(milliseconds: 2600), (timer) {
      if (!mounted) return;

      // Diagram 1: free exit
      _animator1.triggerExit(1, reduceMotion: false);
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _animator1.setLevel(_level1, 20.0);
          setState(() {});
        }
      });

      // Diagram 2: blocked bounce
      _animator2.triggerBlocked(
        threadId: 1,
        blocker: const Blocker(id: 2, distanceCells: 1, hitCell: Cell(1, 2)),
        cellSize: 20.0,
        reduceMotion: false,
      );

      // Diagram 3: clear in right order
      _animator3.triggerExit(1, reduceMotion: false);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _animator3.triggerExit(2, reduceMotion: false);
        }
      });
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          _animator3.setLevel(_level3, 20.0);
          setState(() {});
        }
      });

      setState(() {});
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _animator1.dispose();
    _animator2.dispose();
    _animator3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final haptics = ref.read(hapticsServiceProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text('How to play', style: tokens.typography.title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tokens.ink),
          tooltip: 'Back',
          onPressed: () {
            haptics.selection();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Primitives.space24),
          children: [
            _HowToStepCard(
              stepNumber: 1,
              title: 'Slide free threads',
              body:
                  'Tap a thread that has a clear, unobstructed path to slide it out of the board.',
              animator: _animator1,
              level: _level1,
              activeIds: _active1,
              tokens: tokens,
            ),
            const SizedBox(height: Primitives.space20),
            _HowToStepCard(
              stepNumber: 2,
              title: 'Blocked threads bounce',
              body:
                  'If another thread sits in the way, your thread will nudge forward and spring back.',
              animator: _animator2,
              level: _level2,
              activeIds: _active2,
              tokens: tokens,
            ),
            const SizedBox(height: Primitives.space20),
            _HowToStepCard(
              stepNumber: 3,
              title: 'Order matters',
              body:
                  'Pulling one thread opens space for the next. Unwind the entire board to complete the level.',
              animator: _animator3,
              level: _level3,
              activeIds: _active3,
              tokens: tokens,
            ),
          ],
        ),
      ),
    );
  }
}

class _HowToStepCard extends StatelessWidget {
  const _HowToStepCard({
    required this.stepNumber,
    required this.title,
    required this.body,
    required this.animator,
    required this.level,
    required this.activeIds,
    required this.tokens,
  });

  final int stepNumber;
  final String title;
  final String body;
  final BoardAnimator animator;
  final Level level;
  final Set<int> activeIds;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: tokens.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Primitives.radiusCard),
        side: BorderSide(color: tokens.threadFaint, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Primitives.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini animated board diagram
            Container(
              width: 88.0,
              height: 72.0,
              decoration: BoxDecoration(
                color: tokens.bg,
                borderRadius: BorderRadius.circular(Primitives.radiusChip),
              ),
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(60.0, 40.0),
                painter: BoardPainter(
                  level: level,
                  activeIds: activeIds,
                  cellSize: 20.0,
                  tokens: tokens,
                  animator: animator,
                  reduceMotion: false,
                ),
              ),
            ),
            const SizedBox(width: Primitives.space16),
            // Step text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$stepNumber. $title',
                    style: tokens.typography.heading.copyWith(fontSize: 16.0),
                  ),
                  const SizedBox(height: Primitives.space4),
                  Text(
                    body,
                    style: tokens.typography.caption.copyWith(
                      color: tokens.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
