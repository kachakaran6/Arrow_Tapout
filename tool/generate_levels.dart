import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/dir.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/solver.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:arrowtapout/engine/validity.dart';

import 'shapes.dart';

int fnv1a(String input) {
  var hash = 0x811c9dc5;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

class ChapterSpec {
  const ChapterSpec({
    required this.number,
    required this.name,
    required this.startRows,
    required this.startCols,
    required this.endRows,
    required this.endCols,
    required this.minLen,
    required this.maxLen,
    required this.minDepth,
    required this.maxDepth,
    required this.shapes,
  });

  final int number;
  final String name;
  final int startRows, startCols;
  final int endRows, endCols;
  final int minLen, maxLen;
  final int minDepth, maxDepth;
  final Map<int, String> shapes; // levelIndex (1..20) -> shape key
}

final List<ChapterSpec> chapters = [
  const ChapterSpec(
    number: 1,
    name: 'First Threads',
    startRows: 4,
    startCols: 4,
    endRows: 6,
    endCols: 6,
    minLen: 2,
    maxLen: 4,
    minDepth: 2,
    maxDepth: 4,
    shapes: {5: 'diamond', 10: 'cross', 15: 'shield', 20: 'heart'},
  ),
  const ChapterSpec(
    number: 2,
    name: 'Loose Ends',
    startRows: 5,
    startCols: 5,
    endRows: 7,
    endCols: 7,
    minLen: 2,
    maxLen: 5,
    minDepth: 3,
    maxDepth: 5,
    shapes: {
      4: 'pyramid',
      8: 'hexagon',
      12: 'cross',
      16: 'shield',
      20: 'diamond',
    },
  ),
  const ChapterSpec(
    number: 3,
    name: 'Straight Talk',
    startRows: 6,
    startCols: 6,
    endRows: 8,
    endCols: 8,
    minLen: 2,
    maxLen: 6,
    minDepth: 4,
    maxDepth: 6,
    shapes: {
      3: 'drop',
      6: 'mountain',
      9: 'leaf',
      12: 'bolt',
      15: 'star',
      18: 'tree',
      20: 'heart',
    },
  ),
  const ChapterSpec(
    number: 4,
    name: 'Corners',
    startRows: 6,
    startCols: 6,
    endRows: 8,
    endCols: 8,
    minLen: 3,
    maxLen: 7,
    minDepth: 4,
    maxDepth: 7,
    shapes: {
      3: 'house',
      6: 'fish',
      9: 'crown',
      12: 'anchor',
      15: 'shield',
      18: 'cross',
      20: 'star',
    },
  ),
  const ChapterSpec(
    number: 5,
    name: 'Spirals',
    startRows: 7,
    startCols: 7,
    endRows: 9,
    endCols: 9,
    minLen: 3,
    maxLen: 8,
    minDepth: 5,
    maxDepth: 8,
    shapes: {
      3: 'moon',
      6: 'hexagon',
      9: 'heart',
      12: 'tree',
      15: 'diamond',
      18: 'bolt',
      20: 'star',
    },
  ),
  const ChapterSpec(
    number: 6,
    name: 'Crosscurrents',
    startRows: 7,
    startCols: 7,
    endRows: 9,
    endCols: 9,
    minLen: 3,
    maxLen: 8,
    minDepth: 5,
    maxDepth: 8,
    shapes: {
      3: 'leaf',
      6: 'drop',
      9: 'mountain',
      12: 'anchor',
      15: 'crown',
      18: 'cross',
      20: 'shield',
    },
  ),
  const ChapterSpec(
    number: 7,
    name: 'Dense Weave',
    startRows: 7,
    startCols: 7,
    endRows: 9,
    endCols: 9,
    minLen: 3,
    maxLen: 9,
    minDepth: 6,
    maxDepth: 9,
    shapes: {
      3: 'house',
      6: 'fish',
      9: 'crown',
      12: 'tree',
      15: 'star',
      18: 'heart',
      20: 'diamond',
    },
  ),
  const ChapterSpec(
    number: 8,
    name: 'Labyrinth',
    startRows: 8,
    startCols: 8,
    endRows: 10,
    endCols: 10,
    minLen: 3,
    maxLen: 10,
    minDepth: 7,
    maxDepth: 10,
    shapes: {
      3: 'hexagon',
      6: 'heart',
      9: 'moon',
      12: 'anchor',
      15: 'bolt',
      18: 'cross',
      20: 'star',
    },
  ),
  const ChapterSpec(
    number: 9,
    name: 'Long Form',
    startRows: 8,
    startCols: 8,
    endRows: 10,
    endCols: 10,
    minLen: 4,
    maxLen: 11,
    minDepth: 8,
    maxDepth: 11,
    shapes: {
      3: 'leaf',
      6: 'drop',
      9: 'mountain',
      12: 'tree',
      15: 'shield',
      18: 'crown',
      20: 'star',
    },
  ),
  const ChapterSpec(
    number: 10,
    name: 'Masterworks',
    startRows: 8,
    startCols: 8,
    endRows: 10,
    endCols: 10,
    minLen: 4,
    maxLen: 12,
    minDepth: 8,
    maxDepth: 12,
    shapes: {
      2: 'cross',
      5: 'house',
      8: 'fish',
      11: 'crown',
      14: 'shield',
      17: 'anchor',
      20: 'star',
    },
  ),
];

// Hand-curated tutorial levels for chapter 1 (levels 1-5)
final List<Level> tutorialLevels = [
  // Level 1: 4x4, 2 threads, clear tap
  Level(
    id: 1,
    rows: 4,
    cols: 4,
    threads: [
      Thread(1, [const Cell(1, 1), const Cell(1, 2)]), // points right, free
      Thread(2, [const Cell(2, 1), const Cell(2, 2)]), // points right, free
    ],
  ),
  // Level 2: 4x4, 3 threads, teaches blocker bounce
  Level(
    id: 2,
    rows: 4,
    cols: 4,
    threads: [
      Thread(1, [
        const Cell(2, 0),
        const Cell(1, 0),
        const Cell(0, 0)
      ]), // points up, free
      Thread(2, [
        const Cell(0, 3),
        const Cell(0, 2),
        const Cell(0, 1)
      ]), // points left into t1, blocked
      Thread(3, [
        const Cell(3, 1),
        const Cell(3, 2),
        const Cell(3, 3)
      ]), // points right, free
    ],
  ),
  // Level 3: 5x5, 3 threads, order matters cascade
  Level(
    id: 3,
    rows: 5,
    cols: 5,
    threads: [
      Thread(1, [
        const Cell(0, 3),
        const Cell(1, 3),
        const Cell(2, 3)
      ]), // points down, free
      Thread(2, [
        const Cell(2, 0),
        const Cell(2, 1),
        const Cell(2, 2)
      ]), // points right into t1
      Thread(3, [const Cell(4, 1), const Cell(3, 1)]), // points up into t2
    ],
  ),
  // Level 4: 5x5, 4 threads with corners
  Level(
    id: 4,
    rows: 5,
    cols: 5,
    threads: [
      Thread(1, [
        const Cell(1, 4),
        const Cell(2, 4),
        const Cell(3, 4),
        const Cell(4, 4)
      ]), // points down, free
      Thread(2, [
        const Cell(3, 1),
        const Cell(3, 2),
        const Cell(3, 3)
      ]), // points right into t1
      Thread(3, [
        const Cell(0, 0),
        const Cell(0, 1),
        const Cell(1, 1),
        const Cell(2, 1)
      ]), // points down into t2
      Thread(4, [
        const Cell(4, 0),
        const Cell(4, 1),
        const Cell(4, 2)
      ]), // points right, free
    ],
  ),
  // Level 5: 5x5, 5 threads with dead-end pockets
  Level(
    id: 5,
    rows: 5,
    cols: 5,
    threads: [
      Thread(1, [
        const Cell(0, 3),
        const Cell(0, 2),
        const Cell(0, 1)
      ]), // points left, free
      Thread(2, [
        const Cell(3, 1),
        const Cell(2, 1),
        const Cell(1, 1)
      ]), // points up into t1
      Thread(3, [
        const Cell(1, 3),
        const Cell(2, 3),
        const Cell(3, 3)
      ]), // points down, free
      Thread(4, [const Cell(1, 2), const Cell(2, 2)]), // points down, free
      Thread(5, [
        const Cell(4, 1),
        const Cell(4, 2),
        const Cell(4, 3),
        const Cell(4, 4)
      ]), // points right, free
    ],
  ),
];

void main(List<String> args) {
  if (args.contains('--verify')) {
    verifyAllLevels();
    return;
  }

  generateAllChapters();
  verifyAllLevels();
}

void generateAllChapters() {
  stdout.writeln('=== Unwind Level Generator ===');
  final levelsDir = Directory('assets/levels');
  if (!levelsDir.existsSync()) {
    levelsDir.createSync(recursive: true);
  }

  final report = StringBuffer('# Unwind Level Generation Report\n\n');
  report.writeln('Generated on: ${DateTime.now().toUtc().toIso8601String()}\n');
  report.writeln(
      '| Level | Ch | Name | Grid | Shape | Threads | Coverage | Depth | Init Free | Solved |\n|---|---|---|---|---|---|---|---|---|---|');

  var globalId = 1;

  for (final chapter in chapters) {
    stdout
        .writeln('\nGenerating Chapter ${chapter.number}: ${chapter.name}...');
    final chapterLevels = <Map<String, dynamic>>[];

    for (var idx = 1; idx <= 20; idx++) {
      Level level;

      if (chapter.number == 1 && idx <= 5) {
        level = tutorialLevels[idx - 1];
      } else {
        level = generateLevelFor(chapter, idx, globalId);
      }

      final validity = validateLevel(level);
      if (!validity.isValid) {
        throw StateError(
            'Level $globalId failed validation: ${validity.error}');
      }

      final solveResult = solve(level);
      final mask = ShapePolygons.rasterize(level.shape, level.rows, level.cols);
      final totalThreadCells =
          level.threads.fold<int>(0, (sum, t) => sum + t.cells.length);
      final coveragePct =
          (totalThreadCells / mask.length * 100).toStringAsFixed(1);

      report.writeln(
        '| ${level.id} | ${chapter.number} | ${chapter.name} | ${level.rows}x${level.cols} | ${level.shape} | ${level.threads.length} | $coveragePct% | ${solveResult.depth} | ${solveResult.initialFreeCount} | Yes |',
      );

      chapterLevels.add(level.toJson());
      globalId++;
    }

    final chapterJson = {
      'v': 1,
      'chapter': chapter.number,
      'name': chapter.name,
      'levels': chapterLevels,
    };

    final numStr = chapter.number.toString().padLeft(2, '0');
    final file = File('assets/levels/chapter_$numStr.json');
    file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(chapterJson));
    stdout.writeln('  -> Written: ${file.path} (20 levels)');
  }

  File('tool/level_report.md').writeAsStringSync(report.toString());
  stdout
      .writeln('\nAll 200 levels generated and tool/level_report.md updated.');
}

