import 'dart:convert';
import 'dart:io'; // Для SocketException
import 'package:http/http.dart' as http;
import 'package:vkusnolab/auth_service.dart'; // Импорт AuthService и AuthException

const String _baseUrl = 'http://77.110.103.162/api'; 

// TODO: Скорректировать модель в соответствии с реальной схемой API
class SearchHistory {
  final int? id; // Может быть null при создании новой записи
  final String text;
  // Возможно, есть другие поля, такие как timestamp

  SearchHistory({this.id, required this.text});

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'] as int?, // Убедитесь, что тип правильный
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    // Не включаем id при создании новой записи
    return {
      'text': text,
    };
  }
}

class SearchHistoryService {
  // Используем конечный путь без слеша в начале, так как он добавляется в Uri.parse
  final String _endpoint = '/v1/recipe/search_history/'; 
  final AuthService _authService = AuthService(); // Экземпляр AuthService

  // Приватный метод для получения заголовков с токеном
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

  // Получение истории поиска
  Future<List<SearchHistory>> getSearchHistory() async {
    try {
      final headers = await _getHeaders(); // Получаем заголовки
      final response = await http.get(
        // Формируем полный URL
        Uri.parse('$_baseUrl$_endpoint'), 
        headers: headers, // Используем заголовки с токеном
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<SearchHistory> history = body
            .map((dynamic item) => SearchHistory.fromJson(item as Map<String, dynamic>))
            .toList();
        return history;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Ошибка авторизации или доступа
        throw AuthException('Доступ запрещен. (${response.statusCode})');
      } else {
        // Другие ошибки сервера
        throw Exception('Не удалось загрузить историю поиска: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Ошибка сети при получении истории поиска.');
    } on AuthException { 
      rethrow; // Перебрасываем AuthException
    } catch (e) {
      print('getSearchHistory error: $e');
      throw Exception('Произошла ошибка при получении истории поиска: $e');
    }
  }

  // Сохранение запроса в историю
  Future<SearchHistory> saveSearchQuery(String text) async {
     final newHistoryEntry = SearchHistory(text: text);
     final requestBody = jsonEncode(newHistoryEntry.toJson()); // Кодируем тело заранее для лога
     
     try {
        final headers = await _getHeaders(); // Получаем заголовки

        // --- Логирование --- 
        print('--- Sending Search History Request ---');
        print('URL: ${_baseUrl}${_endpoint}');
        print('Headers: $headers');
        print('Body: $requestBody');
        print('-------------------------------------');
        // --- Конец логирования ---

        final response = await http.post(
          Uri.parse('$_baseUrl$_endpoint'), 
          headers: headers, // Используем заголовки с токеном
          body: requestBody, // Используем заранее подготовленное тело
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 201) {
          // Декодируем ответ для получения созданной записи (с id)
          return SearchHistory.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
        } else if (response.statusCode == 400) {
           throw Exception('Неверные данные для сохранения истории поиска (400).');
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException('Доступ запрещен. (${response.statusCode})');
        } else {
          // Другие ошибки сервера
          throw Exception('Не удалось сохранить историю поиска: ${response.statusCode}');
        }
     } on SocketException {
        throw Exception('Ошибка сети при сохранении истории поиска.');
     } on AuthException {
        rethrow; // Перебрасываем AuthException
     } catch (e) {
        print('saveSearchQuery error: $e');
        throw Exception('Произошла ошибка при сохранении истории поиска: $e');
     }
  }

  // TODO: Реализовать метод удаления истории, если он нужен
  // Future<void> deleteSearchHistory(...) async { ... } 
} 