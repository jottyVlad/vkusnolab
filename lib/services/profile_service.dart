import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class Profile {
  final int id;
  final String username;
  final String email;
  final String bio;
  final String? profilePicture;

  Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.bio,
    this.profilePicture,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profilePicture: json['profile_picture'] as String?,
    );
  }
}

class ProfileService {
  final String _baseUrl = 'http://77.110.103.162/api/v1/profiles/me/';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Profile> getMe() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(_baseUrl), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Profile.fromJson(data);
    } else {
      throw Exception('Не удалось получить профиль пользователя');
    }
  }

  Future<Profile> patchMe({String? email, String? bio}) async {
    final headers = await _getHeaders();
    final body = jsonEncode({
      if (email != null) 'email': email,
      if (bio != null) 'bio': bio,
    });
    final response = await http.patch(Uri.parse(_baseUrl), headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Profile.fromJson(data);
    } else {
      throw Exception('Не удалось обновить профиль');
    }
  }

  Future<Profile> uploadProfilePicture(File image) async {
    final token = await _authService.getAccessToken();
    final uri = Uri.parse(_baseUrl);
    final request = http.MultipartRequest('PATCH', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('profile_picture', image.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Profile.fromJson(data);
    } else {
      throw Exception('Не удалось загрузить фото профиля');
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final headers = await _getHeaders();
    final body = jsonEncode({
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    final response = await http.patch(Uri.parse(_baseUrl), headers: headers, body: body);
    if (response.statusCode == 200) {
      return;
    } else {
      String msg = 'Не удалось сменить пароль';
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map) {
          if (data['detail'] != null) {
            msg = data['detail'].toString();
          } else {
            msg = data.entries.map((e) => "${e.key}: ${e.value}").join("\n");
          }
        }
      } catch (e) {
        msg += '\n' + e.toString();
      }
      throw Exception(msg);
    }
  }
} 