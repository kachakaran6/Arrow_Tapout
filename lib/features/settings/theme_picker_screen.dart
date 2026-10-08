import 'package:arrowtapout/data/settings_repository.dart';
import 'package:arrowtapout/design/app_tokens.dart';
import 'package:arrowtapout/design/primitives.dart';
import 'package:arrowtapout/design/themes.dart';
import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:arrowtapout/features/game/board_painter.dart';
import 'package:arrowtapout/features/game/thread_animator.dart';
import 'package:arrowtapout/platform/haptics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ThemePickerScreen extends ConsumerStatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  ConsumerState<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends ConsumerState<ThemePickerScreen>
    with SingleTickerProviderStateMixin {
  late BoardAnimator _animator;
  late Level _previewLevel;
  late Set<int> _activeIds;

  @override
  void initState() {
    super.initState();
    _animator = BoardAnimator(vsync: this);
    _previewLevel = Level(
      id: 12,
      rows: 5,
      cols: 5,
      threads: [
        Thread(1, [const Cell(0, 1), const Cell(0, 2), const Cell(0, 3)]),
        Thread(2, [const Cell(1, 4), const Cell(2, 4), const Cell(3, 4)]),
        Thread(3, [const Cell(4, 3), const Cell(4, 2), const Cell(4, 1)]),
        Thread(4, [const Cell(3, 0), const Cell(2, 0), const Cell(1, 0)]),
      ],
    );
    _activeIds = {1, 2, 3, 4};
    _animator.setLevel(_previewLevel, 14.0);
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final selectedMode = ref.watch(settingsProvider).themeChoice;
    final haptics = ref.read(hapticsServiceProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);

    const options = AppThemeMode.values;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text('Themes', style: tokens.typography.title),
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
        child: GridView.builder(
          padding: const EdgeInsets.all(Primitives.space20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: Primitives.space16,
            mainAxisSpacing: Primitives.space16,
            childAspectRatio: 0.85,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final mode = options[index];
            final isSelected = mode == selectedMode;
            final tileTokens = AppThemes.tokensFor(mode, brightness);

            return Semantics(
              label: '${mode.label} theme${isSelected ? ', selected' : ''}',
              button: true,
              child: InkWell(
                onTap: () {
                  haptics.selection();
                  ref.read(settingsProvider.notifier).setThemeChoice(mode);
                },
                borderRadius: BorderRadius.circular(Primitives.radiusCard),
                child: Container(
                  decoration: BoxDecoration(
                    color: tileTokens.bg,
                    borderRadius: BorderRadius.circular(Primitives.radiusCard),
                    border: Border.all(
                      color:
                          isSelected ? tokens.accent : tileTokens.threadFaint,
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: tokens.accent.withValues(alpha: 0.15),
                              blurRadius: 12.0,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(Primitives.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mini board preview
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: tileTokens.surface,
                            borderRadius:
                                BorderRadius.circular(Primitives.radiusChip),
                          ),
                          alignment: Alignment.center,
                          child: CustomPaint(
                            size: const Size(56.0, 56.0),
                            painter: BoardPainter(
                              level: _previewLevel,
                              activeIds: _activeIds,
                              cellSize: 14.0,
                              tokens: tileTokens,
                              animator: _animator,
                              reduceMotion: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Primitives.space12),
                      // Title & Checkmark
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              mode.label,
                              style: TextStyle(
                                fontFamily: Primitives.fontUi,
                                fontSize: 13.0,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: tileTokens.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 18.0,
                              height: 18.0,
                              decoration: BoxDecoration(
                                color: tokens.accent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.check_rounded,
                                size: 12.0,
                                color: tokens.onAccent,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
