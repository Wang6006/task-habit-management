import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final int index;
  final String color;

  Category({this.id, required this.name, this.index = 0, required this.color});

  Category copyWith({int? id, String? name, int? index, String? color}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      index: index ?? this.index,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'index': index, 'color': color};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      index: map['index'] as int? ?? 0,
      color: map['color'] as String,
    );
  }

  // Get color value from string
  Color getColor() {
    return CategoryColors.fromString(color);
  }
}

class CategoryColors {
  static const Map<String, Color> _colors = {
    'gray': Colors.grey,
    'blue': Colors.blue,
    'red': Colors.red,
    'orange': Colors.orange,
    'green': Colors.green,
    'yellow': Colors.yellow,
  };

  static Color fromString(String colorName) {
    return _colors[colorName.toLowerCase()] ?? Colors.grey;
  }

  static String colorToString(Color color) {
    return _colors.entries
        .firstWhere(
          (entry) => entry.value == color,
          orElse: () => const MapEntry('gray', Colors.grey),
        )
        .key;
  }

  static List<String> get allColors => _colors.keys.toList();
}
