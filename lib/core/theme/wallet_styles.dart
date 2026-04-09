import 'package:flutter/material.dart';

class WalletStyle {
  final List<Color> gradient;
  final String? logoPath;
  final Color textColor;
  final Color? iconColor;
  final String? backgroundImagePath;

  const WalletStyle({
    required this.gradient,
    this.logoPath,
    this.textColor = Colors.white,
    this.iconColor,
    this.backgroundImagePath,
  });
}

class WalletStyles {
  static const Map<String, WalletStyle> _brandStyles = {
    // E-Wallets
    'gopay': WalletStyle(
      gradient: [Color(0xFF00AED6), Color(0xFF0081A0)],
      logoPath: 'assets/images/ewallet/logo_gopay.png',
    ),
    'ovo': WalletStyle(
      gradient: [Color(0xFF4C2A86), Color(0xFF361D5F)],
      logoPath: 'assets/images/ewallet/logo_ovo.png',
    ),
    'dana': WalletStyle(
      gradient: [Color(0xFF118EEA), Color(0xFF0D6DB3)],
      logoPath: 'assets/images/ewallet/logo_dana.png',
      backgroundImagePath: 'assets/images/ewallet/card/dana_card.png',
    ),
    'shopeepay': WalletStyle(
      gradient: [Color(0xFFEE4D2D), Color(0xFFB23922)],
      logoPath: 'assets/images/ewallet/logo_spay.png',
    ),
    'linkaja': WalletStyle(
      gradient: [Color(0xFFE61C30), Color(0xFFA51422)],
      logoPath: 'assets/images/ewallet/logo_linkaja.png',
    ),

    // Digital Banks
    'seabank': WalletStyle(
      gradient: [Color(0xFFFF5A00), Color(0xFFBF4300)],
    ),
    'bank jago': WalletStyle(
      gradient: [Color(0xFFFFD600), Color(0xFFC7A700)],
      textColor: Color(0xFF3D3D3D),
      iconColor: Color(0xFF3D3D3D),
    ),
    'jago': WalletStyle(
      gradient: [Color(0xFFFFD600), Color(0xFFC7A700)],
      textColor: Color(0xFF3D3D3D),
      iconColor: Color(0xFF3D3D3D),
    ),
    'blu': WalletStyle(
      gradient: [Color(0xFF00A3FF), Color(0xFF007ACC)],
    ),
    'neobank': WalletStyle(
      gradient: [Color(0xFFFFD600), Color(0xFFFF9D00)],
      textColor: Color(0xFF3D3D3D),
    ),
    'allo bank': WalletStyle(
      gradient: [Color(0xFF1A1A1A), Color(0xFF333333)],
    ),

    // Traditional Banks
    'bca': WalletStyle(
      gradient: [Color(0xFF0056A3), Color(0xFF003D73)],
    ),
    'bni': WalletStyle(
      gradient: [Color(0xFFF15A23), Color(0xFFB3421A)],
    ),
    'mandiri': WalletStyle(
      gradient: [Color(0xFF003D79), Color(0xFF00274D)],
    ),
    'bri': WalletStyle(
      gradient: [Color(0xFF00529C), Color(0xFF003A6E)],
    ),
  };

  static WalletStyle getStyle(String name, String type) {
    final lowerName = name.toLowerCase();
    
    // Check for exact or partial matches in keys
    for (final brand in _brandStyles.keys) {
      if (lowerName.contains(brand)) {
        return _brandStyles[brand]!;
      }
    }

    // Fallback to type-based styles
    switch (type) {
      case 'bankmobile':
        return const WalletStyle(gradient: [Color(0xFF1565C0), Color(0xFF0288D1)]);
      case 'digitalbank':
        return const WalletStyle(gradient: [Color(0xFF6A1B9A), Color(0xFFAD1457)]);
      case 'ewallet':
        return const WalletStyle(gradient: [Color(0xFFE65100), Color(0xFFFF8F00)]);
      case 'cash':
        return const WalletStyle(gradient: [Color(0xFF1B5E20), Color(0xFF00897B)]);
      case 'debt':
        return const WalletStyle(gradient: [Color(0xFFC62828), Color(0xFFE53935)]);
      case 'receivable':
        return const WalletStyle(gradient: [Color(0xFF2E7D32), Color(0xFF43A047)]);
      default:
        return const WalletStyle(gradient: [Color(0xFF455A64), Color(0xFF263238)]);
    }
  }
}
