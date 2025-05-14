import 'package:flutter/foundation.dart' show immutable;

@immutable
class IngredientItem {
  final String name;
  final String quantity;
  final String unit;

  const IngredientItem({
    required this.name,
    required this.quantity,
    required this.unit,
  });


} 