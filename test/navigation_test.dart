import 'package:arrowtapout/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Navigation & Route Helpers', () {
    test('typed route paths match specification', () {
      expect(Routes.splash, equals('/'));
      expect(Routes.home, equals('/home'));
      expect(Routes.levels, equals('/levels'));
      expect(Routes.settings, equals('/settings'));
      expect(Routes.theme, equals('/settings/theme'));
      expect(Routes.howToPlay, equals('/howto'));
      expect(Routes.stats, equals('/stats'));
      expect(Routes.devLab, equals('/dev/lab'));
      expect(Routes.play(1), equals('/play/1'));
      expect(Routes.play(200), equals('/play/200'));
    });
  });
}
