import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vkusnolab/services/auth_service.dart'; 

const String _chatBaseUrl = 'http://77.110.103.162/api/v1/chat'; 

class ChatHistory {
  final int? id; 
  final String message;
  final String senderType; 
  final DateTime? createdAt; 

  ChatHistory({
    this.id,
    required this.message,
    required this.senderType,
    this.createdAt, 
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    try {
      return ChatHistory(
        id: json['id'] as int?,
        message: (json['text'] ?? '') as String, 
        senderType: (json['sender_type'] ?? 'unknown') as String, 
        createdAt: json['created_at'] != null && json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
    } catch (e) {
       print('Error parsing JSON item: $json');
       print('Error details: $e');
       rethrow; 
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'text': message,
      'sender_type': senderType,
    };
  }
}

class ChatService {
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
          print('Processing item from API: $item'); 
          if (item is Map<String, dynamic>) {
             return ChatHistory.fromJson(item);
          } else {
             print('Skipping invalid item: item is not a Map<String, dynamic>');
             return null; 
          }
        })
        .where((history) => history != null)
        .cast<ChatHistory>() 
        .toList();
      } else if (response.statusCode == 403) {
        throw AuthException('Доступ запрещен (403).');
      } else {
        throw Exception('Не удалось загрузить историю чата: ${response.statusCode}');
      }
    } on SocketException {
       throw Exception('Ошибка сети при получении истории чата.');
    } on AuthException { 
        rethrow;
    } catch (e) {
      print('getChatHistory error: $e');
      throw Exception('Произошла ошибка при получении истории чата: $e');
    }
  }

  Future<void> sendMessage(String message) async {
     final newMessage = ChatHistory(message: message, senderType: 'user');
     
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_chatBaseUrl/chat_history/'),
        headers: headers,
        body: jsonEncode(newMessage.toJson()),
      ).timeout(const Duration(seconds: 20)); 

      if (response.statusCode == 201) {
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

  Future<void> clearHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get( 
        Uri.parse('$_chatBaseUrl/chat_history/clear_history/'), 
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
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
} 