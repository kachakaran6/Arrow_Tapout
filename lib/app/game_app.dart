import 'package:flutter/material.dart';
import 'package:arrowtapout/ui/game_screen.dart';
import 'package:arrowtapout/design/colors.dart';

/// Root Flutter app
class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Tap-Out',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: GameColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4ECAFF),
          surface: Color(0xFF141729),
        ),
      ),
      home: const GameScreen(),
    );
  }
}
