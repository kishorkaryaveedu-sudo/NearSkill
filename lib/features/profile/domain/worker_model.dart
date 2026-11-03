/// WorkerProfileModel – maps to public.worker_profiles table
/// fullName comes from joining public.users when available.
class WorkerProfileModel {
  final String workerId;
  final String userId;
  final String? profilePhotoUrl;
  final int experienceYears;
  final double hourlyRate;
  final bool availabilityStatus;
  final double currentLatitude;
  final double currentLongitude;
  final double averageRating;
  final String verificationStatus; // pending | verified | rejected
  final String? idCardUrl;
  final String? idCardType;
  final String? verificationNotes;
  final String? fullName; // from users table join

  const WorkerProfileModel({
    required this.workerId,
    required this.userId,
    this.profilePhotoUrl,
    this.experienceYears = 0,
    this.hourlyRate = 0,
    this.availabilityStatus = true,
    this.currentLatitude = 0,
    this.currentLongitude = 0,
    this.averageRating = 0,
    this.verificationStatus = 'pending',
    this.idCardUrl,
    this.idCardType,
    this.verificationNotes,
    this.fullName,
  });

  factory WorkerProfileModel.fromMap(Map<String, dynamic> map) {
    // fullName can come from a nested 'users' object (join) or directly
    String? name;
    if (map['users'] is Map) {
      name = (map['users'] as Map)['full_name'] as String?;
    } else {
      name = map['full_name'] as String?;
    }

    return WorkerProfileModel(
      workerId: map['worker_id'] ?? '',
      userId: map['user_id'] ?? '',
      profilePhotoUrl: map['profile_photo_url'],
      experienceYears: map['experience_years'] ?? 0,
      hourlyRate: (map['hourly_rate'] ?? 0).toDouble(),
      availabilityStatus: map['availability_status'] ?? true,
      currentLatitude: (map['current_latitude'] ?? 0).toDouble(),
      currentLongitude: (map['current_longitude'] ?? 0).toDouble(),
      averageRating: (map['average_rating'] ?? 0).toDouble(),
      verificationStatus: map['verification_status'] ?? 'pending',
      idCardUrl: map['id_card_url'],
      idCardType: map['id_card_type'],
      verificationNotes: map['verification_notes'],
      fullName: name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'worker_id': workerId,
      'user_id': userId,
      'profile_photo_url': profilePhotoUrl,
      'experience_years': experienceYears,
      'hourly_rate': hourlyRate,
      'availability_status': availabilityStatus,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'average_rating': averageRating,
      'verification_status': verificationStatus,
      'id_card_url': idCardUrl,
      'id_card_type': idCardType,
      'verification_notes': verificationNotes,
    };
  }

  WorkerProfileModel copyWith({
    String? workerId,
    String? userId,
    String? profilePhotoUrl,
    int? experienceYears,
    double? hourlyRate,
    bool? availabilityStatus,
    double? currentLatitude,
    double? currentLongitude,
    double? averageRating,
    String? verificationStatus,
    String? idCardUrl,
    String? idCardType,
    String? verificationNotes,
    String? fullName,
  }) {
    return WorkerProfileModel(
      workerId: workerId ?? this.workerId,
      userId: userId ?? this.userId,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      experienceYears: experienceYears ?? this.experienceYears,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      averageRating: averageRating ?? this.averageRating,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      idCardType: idCardType ?? this.idCardType,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      fullName: fullName ?? this.fullName,
    );
  }

  bool get isVerified => verificationStatus == 'verified';
  bool get hasIdCard => idCardUrl != null && idCardUrl!.isNotEmpty;

  /// Display name: uses fullName if available, falls back to short ID
  String get displayName => fullName ?? 'Worker #${workerId.substring(0, 6)}';

  String get formattedRate => '₹${hourlyRate.toStringAsFixed(0)}/hr';

  @override
  String toString() =>
      'WorkerProfileModel(workerId: $workerId, userId: $userId, fullName: $fullName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkerProfileModel && other.workerId == workerId;
  }

  @override
  int get hashCode => workerId.hashCode;
}
