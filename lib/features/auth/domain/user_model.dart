/// User model – maps to public.users table
class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String? mobileNumber;
  final String? profilePhotoUrl;
  final String role; // 'user', 'admin'
  final bool isBanned;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.mobileNumber,
    this.profilePhotoUrl,
    this.role = 'user',
    this.isBanned = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] ?? '',
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      mobileNumber: map['mobile_number'],
      profilePhotoUrl: map['profile_photo_url'],
      role: map['role'] ?? 'user',
      isBanned: map['is_banned'] ?? false,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'mobile_number': mobileNumber,
      'profile_photo_url': profilePhotoUrl,
      'role': role,
      'is_banned': isBanned,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? mobileNumber,
    String? profilePhotoUrl,
    String? role,
    bool? isBanned,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAdmin => role == 'admin';

  factory UserModel.empty() {
    return UserModel(
      userId: '',
      fullName: '',
      email: '',
      isBanned: false,
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'UserModel(userId: $userId, fullName: $fullName, email: $email, role: $role)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
