import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String? bookId;
  final String name;
  final String type; // 'expense' or 'income'
  final IconData icon;
  final Color color;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.userId,
    this.bookId,
    required this.name,
    required this.type,
    required this.icon,
    this.color = Colors.blue,
    this.isDefault = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'] != null ? IconData(int.parse(json['icon']), fontFamily: 'MaterialIcons') : Icons.category,
      color: json['color'] != null ? Color(int.parse(json['color'].replaceAll('#', '0xFF'))) : Colors.blue,
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'icon': icon.codePoint.toString(),
      'color': '0x${color.value.toRadixString(16).padLeft(8, '0')}',
      'is_default': isDefault,
      if (bookId != null) 'book_id': bookId,
    };
  }
}
