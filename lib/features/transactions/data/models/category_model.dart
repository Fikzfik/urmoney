import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String? bookId;
  final String name;
  final String type; // 'expense' or 'income'
  final IconData? icon;
  final String? iconPath;
  final Color color;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.userId,
    this.bookId,
    required this.name,
    required this.type,
    this.icon,
    this.iconPath,
    this.color = Colors.blue,
    this.isDefault = false,
  }) : assert(icon != null || iconPath != null);

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawIcon = json['icon'] as String?;
    final iconCode = rawIcon != null ? int.tryParse(rawIcon) : null;

    return CategoryModel(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      name: json['name'],
      type: json['type'],
      icon: iconCode != null ? IconData(iconCode, fontFamily: 'MaterialIcons') : null,
      iconPath: iconCode == null ? rawIcon : null,
      color: json['color'] != null ? Color(int.parse(json['color'].replaceAll('#', '0xFF'))) : Colors.blue,
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'icon': iconPath ?? icon?.codePoint.toString(),
      'color': '0x${color.value.toRadixString(16).padLeft(8, '0')}',
      'is_default': isDefault,
      if (bookId != null) 'book_id': bookId,
    };
  }
}
