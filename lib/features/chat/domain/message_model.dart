/// ChatMessageModel – maps to public.chat_messages table
class ChatMessageModel {
  final String messageId;
  final String requestId;
  final String senderUserId;
  final String receiverUserId;
  final String messageContent;
  final String messageType; // 'text', 'image'
  final String? imageUrl;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.messageId,
    required this.requestId,
    required this.senderUserId,
    required this.receiverUserId,
    required this.messageContent,
    this.messageType = 'text',
    this.imageUrl,
    required this.timestamp,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      messageId: map['message_id'] ?? '',
      requestId: map['request_id'] ?? '',
      senderUserId: map['sender_user_id'] ?? '',
      receiverUserId: map['receiver_user_id'] ?? '',
      messageContent: map['message_content'] ?? '',
      messageType: map['message_type'] ?? 'text',
      imageUrl: map['image_url'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'request_id': requestId,
      'sender_user_id': senderUserId,
      'receiver_user_id': receiverUserId,
      'message_content': messageContent,
      'message_type': messageType,
      'image_url': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  ChatMessageModel copyWith({
    String? messageId,
    String? requestId,
    String? senderUserId,
    String? receiverUserId,
    String? messageContent,
    String? messageType,
    String? imageUrl,
    DateTime? timestamp,
  }) {
    return ChatMessageModel(
      messageId: messageId ?? this.messageId,
      requestId: requestId ?? this.requestId,
      senderUserId: senderUserId ?? this.senderUserId,
      receiverUserId: receiverUserId ?? this.receiverUserId,
      messageContent: messageContent ?? this.messageContent,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isImage => messageType == 'image';
  bool isFromUser(String userId) => senderUserId == userId;

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  String toString() =>
      'ChatMessageModel(messageId: $messageId, senderUserId: $senderUserId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessageModel && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;
}
