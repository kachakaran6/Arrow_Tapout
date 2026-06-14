/// Game constants for Arrow Tap-Out
class GameConstants {
  GameConstants._();

  // Grid
  static const int gridCols = 6;
  static const int gridRows = 6;
  static const double cellSize = 64.0; // px per cell
  static const double cellPadding = 4.0; // padding between cells
  static const double arrowSize = 48.0; // rendered arrow size within cell

  // Animation durations (ms)
  static const int exitAnticipationMs = 80;
  static const int exitSquishMs = 50;
  static const int exitLaunchMs = 350;
  static const int exitTotalMs = 480;

  static const int blockedTotalMs = 320;
  static const int blockedShakePx = 8; // shake amplitude pixels

  static const int idleGlowMs = 1800;
  static const int idleBreathMs = 2200;

  static const int settleMs = 200;
  static const int emptyCellPulseMs = 120;

  static const int boardFloatMs = 3000;
  static const int cameraDriftMs = 12000;

  // Particle system
  static const int trailParticleCount = 14;
  static const double trailSpreadAngleDeg = 25.0;
  static const int trailLifetimeMinMs = 300;
  static const int trailLifetimeMaxMs = 500;

  static const int confettiCount = 80;

  // Camera
  static const double cameraMinZoom = 0.6;
  static const double cameraMaxZoom = 2.5;
  static const double cameraDriftAngleDeg = 2.0;

  // Combo milestones
  static const List<int> comboMilestones = [3, 5, 10, 15, 25, 50];

  // Restart confirmation window (ms)
  static const int restartConfirmWindowMs = 2000;

  // HUD
  static const double hudHeight = 40.0;
  static const double bottomBarHeight = 56.0;
  static const double hudPadding = 16.0;
}
