import 'package:flutter/foundation.dart' show immutable;
import 'user_profile.dart';

@immutable
class Comment {
  final int? id; 
  final int recipeId;
  final DateTime createdAt;
  final String commentText;
  final UserProfile author;

  const Comment({
    this.id,
    required this.recipeId,
    required this.createdAt,
    required this.commentText,
    required this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int?, 
      recipeId: json['recipe'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      commentText: json['comment_text'] as String,
      author: UserProfile.fromJson(json['author'] as Map<String, dynamic>),
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'recipe': recipeId,
      'comment_text': commentText,
      'author': author.toJson(),
    };
  }
} 