Level generateLevelFor(ChapterSpec ch, int levelIndex, int id) {
  final progress = (levelIndex - 1) / 19.0;
  final rows = (ch.startRows + (ch.endRows - ch.startRows) * progress).round();
  final cols = (ch.startCols + (ch.endCols - ch.startCols) * progress).round();
  final shape = ch.shapes[levelIndex] ?? 'rect';

  final mask = ShapePolygons.rasterize(shape, rows, cols);
  final seedBase = fnv1a('unwind|${ch.number}|$levelIndex');

  Level? bestLevel;
  var bestScore = -1e9;

  for (var attempt = 0; attempt < 350; attempt++) {
    final rand = Random(seedBase + attempt * 1013);
    final candidate = _generateCandidate(
      id: id,
      rows: rows,
      cols: cols,
      shape: shape,
      mask: mask,
      minLen: ch.minLen,
      maxLen: ch.maxLen,
      rand: rand,
    );

    if (candidate == null) continue;

    final validity = validateLevel(candidate);
    if (!validity.isValid) continue;

    final solveRes = solve(candidate);
    if (!solveRes.isSolved) continue;

    // Check depth and initial free targets
    final initFree = solveRes.initialFreeCount;
    final totalThreads = candidate.threads.length;
    if (initFree < 1) continue;
    if (ch.number >= 3 && (initFree / totalThreads) > 0.45) continue;

    final totalCells =
        candidate.threads.fold<int>(0, (s, t) => s + t.cells.length);
    final coverage = totalCells / mask.length;
    if (shape == 'rect' && coverage < 0.82) continue;
    if (shape != 'rect' && coverage < 0.78) continue;

    var score = coverage * 100.0 + solveRes.depth * 5.0;
    if (solveRes.depth >= ch.minDepth && solveRes.depth <= ch.maxDepth) {
      score += 25.0;
    }

    if (score > bestScore) {
      bestScore = score;
      bestLevel = candidate;
      if (coverage >= 0.88 && solveRes.depth >= ch.minDepth) {
        break; // Excellent match
      }
    }
  }

  return bestLevel ?? _fallbackLevel(id, rows, cols, shape, mask);
}

