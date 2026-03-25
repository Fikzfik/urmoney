import 'package:flutter/material.dart';

// Utility: format Rupiah with thousand separators
String formatRp(double amount) {
  final str = amount.toStringAsFixed(0);
  final result = StringBuffer();
  final reversed = str.split('').reversed.toList();
  for (int i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) result.write('.');
    result.write(reversed[i]);
  }
  return 'Rp ${result.toString().split('').reversed.join()}';
}

class AppColors {
  // Core
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF2979FF);

  // Backgrounds
  static const Color background = Color(0xFFF0F4FC);
  static const Color card = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF8A94A6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardDeepBlue = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardOrange = LinearGradient(
    colors: [Color(0xFFFF6F00), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardPurple = LinearGradient(
    colors: [Color(0xFF6A1B9A), Color(0xFFAD1457)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundWave = LinearGradient(
    colors: [Color(0xFFE3ECFF), Color(0xFFF0F4FC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Income / Expense colors
  static const Color income = Color(0xFF00897B);
  static const Color expense = Color(0xFFE53935);

  // Wallet type gradients
  static const Map<String, List<Color>> walletGradients = {
    'bankmobile': [Color(0xFF1565C0), Color(0xFF0288D1)],
    'digitalbank': [Color(0xFF6A1B9A), Color(0xFFAD1457)],
    'ewallet': [Color(0xFFE65100), Color(0xFFFF8F00)],
    'cash': [Color(0xFF1B5E20), Color(0xFF00897B)],
  };
}
