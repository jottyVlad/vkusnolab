import 'package:flutter/foundation.dart' show immutable;

@immutable
class Ingredient {
  final int id;
  final String name;

  const Ingredient({required this.id, required this.name});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Неизвестный ингредиент',
    );
  }


  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
} 