Level? _generateCandidate({
  required int id,
  required int rows,
  required int cols,
  required String shape,
  required Set<Cell> mask,
  required int minLen,
  required int maxLen,
  required Random rand,
}) {
  final placed = <Thread>[];
  final placedCells = <Cell>{};
  final freeMask = Set<Cell>.of(mask);

  var failures = 0;

  while (freeMask.isNotEmpty && failures < 120) {
    // Pick start cell with fewer free neighbours to fill pockets first
    final start = _pickStartCell(freeMask, rand);
    if (start == null) break;

    final targetLen = minLen + rand.nextInt(maxLen - minLen + 1);
    final walk = _randomWalk(start, targetLen, freeMask, rand);

    if (walk.length < 2) {
      failures++;
      continue;
    }

    // Try both ends as head
    final headCandidate1 = _evaluateHead(walk, rows, cols, placedCells);
    final headCandidate2 =
        _evaluateHead(walk.reversed.toList(), rows, cols, placedCells);

    List<Cell>? acceptedWalk;
    if (headCandidate1 && headCandidate2) {
      acceptedWalk = rand.nextBool() ? walk : walk.reversed.toList();
    } else if (headCandidate1) {
      acceptedWalk = walk;
    } else if (headCandidate2) {
      acceptedWalk = walk.reversed.toList();
    }

    if (acceptedWalk != null) {
      final thread = Thread(placed.length + 1, acceptedWalk);
      placed.add(thread);
      placedCells.addAll(acceptedWalk);
      freeMask.removeAll(acceptedWalk);
      failures = 0;
    } else {
      failures++;
    }
  }

  // Leftover repair: try extending tails
  _repairLeftovers(placed, freeMask, placedCells, rows, cols);

  if (placed.isEmpty) return null;

  // Re-number threads sequentially
  final finalThreads = <Thread>[];
  for (var i = 0; i < placed.length; i++) {
    finalThreads.add(Thread(i + 1, placed[i].cells));
  }

  return Level(
    id: id,
    rows: rows,
    cols: cols,
    threads: finalThreads,
    shape: shape,
  );
}

