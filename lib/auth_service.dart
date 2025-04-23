import 'dart:convert';
import 'dart:io'; // Для PlatformException

import 'package:flutter/services.dart'; // Для PlatformException
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// TODO: Настроить baseUrl через переменные окружения (--dart-define) или конфигурационный файл
const String _baseUrl = 'http://77.110.103.162/api'; 

// Пользовательское исключение для ошибок аутентификации/регистрации
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  // final String baseUrl = 'http://127.0.0.1:8001/api'; // Заменено константой _baseUrl
  final _storage = FlutterSecureStorage();
  final String _accessKey = 'access';
  final String _refreshKey = 'refresh';

  // Вспомогательная функция для получения токена
  Future<String?> _getToken(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      // Обработка возможных ошибок FlutterSecureStorage (например, на Web)
      print('Error reading token from secure storage: $e');
      return null;
    }
  }

  // Вспомогательная функция для сохранения токена
  Future<void> _saveToken(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      // Обработка возможных ошибок FlutterSecureStorage
      print('Error saving token to secure storage: $e');
      throw AuthException('Не удалось безопасно сохранить данные сессии.');
    }
  }

  // Вспомогательная функция для удаления токена
  Future<void> _deleteToken(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e) {
      // Обработка возможных ошибок FlutterSecureStorage
      print('Error deleting token from secure storage: $e');
      // Не выбрасываем исключение здесь, так как это часть logout
    }
  }
  
  Future<void> login(String username, String password) async { // Изменен тип возвращаемого значения на Future<void>
    // if (username == 'test' && password == '123') { // Убрана тестовая заглушка
    //   await _saveToken(_accessKey, 'fake_access_token'); 
    //   await _saveToken(_refreshKey, 'fake_refresh_token');
    //   return;
    // }
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10)); // Добавлен таймаут

      if (response.statusCode == 200 || response.statusCode == 201) { // Проверяем 200 или 201 (200 для djangorestframework-simplejwt < 5.0)
        final data = jsonDecode(utf8.decode(response.bodyBytes)); // Декодируем с utf8
        if (data['access'] != null && data['refresh'] != null) {
            await _saveToken(_accessKey, data['access']);
            await _saveToken(_refreshKey, data['refresh']);
            return; // Успех
        } else {
           throw AuthException('Некорректный ответ от сервера.');
        }
      } else if (response.statusCode == 401) {
        throw AuthException('Неверный логин или пароль.');
      } else {
        throw AuthException('Ошибка входа: ${response.statusCode}. ${response.body}');
      }
    } on SocketException {
       throw AuthException('Ошибка сети. Проверьте подключение к интернету.');
    } on http.ClientException catch (e) {
       throw AuthException('Ошибка клиента: $e');
    } catch (e) {
      print('login error: $e');
      if (e is AuthException) rethrow; // Перебрасываем AuthException
      throw AuthException('Произошла неизвестная ошибка при входе.');
    }
  }

  Future<void> registration(String username, String email, String password, String secondPassword) async { // Изменен тип возвращаемого значения
    if (password != secondPassword) {
      throw AuthException('Пароли не совпадают.'); // Выбрасываем исключение
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/users/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // Проверяем, возвращает ли регистрация токены (зависит от бэкенда)
        if (data['access'] != null && data['refresh'] != null) { 
           await _saveToken(_accessKey, data['access']);
           await _saveToken(_refreshKey, data['refresh']);
        } else {
           // Если токены не возвращаются, возможно, нужно будет вызвать login после регистрации
           print('Registration successful, but tokens not returned in response. User might need to login.');
           // Если ваш API не возвращает токены при регистрации, удалите строки _saveToken выше
           // и обработайте это в UI (например, перенаправьте на страницу входа).
        }
        return; // Успех
      } else {
         // Попытка разобрать ошибку от Django Rest Framework
         String errorMessage = 'Ошибка регистрации: ${response.statusCode}.';
         try {
             final errors = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
             // Формируем сообщение из ошибок валидации
             errorMessage += ' ' + errors.entries.map((e) => '${e.key}: ${e.value is List ? e.value.join(', ') : e.value}').join('; ');
         } catch (_) {
             errorMessage += ' ' + response.body; // Если не JSON, показываем тело ответа
         }
         throw AuthException(errorMessage);
      }
    } on SocketException {
       throw AuthException('Ошибка сети. Проверьте подключение к интернету.');
    } on http.ClientException catch (e) {
       throw AuthException('Ошибка клиента: $e');
    } catch (e) {
      print('registration error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Произошла неизвестная ошибка при регистрации.');
    }
  }

  Future<bool> refreshToken() async { // Оставляем bool для простоты использования в интерцепторе
    final refresh = await _getToken(_refreshKey); 

    if (refresh == null) return false;

    try {
        final response = await http.post(
          Uri.parse('$_baseUrl/token/refresh/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refresh})
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) { // Проверяем 200 или 201
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['access'] != null) {
             await _saveToken(_accessKey, data['access']);
             return true;
          } else {
             print('Refresh token success, but no access token in response.');
             return false; // Не удалось получить новый токен
          }
        } else {
          print('Refresh token failed: ${response.statusCode}');
          await logout(); // Если refresh не удался, разлогиниваем
          return false;
        }
    } on SocketException {
       print('Network error during token refresh.');
       return false; // Не удалось обновить из-за сети
    } catch (e) {
        print('refreshToken error: $e');
        await logout(); // Разлогиниваем при любой ошибке обновления
        return false;
    }
  }

  Future<bool> verifyToken() async { // Оставляем bool для быстрой проверки
    final access = await _getToken(_accessKey);
    
    if (access == null) return false;

    try {
        final response = await http.post(
          Uri.parse('$_baseUrl/token/verify/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': access}),
        ).timeout(const Duration(seconds: 5));

        return response.statusCode == 200; // Verify возвращает 200 OK
    } catch (e) {
      print('verifyToken error: $e');
      return false; // Ошибка при проверке или таймаут
    }
  }

  Future<void> logout() async {
    // Возможно, нужно добавить вызов API для инвалидации refresh токена на бэкенде
    await _deleteToken(_accessKey);
    await _deleteToken(_refreshKey);
  }

  // Метод для получения текущего access токена (может понадобиться для HTTP-клиента)
  Future<String?> getAccessToken() async {
    return await _getToken(_accessKey);
  }
}