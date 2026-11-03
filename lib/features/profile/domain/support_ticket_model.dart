class SupportTicketModel {
  final String ticketId;
  final String userId;
  final String? subject;
  final String message;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;

  const SupportTicketModel({
    required this.ticketId,
    required this.userId,
    this.subject,
    required this.message,
    this.status = 'open',
    this.adminResponse,
    required this.createdAt,
  });

  factory SupportTicketModel.fromMap(Map<String, dynamic> map) {
    return SupportTicketModel(
      ticketId: map['ticket_id'] ?? '',
      userId: map['user_id'] ?? '',
      subject: map['subject'],
      message: map['message'] ?? '',
      status: map['status'] ?? 'open',
      adminResponse: map['admin_response'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticket_id': ticketId,
      'user_id': userId,
      'subject': subject,
      'message': message,
      'status': status,
      'admin_response': adminResponse,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