Cell? _pickStartCell(Set<Cell> freeCells, Random rand) {
  if (freeCells.isEmpty) return null;
  final list = freeCells.toList();

  // Score by number of free neighbours (fewer is better)
  var bestCell = list[rand.nextInt(list.length)];
  var minNeighbours = 99;

  final sampleSize = min(8, list.length);
  for (var i = 0; i < sampleSize; i++) {
    final c = list[rand.nextInt(list.length)];
    var n = 0;
    for (final d in Dir.values) {
      if (freeCells.contains(Cell(c.r + d.dr, c.c + d.dc))) {
        n++;
      }
    }
    if (n < minNeighbours) {
      minNeighbours = n;
      bestCell = c;
    }
  }
  return bestCell;
}

List<Cell> _randomWalk(
    Cell start, int targetLen, Set<Cell> freeCells, Random rand) {
  final walk = <Cell>[start];
  final visited = <Cell>{start};
  var current = start;

  while (walk.length < targetLen) {
    final dirs = Dir.values.toList()..shuffle(rand);
    Cell? next;

    for (final d in dirs) {
      final cand = Cell(current.r + d.dr, current.c + d.dc);
      if (freeCells.contains(cand) && !visited.contains(cand)) {
        next = cand;
        break;
      }
    }

    if (next == null) break;
    walk.add(next);
    visited.add(next);
    current = next;
  }

  return walk;
}

