import 'dart:convert';
import 'dart:async'; 
import 'dart:io'; 
import 'package:http/http.dart' as http;
import 'package:vkusnolab/auth_service.dart';
import '../home_page.dart'; 
import '../models/recipe_ingredient.dart'; 


class PaginatedRecipes {
  final List<Recipe> recipes;
  final int count; 
  final String? next; 
  final String? previous;

  PaginatedRecipes({
    required this.recipes,
    required this.count,
    this.next,
    this.previous,
  });
}

class RecipeService {
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

  // GET /v1/recipe/recipe/
  Future<PaginatedRecipes> getRecipes({int page = 1, int pageSize = 10, String? searchQuery}) async {
    final headers = await _getHeaders();
    final queryParameters = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
    };
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParameters['search'] = searchQuery;
    }

    final uri = Uri.parse('$_baseUrl/v1/recipe/recipe/').replace(queryParameters: queryParameters);

    print("Fetching recipes from: $uri with headers: $headers"); 

    try {
      final response = await http.get(uri, headers: headers)
                             .timeout(const Duration(seconds: 15));
      
      print("Get recipes response status: ${response.statusCode}");
      // print("Get recipes response body: ${response.body}"); // Careful with large responses

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(utf8.decode(response.bodyBytes));

        if (responseData is! Map<String, dynamic>) {
            print('Failed to parse recipes: Response body is not a Map. Body: ${response.body}');
            throw Exception('Неверный формат ответа сервера.');
        }
        
        final int count = responseData['count'] as int? ?? 0;
        final String? next = responseData['next'] as String?;
        final String? previous = responseData['previous'] as String?;

        if (responseData['results'] != null && responseData['results'] is List) {
            final List<dynamic> results = responseData['results'] as List<dynamic>;
            try {
                List<Recipe> recipes = results
                    .map((dynamic item) => Recipe.fromJson(item as Map<String, dynamic>))
                    .toList();
                 print("Successfully fetched and parsed ${recipes.length} recipes out of $count total for query: '$searchQuery'");
                return PaginatedRecipes(
                  recipes: recipes,
                  count: count,
                  next: next,
                  previous: previous,
                );
            } catch (e, stacktrace) {
                print('Ошибка парсинга отдельного рецепта из результатов: $e\n$stacktrace');
                throw Exception('Ошибка парсинга данных рецепта: $e');
            }
        } else {
            print('Failed to parse recipes: \'results\' field missing or not a list. Response: ${response.body}');
            throw Exception('Не удалось разобрать список рецептов из ответа сервера.');
        }
      } else if (response.statusCode == 404) {
          print('Recipe list endpoint not found (404). URL: $uri');
          throw Exception('Конечная точка рецептов не найдена (404). Пожалуйста, проверьте путь API.');
      } else {
        final errorBody = response.body;
        print('Failed to load recipes. Status: ${response.statusCode}, Body: $errorBody');
        throw Exception('Не удалось загрузить рецепты. Код состояния: ${response.statusCode}. Ответ: $errorBody');
      }
    } on TimeoutException catch (e) {
        print('Error fetching recipes: Timeout occurred after 15 seconds. $e');
        throw Exception('Время ожидания запроса истекло. Пожалуйста, проверьте ваше соединение или попробуйте позже.');
    } on SocketException catch (e) {
        print('Network error fetching recipes: $e');
        throw Exception('Ошибка сети при получении рецептов. Проверьте ваше интернет-соединение.');
    } catch (e, stacktrace) {
      print('Error fetching recipes: $e\n$stacktrace');
      print('Caught error of type: ${e.runtimeType}'); 
      throw Exception('Ошибка при получении рецептов: $e');
    }
  }

  // GET /v1/recipe/recipe/{id}/
  Future<Recipe> getRecipeById(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/recipe/$id/');

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return Recipe.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      } else {
        print('Failed to load recipe $id. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load recipe $id. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipe $id: $e');
      throw Exception('Error fetching recipe $id: $e');
    }
  }

  // POST /v1/recipe/recipe/
  Future<Recipe> createRecipe({
    required String title,
    required String description,
    required String instructions,
    required int cookingTimeMinutes,
    required int servings,
    required bool isActive,
    required bool isPrivate,
    required List<Map<String, dynamic>> ingredients, 
    String? imagePath, 
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/recipe/');
    
    print("[RecipeService] Creating recipe with multipart/form-data...");
    print("[RecipeService] Title: $title");
    print("[RecipeService] Ingredients (as JSON string): ${jsonEncode(ingredients)}");
    print("[RecipeService] Image path: $imagePath");

    try {
      final request = http.MultipartRequest('POST', uri);
      // Удаляем 'Content-Type' из headers для MultipartRequest, так как он устанавливается автоматически
      final multipartHeaders = Map<String, String>.from(headers);
      multipartHeaders.remove('Content-Type');
      request.headers.addAll(multipartHeaders);

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['instructions'] = instructions;
      request.fields['cooking_time_minutes'] = cookingTimeMinutes.toString();
      request.fields['servings'] = servings.toString();
      request.fields['is_active'] = isActive.toString();
      request.fields['is_private'] = isPrivate.toString();
      
      request.fields['ingredients'] = jsonEncode(ingredients);

      if (imagePath != null && imagePath.isNotEmpty) {
         final file = File(imagePath);
         if (await file.exists()) {
            request.files.add(await http.MultipartFile.fromPath(
                'image', 
                imagePath
            ));
            print("[RecipeService] Added image file to request.");
         } else {
            print("[RecipeService] Warning: Image file not found at path: $imagePath");
         }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30)); 

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
          print("[RecipeService] Recipe created successfully (201).");
          return Recipe.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      } else {
          print('Failed to create recipe. Status: ${response.statusCode}, Body: ${response.body}');
          String errorMessage = 'Failed to create recipe. Server responded with ${response.statusCode}.';
           try {
             final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
              if (errorBody is Map) {
                 errorMessage += ' Details: ${errorBody.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
              } else {
                 errorMessage += ' Body: ${utf8.decode(response.bodyBytes)}';
              }
           } catch (_) { errorMessage += ' Body: ${utf8.decode(response.bodyBytes)}'; }
          throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error creating recipe: $e');
      throw Exception('Error sending create recipe request: $e');
    }
  }

  // PUT /v1/recipe/recipe/{id}/
  Future<Recipe> updateRecipe(int id, Map<String, dynamic> recipeData) async {
      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/v1/recipe/recipe/$id/');
      final body = jsonEncode(recipeData);

      try {
          final response = await http.put(uri, headers: headers, body: body);

          if (response.statusCode == 200) {
              return Recipe.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
          } else {
              print('Failed to update recipe $id. Status: ${response.statusCode}, Body: ${response.body}');
              throw Exception('Failed to update recipe $id. Status code: ${response.statusCode}');
          }
      } catch (e) {
          print('Error updating recipe $id: $e');
          throw Exception('Error updating recipe $id: $e');
      }
  }

  // PATCH /v1/recipe/recipe/{id}/
  Future<Recipe> patchRecipe(int id, Map<String, dynamic> recipePatchData) async {
      if (recipePatchData.isEmpty) {
          throw ArgumentError("No fields provided for patching recipe.");
      }
      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/v1/recipe/recipe/$id/');
      final body = jsonEncode(recipePatchData);

      try {
          final response = await http.patch(uri, headers: headers, body: body);

          if (response.statusCode == 200) {
              return Recipe.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
          } else {
              print('Failed to patch recipe $id. Status: ${response.statusCode}, Body: ${response.body}');
              throw Exception('Failed to patch recipe $id. Status code: ${response.statusCode}');
          }
      } catch (e) {
          print('Error patching recipe $id: $e');
          throw Exception('Error patching recipe $id: $e');
      }
  }

  // DELETE /v1/recipe/recipe/{id}/
  Future<void> deleteRecipe(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/recipe/$id/');

    try {
        final response = await http.delete(uri, headers: headers);

        if (response.statusCode == 204) {
            return;
        } else if (response.statusCode == 404) {
            print('Recipe $id not found for deletion. Status: ${response.statusCode}');
            throw Exception('Recipe not found');
        } else {
            print('Failed to delete recipe $id. Status: ${response.statusCode}, Body: ${response.body}');
            throw Exception('Failed to delete recipe $id. Status code: ${response.statusCode}');
        }
    } catch (e) {
        print('Error deleting recipe $id: $e');
        throw Exception('Error deleting recipe $id: $e');
    }
  }
} 