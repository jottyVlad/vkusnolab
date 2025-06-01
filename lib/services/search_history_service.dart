import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vkusnolab/services/auth_service.dart';
import 'package:vkusnolab/models/user_profile.dart'; 

const String _searchHistoryBaseUrl = 'http://77.110.103.162/api'; 

class SearchHistory {
  final String? createdAt; 
  final String text;
  final UserProfile? user; 

  SearchHistory({
    this.createdAt,
    required this.text,
    this.user,
  });

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      createdAt: json['created_at'] as String?,
      text: json['text'] as String? ?? '',
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
}

class SearchHistoryService {
  final String _endpoint = '/v1/recipe/search_history/';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw AuthException('Не удалось получить токен доступа. Войдите снова.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<SearchHistory>> getSearchHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_searchHistoryBaseUrl$_endpoint'), 
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<SearchHistory> history = body
            .map((dynamic item) => SearchHistory.fromJson(item as Map<String, dynamic>))
            .toList();
        return history;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException('Доступ запрещен. Пожалуйста, войдите снова (${response.statusCode})');
      } else {
        print("getSearchHistory failed: ${response.statusCode} ${response.body}");
        throw Exception('Не удалось загрузить историю поиска: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Ошибка сети при получении истории поиска. Проверьте ваше интернет-соединение.');
    } on AuthException { 
      rethrow;
    } catch (e) {
      print('getSearchHistory error: $e');
      throw Exception('Произошла непредвиденная ошибка при получении истории поиска.');
    }
  }

  Future<SearchHistory> saveSearchQuery(String text) async {
     if (text.isEmpty || text.length > 100) {
       throw ArgumentError('Текст поискового запроса должен содержать от 1 до 100 символов.');
     }

     final requestBody = jsonEncode(SearchHistory(text: text).toJson());
     print("[SearchHistoryService] Saving search query: $text, Body: $requestBody");

     try {
        final headers = await _getHeaders();

        final response = await http.post(
          Uri.parse('$_searchHistoryBaseUrl$_endpoint'), 
          headers: headers,
          body: requestBody,
        ).timeout(const Duration(seconds: 10));

        print("[SearchHistoryService] Save search query response: ${response.statusCode}, Body: ${response.body}");

        if (response.statusCode == 201) {
          return SearchHistory.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
        } else if (response.statusCode == 400) {
           final errorBody = utf8.decode(response.bodyBytes);
           print("saveSearchQuery bad request (400): $errorBody");
           throw Exception('Неверные данные для сохранения истории поиска (400): $errorBody');
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException('Доступ запрещен. Пожалуйста, войдите снова (${response.statusCode})');
        } else {
          print("saveSearchQuery failed: ${response.statusCode} ${response.body}");
          throw Exception('Не удалось сохранить историю поиска: ${response.statusCode}');
        }
     } on SocketException {
        throw Exception('Ошибка сети при сохранении истории поиска. Проверьте ваше интернет-соединение.');
     } on AuthException {
        rethrow;
     } catch (e) {
        print('saveSearchQuery error: $e');
        throw Exception('Произошла непредвиденная ошибка при сохранении истории поиска.');
     }
  }
} 