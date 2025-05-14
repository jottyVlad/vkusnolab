import 'package:flutter/foundation.dart' show immutable;
import 'package:vkusnolab/models/ingredient.dart'; 


@immutable
class RecipeIngredient {
  final int id; 
  final Ingredient ingredient; 
  final double count;
  final String visibleTypeOfCount; 

  const RecipeIngredient({
    required this.id,
    required this.ingredient,
    required this.count,
    required this.visibleTypeOfCount,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    double safeParseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
      return 0.0;
    }
    

    final int ingredientId = json['ingredient'] as int? ?? 0;
    final String ingredientName = json['name'] as String? ?? 'Неизвестный ингредиент'; 
    

    return RecipeIngredient(
      id: json['id'] as int? ?? 0,
      ingredient: Ingredient(id: ingredientId, name: ingredientName),
      count: safeParseDouble(json['count']),
      visibleTypeOfCount: json['visible_type_of_count'] as String? ?? '',
    );
  }

  String get displayString {
    final String formattedCount = count == count.truncate() ? count.truncate().toString() : count.toStringAsFixed(1); // Show 1 decimal place if needed
    return '$formattedCount ${visibleTypeOfCount} ${ingredient.name}';
  }

 
  Map<String, dynamic> toJson() {
    return {
      'ingredient': ingredient.toJson(),
      'count': count,
      'visible_type_of_count': visibleTypeOfCount,
    };
  }
} 