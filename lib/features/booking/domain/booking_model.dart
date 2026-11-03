/// ServiceRequestModel – maps to public.service_requests table
class ServiceRequestModel {
  final String requestId;
  final String userId;
  final String workerId;
  final ServiceRequestStatus status;
  final double? agreedPrice;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ServiceRequestModel({
    required this.requestId,
    required this.userId,
    required this.workerId,
    this.status = ServiceRequestStatus.pending,
    this.agreedPrice,
    required this.createdAt,
    this.completedAt,
  });

  factory ServiceRequestModel.fromMap(Map<String, dynamic> map) {
    return ServiceRequestModel(
      requestId: map['request_id'] ?? '',
      userId: map['user_id'] ?? '',
      workerId: map['worker_id'] ?? '',
      status: ServiceRequestStatus.fromString(map['status']),
      agreedPrice: map['agreed_price'] != null
          ? (map['agreed_price'] as num).toDouble()
          : null,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'request_id': requestId,
      'user_id': userId,
      'worker_id': workerId,
      'status': status.value,
      'agreed_price': agreedPrice,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  ServiceRequestModel copyWith({
    String? requestId,
    String? userId,
    String? workerId,
    ServiceRequestStatus? status,
    double? agreedPrice,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ServiceRequestModel(
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      status: status ?? this.status,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isCompleted => status == ServiceRequestStatus.completed;
  bool get canCancel =>
      status == ServiceRequestStatus.pending ||
      status == ServiceRequestStatus.accepted;

  String get formattedPrice =>
      agreedPrice != null ? '₹${agreedPrice!.toStringAsFixed(2)}' : 'TBD';

  @override
  String toString() =>
      'ServiceRequestModel(requestId: $requestId, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceRequestModel && other.requestId == requestId;
  }

  @override
  int get hashCode => requestId.hashCode;
}

/// Status enum for service_requests
enum ServiceRequestStatus {
  pending('pending'),
  accepted('accepted'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const ServiceRequestStatus(this.value);

  static ServiceRequestStatus fromString(String? value) {
    return ServiceRequestStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ServiceRequestStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ServiceRequestStatus.pending:
        return 'Pending';
      case ServiceRequestStatus.accepted:
        return 'Accepted';
      case ServiceRequestStatus.inProgress:
        return 'In Progress';
      case ServiceRequestStatus.completed:
        return 'Completed';
      case ServiceRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}
