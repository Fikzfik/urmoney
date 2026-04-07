import 'package:flutter/material.dart';

class CategoryItemModel {
  final String id;
  final String categoryId;
  final String name;
  final IconData? icon;
  final String? iconPath;

  CategoryItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.icon,
    this.iconPath,
  }) : assert(icon != null || iconPath != null);

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    final rawIcon = json['icon'] as String?;
    final iconCode = rawIcon != null ? int.tryParse(rawIcon) : null;
    
    return CategoryItemModel(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      icon: iconCode != null ? IconData(iconCode, fontFamily: 'MaterialIcons') : null,
      iconPath: iconCode == null ? rawIcon : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'icon': iconPath ?? icon?.codePoint.toString(),
    };
  }
}
