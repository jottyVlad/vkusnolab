import 'dart:convert';
import 'dart:io'; 
import 'package:http/http.dart' as http;
import 'package:vkusnolab/auth_service.dart'; 

const String _baseUrl = 'http://77.110.103.162/api'; 

class SearchHistory {
  final int? id; 
  final String text;

  SearchHistory({this.id, required this.text});

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'] as int?, 
      text: json['text'] as String,
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
        Uri.parse('$_baseUrl$_endpoint'), 
        headers: headers, 
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<SearchHistory> history = body
            .map((dynamic item) => SearchHistory.fromJson(item as Map<String, dynamic>))
            .toList();
        return history;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException('Доступ запрещен. (${response.statusCode})');
      } else {
        throw Exception('Не удалось загрузить историю поиска: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Ошибка сети при получении истории поиска.');
    } on AuthException { 
      rethrow; 
    } catch (e) {
      print('getSearchHistory error: $e');
      throw Exception('Произошла ошибка при получении истории поиска: $e');
    }
  }

  Future<SearchHistory> saveSearchQuery(String text) async {
     final newHistoryEntry = SearchHistory(text: text);
     final requestBody = jsonEncode(newHistoryEntry.toJson()); 
     
     try {
        final headers = await _getHeaders(); 

        final response = await http.post(
          Uri.parse('$_baseUrl$_endpoint'), 
          headers: headers, 
          body: requestBody, 
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 201) {
          return SearchHistory.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
        } else if (response.statusCode == 400) {
           throw Exception('Неверные данные для сохранения истории поиска (400).');
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException('Доступ запрещен. (${response.statusCode})');
        } else {
          throw Exception('Не удалось сохранить историю поиска: ${response.statusCode}');
        }
     } on SocketException {
        throw Exception('Ошибка сети при сохранении истории поиска.');
     } on AuthException {
        rethrow; 
     } catch (e) {
        print('saveSearchQuery error: $e');
        throw Exception('Произошла ошибка при сохранении истории поиска: $e');
     }
  } 
} 