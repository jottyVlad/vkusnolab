import 'package:flutter/foundation.dart' show immutable;

@immutable
class UserProfile {
  final int id;
  final String username;
  final String? email;
  final String? bio;
  final String? profilePicture; 

  const UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.bio,
    this.profilePicture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      profilePicture: json['profile_picture'] as String?,
    );
  }


  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id, 
      'username': username,
    };
    if (email != null) map['email'] = email;
    if (bio != null) map['bio'] = bio;

    return map;
  }
} 