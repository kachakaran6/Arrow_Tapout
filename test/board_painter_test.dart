import 'package:arrowtapout/design/themes.dart';
import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:arrowtapout/features/game/board_view.dart';
import 'package:arrowtapout/features/game/thread_animator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardView and BoardPainter Widget Tests', () {
    testWidgets(
        'BoardView renders static layer with threads in Sage Linen theme',
        (tester) async {
      final level = Level(
        id: 1,
        rows: 4,
        cols: 4,
        threads: [
          Thread(1, [const Cell(1, 1), const Cell(1, 2)]),
          Thread(2, [const Cell(2, 1), const Cell(2, 2)]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.buildThemeData(AppThemes.sageLinenTokens,
              isDark: false),
          home: Scaffold(
            body: TestBoardContainer(level: level),
          ),
        ),
      );

      expect(find.byType(BoardView), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('BoardView renders properly in dark theme Ink and Brass',
        (tester) async {
      final level = Level(
        id: 2,
        rows: 5,
        cols: 5,
        threads: [
          Thread(1, [const Cell(0, 3), const Cell(1, 3), const Cell(2, 3)]),
          Thread(2, [const Cell(2, 0), const Cell(2, 1), const Cell(2, 2)]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.buildThemeData(AppThemes.inkAndBrassTokens,
              isDark: true),
          home: Scaffold(
            body: TestBoardContainer(level: level),
          ),
        ),
      );

      expect(find.byType(BoardView), findsOneWidget);
    });
  });
}

class TestBoardContainer extends StatefulWidget {
  const TestBoardContainer({super.key, required this.level});
  final Level level;

  @override
  State<TestBoardContainer> createState() => _TestBoardContainerState();
}

class _TestBoardContainerState extends State<TestBoardContainer>
    with SingleTickerProviderStateMixin {
  late BoardAnimator _animator;
  late Set<int> _activeIds;

  @override
  void initState() {
    super.initState();
    _activeIds = {for (final t in widget.level.threads) t.id};
    _animator = BoardAnimator(vsync: this);
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BoardView(
      level: widget.level,
      activeIds: _activeIds,
      animator: _animator,
      onThreadTap: (id) {},
    );
  }
}
