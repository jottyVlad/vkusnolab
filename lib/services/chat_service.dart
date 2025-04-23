import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vkusnolab/auth_service.dart'; // Для получения токена и AuthException

// TODO: Убедитесь, что базовый URL правильный
const String _chatBaseUrl = 'http://77.110.103.162/api/v1/chat'; 

// TODO: Скорректируйте модель в соответствии с реальной схемой API из #/definitions/ChatHistory
class ChatHistory {
  final int? id; // Может быть null при создании
  final String message;
  final String senderType; // 'user' или 'AI'
  final DateTime? createdAt; // Переименовано с timestamp на createdAt

  ChatHistory({
    this.id,
    required this.message,
    required this.senderType,
    this.createdAt, // Переименовано
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    // Отладочный вывод для конкретного объекта JSON
    // print('Parsing JSON item: $json'); 
    try {
      return ChatHistory(
        id: json['id'] as int?,
        // Используем ?? для защиты от null (хотя вы говорите, что их нет)
        message: (json['text'] ?? '') as String, // Используем 'text' как в Swagger
        senderType: (json['sender_type'] ?? 'unknown') as String, 
        // Читаем и парсим 'created_at' из API
        createdAt: json['created_at'] != null && json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
    } catch (e) {
       print('Error parsing JSON item: $json');
       print('Error details: $e');
       // Перебрасываем ошибку, чтобы она была видна выше
       rethrow; 
    }
  }

  Map<String, dynamic> toJson() {
    // Включаем только необходимые поля для отправки нового сообщения
    return {
      'text': message,
      'sender_type': senderType,
      // id и createdAt обычно устанавливаются сервером
    };
  }
}

class ChatService {
  final AuthService _authService = AuthService(); // Для получения токена

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

  // Получение всей истории чата
  Future<List<ChatHistory>> getChatHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_chatBaseUrl/chat_history/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) {
          // Выводим каждый элемент перед парсингом
          print('Processing item from API: $item'); 
          // Добавляем проверку, что item это действительно Map
          if (item is Map<String, dynamic>) {
             return ChatHistory.fromJson(item);
          } else {
             // Если элемент не Map, выводим ошибку и пропускаем его
             print('Skipping invalid item: item is not a Map<String, dynamic>');
             // Возвращаем null или выбрасываем исключение, 
             // в зависимости от того, как хотим обрабатывать невалидные данные.
             // Пока просто вернем null, чтобы не падать, но надо будет отфильтровать.
             return null; 
          }
        })
        // Отфильтровываем возможные null, если были ошибки парсинга отдельных элементов
        .where((history) => history != null)
        .cast<ChatHistory>() // Приводим к нужному типу после фильтрации
        .toList();
      } else if (response.statusCode == 403) {
        throw AuthException('Доступ запрещен (403).');
      } else {
        throw Exception('Не удалось загрузить историю чата: ${response.statusCode}');
      }
    } on SocketException {
       throw Exception('Ошибка сети при получении истории чата.');
    } on AuthException { // Перебрасываем AuthException
        rethrow;
    } catch (e) {
      print('getChatHistory error: $e');
      throw Exception('Произошла ошибка при получении истории чата: $e');
    }
  }

  // Отправка сообщения пользователя
  // Возвращает bool успеха, так как ответ AI получаем через getChatHistory()
  Future<void> sendMessage(String message) async {
     final newMessage = ChatHistory(message: message, senderType: 'user');
     
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_chatBaseUrl/chat_history/'),
        headers: headers,
        body: jsonEncode(newMessage.toJson()),
      ).timeout(const Duration(seconds: 20)); // Таймаут для потенциальной обработки AI

      if (response.statusCode == 201) {
        // Успешно создана запись сообщения пользователя на сервере.
        // Ответ AI будет получен при следующем вызове getChatHistory().
        return; 
      } else if (response.statusCode == 400) {
         throw Exception('Неверные данные сообщения (400).');
      } else if (response.statusCode == 403) {
         throw AuthException('Доступ запрещен (403).');
      } else {
        throw Exception('Не удалось отправить сообщение: ${response.statusCode}');
      }
    } on SocketException {
       throw Exception('Ошибка сети при отправке сообщения.');
    } on AuthException {
        rethrow;
    } catch (e) {
      print('sendMessage error: $e');
      throw Exception('Произошла ошибка при отправке сообщения: $e');
    }
  }

  // Очистка истории чата
  Future<void> clearHistory() async {
    try {
      final headers = await _getHeaders();
      // API использует GET для очистки, что не стандартно, но следуем описанию
      final response = await http.get( 
        Uri.parse('$_chatBaseUrl/chat_history/clear_history/'), 
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      // В описании указан ответ 200 с []
      if (response.statusCode == 200) {
         // История успешно очищена
         return;
      } else if (response.statusCode == 403) {
         throw AuthException('Доступ запрещен (403).');
      } else {
         throw Exception('Не удалось очистить историю: ${response.statusCode}');
      }
    } on SocketException {
       throw Exception('Ошибка сети при очистке истории.');
    } on AuthException {
       rethrow;
    } catch (e) {
      print('clearHistory error: $e');
      throw Exception('Произошла ошибка при очистке истории: $e');
    }
  }

  // --- Метод для получения только сообщений AI (если понадобится) ---
  // Future<List<ChatHistory>> getAiMessages() async { ... } 
} 