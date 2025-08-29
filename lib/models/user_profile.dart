import 'company.dart';

class UserProfile {
  final int id;
  final String username;
  final String email;
  final ProfileData profile;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.profile,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      profile: ProfileData.fromJson(json['profile']),
    );
  }
}

class ProfileData {
  final Company company;
  final String role;
  final String roleDisplay;

  ProfileData({
    required this.company,
    required this.role,
    required this.roleDisplay,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      company: Company.fromJson(json['company']),
      role: json['role'],
      roleDisplay: json['role_display'],
    );
  }
}
