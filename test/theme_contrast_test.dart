import 'dart:math' as math;

import 'package:arrowtapout/design/app_tokens.dart';
import 'package:arrowtapout/design/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Calculates relative luminance for WCAG contrast calculation.
double _relativeLuminance(Color color) {
  double channelLuminance(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    }
    return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channelLuminance(color.r);
  final g = channelLuminance(color.g);
  final b = channelLuminance(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates WCAG 2.1 contrast ratio between two colors.
double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final brighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (brighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Theme Contrast & WCAG Gates', () {
    final themes = <String, AppTokens>{
      'Sage Linen': AppThemes.sageLinenTokens,
      'Ink and Brass': AppThemes.inkAndBrassTokens,
      'Fog Slate': AppThemes.fogSlateTokens,
      'Rosewood': AppThemes.rosewoodTokens,
      'Graphite Ember': AppThemes.graphiteEmberTokens,
    };

    for (final entry in themes.entries) {
      final name = entry.key;
      final tokens = entry.value;

      group('Theme: $name', () {
        test('ink on bg contrast is at least 7.0:1', () {
          final ratio = _contrastRatio(tokens.ink, tokens.bg);
          expect(
            ratio,
            greaterThanOrEqualTo(7.0),
            reason: '$name: ink on bg ratio is $ratio (needs >= 7.0)',
          );
        });

        test('ink on surface contrast is at least 7.0:1', () {
          final ratio = _contrastRatio(tokens.ink, tokens.surface);
          expect(
            ratio,
            greaterThanOrEqualTo(7.0),
            reason: '$name: ink on surface ratio is $ratio (needs >= 7.0)',
          );
        });

        test('inkMuted on bg contrast is at least 4.5:1', () {
          final ratio = _contrastRatio(tokens.inkMuted, tokens.bg);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$name: inkMuted on bg ratio is $ratio (needs >= 4.5)',
          );
        });

        test('accent on bg contrast is at least 3.0:1', () {
          final ratio = _contrastRatio(tokens.accent, tokens.bg);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason: '$name: accent on bg ratio is $ratio (needs >= 3.0)',
          );
        });

        test('onAccent on accent contrast is at least 4.5:1', () {
          final ratio = _contrastRatio(tokens.onAccent, tokens.accent);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$name: onAccent on accent ratio is $ratio (needs >= 4.5)',
          );
        });

        test('danger on bg contrast is at least 3.0:1', () {
          final ratio = _contrastRatio(tokens.danger, tokens.bg);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason: '$name: danger on bg ratio is $ratio (needs >= 3.0)',
          );
        });
      });
    }

    test('AppTokens lerp works smoothly and matches endpoints', () {
      const t1 = AppThemes.sageLinenTokens;
      const t2 = AppThemes.inkAndBrassTokens;

      final lerp0 = t1.lerp(t2, 0.0);
      expect(lerp0.bg, equals(t1.bg));
      expect(lerp0.accent, equals(t1.accent));
      expect(lerp0.gridDot, equals(t1.gridDot));

      final lerp1 = t1.lerp(t2, 1.0);
      expect(lerp1.bg, equals(t2.bg));
      expect(lerp1.accent, equals(t2.accent));
      expect(lerp1.gridDot, equals(t2.gridDot));

      final lerpHalf = t1.lerp(t1, 0.5);
      expect(lerpHalf.bg, equals(t1.bg));
      expect(lerpHalf.accent, equals(t1.accent));
      expect(lerpHalf.gridDot, equals(t1.gridDot));
    });
  });
}
