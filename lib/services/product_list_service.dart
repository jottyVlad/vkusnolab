import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CartItem {
  final int id;
  final String text;

  CartItem({required this.id, required this.text});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      text: json['text_recipe_ingredient'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'text_recipe_ingredient': text,
  };
}

class ProductListService {
  static final ProductListService _instance = ProductListService._internal();
  factory ProductListService() => _instance;
  ProductListService._internal();

  final ValueNotifier<List<CartItem>> cartNotifier = ValueNotifier([]);
  final AuthService _authService = AuthService();
  final String _baseUrl = 'http://77.110.103.162/api/v1/recipe/cart/';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> getCartItems() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        print('Cart response: ' + decoded.toString());
        final List<dynamic> data = decoded is List
            ? decoded
            : (decoded['data'] ?? []);
        cartNotifier.value = data.map((e) => CartItem.fromJson(e)).toList();
      } else {
        print('Failed to get cart items. Status: ${response.statusCode}, Body: ${response.body}');
        cartNotifier.value = [];
        throw Exception('Не удалось загрузить корзину: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting cart items: $e');
      cartNotifier.value = [];
      throw Exception('Ошибка при загрузке корзины: $e');
    }
  }

  Future<void> addProduct(String text) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: headers,
      body: jsonEncode({'text_recipe_ingredient': text}),
    );
    print('Add product response: \\${response.statusCode} \\${response.body}');
    if (response.statusCode == 201) {
      await getCartItems();
    } else {
      throw Exception('Не удалось добавить продукт');
    }
  }

  Future<void> addProducts(List<String> products) async {
    final headers = await _getHeaders();
    final body = jsonEncode(products.map((e) => {'text_recipe_ingredient': e}).toList());
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: headers,
      body: body,
    );
    if (response.statusCode == 201) {
      await getCartItems();
    } else {
      throw Exception('Не удалось добавить продукты');
    }
  }

  Future<void> removeProduct(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl$id/'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 204) {
        // Optimistically update the local state
        cartNotifier.value = cartNotifier.value.where((item) => item.id != id).toList();
        // Then refresh from server to ensure consistency
        await getCartItems();
      } else {
        print('Failed to remove product $id. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Не удалось удалить продукт: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing product $id: $e');
      throw Exception('Ошибка при удалении продукта: $e');
    }
  }

  Future<void> editProduct(int id, String newText) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl$id/'),
      headers: headers,
      body: jsonEncode({'text_recipe_ingredient': newText}),
    );
    if (response.statusCode == 200) {
      await getCartItems();
    } else {
      throw Exception('Не удалось обновить продукт');
    }
  }
} 