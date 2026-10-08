import 'package:arrowtapout/features/game/thread_animator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exit Motion Function p(u) Mathematical Properties', () {
    const double testCell = 24.0;
    const double testRay = 4.0 * testCell;
    const double testLength = 3.0 * testCell;
    const double testD = testRay + testLength + 0.6 * testCell;
    const double testA = 0.16 * testCell;

    double p(double u) => calculateExitDisplacement(
          u: u,
          totalDistanceD: testD,
          anticipationA: testA,
        );

    test('p(0) = 0 exactly', () {
      expect(p(0.0), closeTo(0.0, 1e-9));
    });

    test('p(1) = D exactly', () {
      expect(p(1.0), closeTo(testD, 1e-9));
    });

    test('p is non-increasing on [0, 0.08]', () {
      var prev = p(0.0);
      const steps = 100;
      for (var i = 1; i <= steps; i++) {
        final u = (i / steps) * 0.08;
        final curr = p(u);
        expect(curr, lessThanOrEqualTo(prev + 1e-9),
            reason: 'p($u) should be <= p(${u - 0.08 / steps})');
        prev = curr;
      }
    });

    test('p is non-decreasing on [0.1, 1.0]', () {
      var prev = p(0.10);
      const steps = 900;
      for (var i = 1; i <= steps; i++) {
        final u = 0.10 + (i / steps) * 0.90;
        final curr = p(u);
        expect(curr, greaterThanOrEqualTo(prev - 1e-9),
            reason: 'p($u) should be >= previous');
        prev = curr;
      }
    });

    test(
        'finite-difference slope has no jump larger than 5% of D across 1/240 steps',
        () {
      const dt = 1.0 / 240.0;
      const maxAllowedJump = 0.05 * testD;

      double slopeAt(double u) {
        return (p(u + dt) - p(u)) / dt;
      }

      var prevSlope = slopeAt(0.0);
      for (var u = dt; u <= 1.0 - dt * 2; u += dt) {
        final currSlope = slopeAt(u);
        final changeInStep = (currSlope - prevSlope).abs() * dt;
        expect(changeInStep, lessThanOrEqualTo(maxAllowedJump),
            reason:
                'Slope change at u=$u is too large ($changeInStep > $maxAllowedJump)');
        prevSlope = currSlope;
      }
    });
  });
}