bool _evaluateHead(List<Cell> walk, int rows, int cols, Set<Cell> placedCells) {
  final head = walk.last;
  final pen = walk[walk.length - 2];
  final dr = head.r - pen.r;
  final dc = head.c - pen.c;

  final walkCells = walk.toSet();

  var r = head.r + dr;
  var c = head.c + dc;

  while (r >= 0 && r < rows && c >= 0 && c < cols) {
    final cell = Cell(r, c);
    // Ray must not hit already-placed threads or this walk's own body
    if (placedCells.contains(cell) || walkCells.contains(cell)) {
      return false;
    }
    r += dr;
    c += dc;
  }
  return true;
}

void _repairLeftovers(
  List<Thread> placed,
  Set<Cell> freeMask,
  Set<Cell> placedCells,
  int rows,
  int cols,
) {
  final leftovers = freeMask.toList();
  for (final leftover in leftovers) {
    for (var i = 0; i < placed.length; i++) {
      final t = placed[i];
      final tail = t.tail;
      final dr = (leftover.r - tail.r).abs();
      final dc = (leftover.c - tail.c).abs();

      if (dr + dc == 1) {
        // Try prepending leftover to tail
        final newCells = [leftover, ...t.cells];
        final newThread = Thread(t.id, newCells);

        // Check if new thread body doesn't intersect other placed threads
        if (!placedCells.contains(leftover)) {
          placed[i] = newThread;
          placedCells.add(leftover);
          freeMask.remove(leftover);
          break;
        }
      }
    }
  }
}

Level _fallbackLevel(int id, int rows, int cols, String shape, Set<Cell> mask) {
  // Safe simple fallback level generator with orthogonal lines
  final threads = <Thread>[];
  final sortedCells = mask.toList()
    ..sort((a, b) => a.r != b.r ? a.r.compareTo(b.r) : a.c.compareTo(b.c));

  final used = <Cell>{};
  var tid = 1;

  for (final c in sortedCells) {
    if (used.contains(c)) continue;
    final right = Cell(c.r, c.c + 1);
    if (mask.contains(right) && !used.contains(right)) {
      threads.add(Thread(tid++, [c, right]));
      used.add(c);
      used.add(right);
      continue;
    }
    final down = Cell(c.r + 1, c.c);
    if (mask.contains(down) && !used.contains(down)) {
      threads.add(Thread(tid++, [c, down]));
      used.add(c);
      used.add(down);
      continue;
    }
  }

  return Level(
    id: id,
    rows: rows,
    cols: cols,
    threads: threads,
    shape: shape,
  );
}

void verifyAllLevels() {
  stdout.writeln('\n=== Verifying All 200 Level Assets ===');
  var verifiedCount = 0;

  for (var ch = 1; ch <= 10; ch++) {
    final numStr = ch.toString().padLeft(2, '0');
    final file = File('assets/levels/chapter_$numStr.json');
    if (!file.existsSync()) {
      throw StateError('Missing asset: ${file.path}');
    }

    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final levelsRaw = jsonMap['levels'] as List<dynamic>;

    if (levelsRaw.length != 20) {
      throw StateError(
          'Chapter $ch has ${levelsRaw.length} levels (expected 20).');
    }

    for (final raw in levelsRaw) {
      final level = Level.fromJson(raw as Map<String, dynamic>, chapter: ch);
      final val = validateLevel(level);
      if (!val.isValid) {
        throw StateError(
            'Level ${level.id} in chapter $ch is invalid: ${val.error}');
      }
      final solveRes = solve(level);
      if (!solveRes.isSolved) {
        throw StateError('Level ${level.id} in chapter $ch is unsolvable.');
      }
      verifiedCount++;
    }
  }

  stdout.writeln(
      'Verification passed: All $verifiedCount levels are 100% valid and solvable.');
}
