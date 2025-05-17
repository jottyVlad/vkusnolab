import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vkusnolab/services/auth_service.dart'; 
import '../models/comment.dart';


class CommentService {
  final String _baseUrl = 'http://77.110.103.162/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _authService.getAccessToken();
    if (token == null) {
      print("Warning: No auth token found for CommentService request.");
      return {
        'Content-Type': 'application/json; charset=UTF-8',
      };
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', 
    };
  }

  // GET /v1/recipe/comments/
  Future<List<Comment>> getComments(int recipeId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/comments/') 
        .replace(queryParameters: {'recipe': recipeId.toString()});

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<Comment> comments = body
            .map((dynamic item) => Comment.fromJson(item as Map<String, dynamic>))
            .toList();
        return comments;
      } else {
        print('Failed to load comments. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load comments. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      throw Exception('Error fetching comments: $e');
    }
  }

  // GET /v1/recipe/comments/{id}/
  Future<Comment> getComment(int commentId) async {
    final headers = await _getHeaders();

    final uri = Uri.parse('$_baseUrl/v1/recipe/comments/$commentId/');

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      } else {
        print('Failed to load comment $commentId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load comment $commentId. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching comment $commentId: $e');
      throw Exception('Error fetching comment $commentId: $e');
    }
  }

  // POST /v1/recipe/comments/
  Future<Comment> createComment(int recipeId, String commentText) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/comments/');
 
    const String placeholderUsername = "testuser";

    final body = jsonEncode(<String, dynamic>{
      'recipe': recipeId,
      'comment_text': commentText,
      'author': {
          'username': placeholderUsername 

      }
    });

    print("[CommentService] Posting comment with body: $body"); 

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
            return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
        } catch (e) {
            print('Error decoding create comment response: $e. Body: ${response.body}');
            throw Exception('Failed to parse server response after creating comment.');
        }
      } else {
        print('Failed to create comment. Status: ${response.statusCode}, Body: ${response.body}');
        String errorMessage = 'Failed to create comment. Server responded with ${response.statusCode}.';
        try {
           final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
           if (errorBody is Map && errorBody.containsKey('detail')) {
               errorMessage += ' Details: ${errorBody['detail']}';
           } else if (errorBody is Map) {
              errorMessage += ' Details: ${errorBody.values.join(', ')}';
           }
        } catch (_) {  }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error creating comment: $e');
      throw Exception('Error sending comment: $e');
    }
  }

  // PUT /v1/recipe/comments/{id}/
  Future<Comment> updateComment(int commentId, int recipeId, String commentText) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/comments/$commentId/');

    final body = jsonEncode(<String, dynamic>{
      'recipe': recipeId,
      'comment_text': commentText,
    });

    try {
      final response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      } else {
        print('Failed to update comment $commentId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to update comment $commentId. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating comment $commentId: $e');
      throw Exception('Error updating comment $commentId: $e');
    }
  }

  // PATCH /v1/recipe/comments/{id}/
  Future<Comment> patchComment(int commentId, {int? recipeId, String? commentText}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/comments/$commentId/'); 

    final bodyMap = <String, dynamic>{};
    if (recipeId != null) bodyMap['recipe'] = recipeId;
    if (commentText != null) bodyMap['comment_text'] = commentText;

    if (bodyMap.isEmpty) {
      throw ArgumentError("No fields provided for patching comment.");
    }

    final body = jsonEncode(bodyMap);

    try {
      final response = await http.patch(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      } else {
        print('Failed to patch comment $commentId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to patch comment $commentId. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error patching comment $commentId: $e');
      throw Exception('Error patching comment $commentId: $e');
    }
  }

  // DELETE /v1/recipe/comments/{id}/
  Future<void> deleteComment(int commentId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_baseUrl/v1/recipe/comments/$commentId/');

    try {
      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        print('Comment $commentId not found for deletion. Status: ${response.statusCode}');
        throw Exception('Comment not found');
      } else {
        print('Failed to delete comment $commentId. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to delete comment $commentId. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting comment $commentId: $e');
      throw Exception('Error deleting comment $commentId: $e');
    }
  }
} 