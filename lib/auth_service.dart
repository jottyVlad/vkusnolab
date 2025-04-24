import 'dart:convert';
import 'dart:io'; 

import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _baseUrl = 'http://77.110.103.162/api'; 

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final _storage = FlutterSecureStorage();
  final String _accessKey = 'access';
  final String _refreshKey = 'refresh';

  Future<String?> _getToken(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      print('Error reading token from secure storage: $e');
      return null;
    }
  }

  Future<void> _saveToken(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      print('Error saving token to secure storage: $e');
      throw AuthException('Не удалось безопасно сохранить данные сессии.');
    }
  }

  Future<void> _deleteToken(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e) {
      print('Error deleting token from secure storage: $e');
    }
  }
  
  Future<void> login(String username, String password) async { 
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10)); 

      if (response.statusCode == 200 || response.statusCode == 201) { 
        final data = jsonDecode(utf8.decode(response.bodyBytes)); 
        if (data['access'] != null && data['refresh'] != null) {
            await _saveToken(_accessKey, data['access']);
            await _saveToken(_refreshKey, data['refresh']);
            return; 
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
      if (e is AuthException) rethrow; 
      throw AuthException('Произошла неизвестная ошибка при входе.');
    }
  }

  Future<void> registration(String username, String email, String password, String secondPassword) async { 
    if (password != secondPassword) {
      throw AuthException('Пароли не совпадают.'); 
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/users/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        print('User registration successful on server for username: $username');
        return;
      } else {
         String errorMessage = 'Ошибка регистрации: ${response.statusCode}.';
         try {
             final errors = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
             errorMessage += ' ' + errors.entries.map((e) => '${e.key}: ${e.value is List ? e.value.join(', ') : e.value}').join('; ');
         } catch (_) {
             errorMessage += ' ' + response.body; 
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

  Future<bool> refreshToken() async { 
    final refresh = await _getToken(_refreshKey); 

    if (refresh == null) return false;

    try {
        final response = await http.post(
          Uri.parse('$_baseUrl/token/refresh/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refresh})
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) { 
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['access'] != null) {
             await _saveToken(_accessKey, data['access']);
             return true;
          } else {
             print('Refresh token success, but no access token in response.');
             return false; 
          }
        } else {
          print('Refresh token failed: ${response.statusCode}');
          await logout(); 
          return false;
        }
    } on SocketException {
       print('Network error during token refresh.');
       return false; 
    } catch (e) {
        print('refreshToken error: $e');
        await logout(); 
        return false;
    }
  }

  Future<bool> verifyToken() async { 
    final access = await _getToken(_accessKey);
    
    if (access == null) return false;

    try {
        final response = await http.post(
          Uri.parse('$_baseUrl/token/verify/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': access}),
        ).timeout(const Duration(seconds: 5));

        return response.statusCode == 200; 
    } catch (e) {
      print('verifyToken error: $e');
      return false; 
    }
  }

  Future<void> logout() async {
    await _deleteToken(_accessKey);
    await _deleteToken(_refreshKey);
  }

  Future<String?> getAccessToken() async {
    return await _getToken(_accessKey);
  }
}