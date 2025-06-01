import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vkusnolab/services/auth_service.dart';
import 'package:vkusnolab/models/ingredient.dart'; 

class IngredientService {
  final String _baseUrl = 'http://77.110.103.162/api'; 
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _authService.getAccessToken();
    var headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  
  Future<List<Ingredient>> getIngredients({String? search}) async {
    final headers = await _getHeaders();
    
    final uri = Uri.parse('$_baseUrl/v1/recipe/ingredients/')
        .replace(queryParameters: search != null && search.isNotEmpty ? {'search': search} : null);

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<Ingredient> ingredients = body
            .map((dynamic item) => Ingredient.fromJson(item as Map<String, dynamic>))
            .toList();
        return ingredients;
      } else {
        print('Failed to load ingredients. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load ingredients. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching ingredients: $e');
      throw Exception('Error fetching ingredients: $e');
    }
  }


} 