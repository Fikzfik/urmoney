import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF7F7FE);
  
  static const Color primary = Color(0xFF6A62FF);
  static const Color primaryDark = Color(0xFF3B32FF);
  
  static const Color textPrimary = Color(0xFF1E1E2D);
  static const Color textSecondary = Color(0xFF8F92A1);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B78FF), Color(0xFF5A4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardDeepBlue = LinearGradient(
    colors: [Color(0xFF4A55FF), Color(0xFF2633C5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardOrange = LinearGradient(
    colors: [Color(0xFFFFB347), Color(0xFFFF7B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardPurple = LinearGradient(
    colors: [Color(0xFFB55DFF), Color(0xFF8C20E1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundWave = LinearGradient(
    colors: [Color(0xFFE5E5FF), Color(0xFFF0F0FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
