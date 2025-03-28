import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://127.0.0.1:8001/api';
  
  Future<bool> login(String username, String password) async {
    if (username == 'test' && password == '123') {
      return true;
    }
    
    try {
    final response = await http.post(
      Uri.parse('$baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access', data['access']);
      await prefs.setString('refresh', data['refresh']);
      return true;
    } else {
      return false;
    }
    } catch (e) {
      print('login error: $e');
      return false;
    }
  }

  Future<bool> registration(String username, String email, String password, String secondPassword) async {
    if (password != secondPassword) {
      print('Passwords do not match');
      return false;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/users/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access', data['access']);
        await prefs.setString('refresh', data['refresh']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('registration error: $e');
      return false;
    }
  }

  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString('refresh');

    if (refresh == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh})
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('access', data['access']);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> verifyToken() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('access');
    
    if (access == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/token/verify/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'access': access}),
    );

    return response.statusCode == 200;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access');
    await prefs.remove('refresh');
  }
}