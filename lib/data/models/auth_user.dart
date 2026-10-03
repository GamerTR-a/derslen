import 'package:supabase_flutter/supabase_flutter.dart';

class LiseAuthUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'student', 'coach', 'parent', 'institution_admin', 'baskan', 'admin'
  final String? grade;
  final String? department;
  final int xp;
  final String? profilePhoto;
  final bool isAdmin;
  final String? institutionId;
  final String? institutionName;
  final String? phone;
  final int streakDays;
  final DateTime createdAt;

  const LiseAuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'student',
    this.grade,
    this.department,
    this.xp = 0,
    this.profilePhoto,
    this.isAdmin = false,
    this.institutionId,
    this.institutionName,
    this.phone,
    this.streakDays = 0,
    required this.createdAt,
  });

  bool get isBaskan => role == 'baskan' || isAdmin;
  bool get isCoach => role == 'coach' || role == 'koc';
  bool get isParent => role == 'parent' || role == 'veli';
  bool get isInstitutionAdmin => role == 'institution_admin' || role == 'admin';

  factory LiseAuthUser.fromProfileJson(User user, Map<String, dynamic> profileJson) {
    final role = profileJson['role'] as String? ?? 'student';
    final isAdminRole = role == 'admin' || role == 'institution_admin';
    return LiseAuthUser(
      id: user.id,
      name: profileJson['name'] as String? ?? user.email?.split('@').first ?? 'Kullanıcı',
      email: user.email ?? '',
      role: role,
      grade: profileJson['grade'] as String?,
      department: (profileJson['department'] is List)
          ? (profileJson['department'] as List).join(', ')
          : profileJson['department'] as String?,
      xp: profileJson['xp'] != null ? (profileJson['xp'] as num).toInt() : 0,
      profilePhoto: profileJson['profile_photo'] as String?,
      isAdmin: isAdminRole,
      institutionId: profileJson['institution_id'] as String?,
      institutionName: profileJson['institution_name'] as String?,
      phone: profileJson['phone'] as String?,
      streakDays: profileJson['streak_days'] != null ? (profileJson['streak_days'] as num).toInt() : 0,
      createdAt: profileJson['created_at'] != null
          ? DateTime.parse(profileJson['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'grade': grade,
      'department': department,
      'xp': xp,
      'profile_photo': profilePhoto,
      'is_admin': isAdmin,
      'institution_id': institutionId,
      'institution_name': institutionName,
      'phone': phone,
      'streak_days': streakDays,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LiseAuthUser.fromJson(Map<String, dynamic> json) {
    return LiseAuthUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      grade: json['grade'] as String?,
      department: json['department'] as String?,
      xp: json['xp'] != null ? (json['xp'] as num).toInt() : 0,
      profilePhoto: json['profile_photo'] as String?,
      isAdmin: json['is_admin'] as bool? ?? (json['role'] == 'admin'),
      institutionId: json['institution_id'] as String?,
      institutionName: json['institution_name'] as String?,
      phone: json['phone'] as String?,
      streakDays: json['streak_days'] != null ? (json['streak_days'] as num).toInt() : 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
