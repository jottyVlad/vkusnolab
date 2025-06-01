import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class LikeService {
  final String _baseUrl = 'http://77.110.103.162/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _authService.getAccessToken();
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Get list of liked recipe IDs
  Future<List<int>> getLikedRecipeIds() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/likes/');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map<int>((like) => like['recipe'] as int).toList();
    } else {
      throw Exception('Failed to get liked recipes');
    }
  }

  // Add a like
  Future<void> likeRecipe(int recipeId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/likes/');
    final body = jsonEncode({'recipe': recipeId});
    final response = await http.post(uri, headers: headers, body: body);
    if (response.statusCode != 201) {
      throw Exception('Failed to like recipe');
    }
  }

  // Remove a like by like ID
  Future<void> unlikeRecipe(int likeId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/likes/$likeId/');
    final response = await http.delete(uri, headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike recipe');
    }
  }

  // Get like ID for a recipe (needed for unliking)
  Future<int?> getLikeIdForRecipe(int recipeId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/likes/');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      for (final like in data) {
        if (like['recipe'] == recipeId) {
          return like['id'] as int;
        }
      }
      return null;
    } else {
      throw Exception('Failed to get like ID');
    }
  }
} 