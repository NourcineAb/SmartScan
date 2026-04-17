import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final int color;
  final String? icon;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.createdAt,
  });

  Color getColor() => Color(color);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as int,
      icon: map['icon'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    int? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, color: $color)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          color == other.color;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ color.hashCode;
}
