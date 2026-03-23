import 'package:flutter/material.dart';

class CategoryItemModel {
  final String id;
  final String categoryId;
  final String name;
  final IconData icon;

  CategoryItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.icon,
  });

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryItemModel(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      icon: json['icon'] != null ? IconData(int.parse(json['icon']), fontFamily: 'MaterialIcons') : Icons.label,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'icon': icon.codePoint.toString(),
    };
  }
}
