import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/message_model.dart';

/// Chat repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(client: SupabaseConfig.client);
});

/// Messages stream provider – scoped to a service request
final messagesProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, requestId) {
  return ref.watch(chatRepositoryProvider).getMessagesStream(requestId);
});

/// Latest message stream provider - scoped to a service request
final latestMessageProvider =
    StreamProvider.family<ChatMessageModel?, String>((ref, requestId) {
  return ref.watch(chatRepositoryProvider).getLatestMessageStream(requestId);
});

/// Chat repository for chat_messages table
class ChatRepository {
  final SupabaseClient _client;

  ChatRepository({required SupabaseClient client}) : _client = client;

  // ----------------------------------------------------------------
  // Send text message
  // ----------------------------------------------------------------

  Future<ChatMessageModel> sendMessage({
    required String requestId,
    required String senderUserId,
    required String receiverUserId,
    required String messageContent,
  }) async {
    final response = await _client
        .from('chat_messages')
        .insert({
          'request_id': requestId,
          'sender_user_id': senderUserId,
          'receiver_user_id': receiverUserId,
          'message_content': messageContent,
          'message_type': 'text',
        })
        .select()
        .single();

    return ChatMessageModel.fromMap(response);
  }

  // ----------------------------------------------------------------
  // Send image message
  // ----------------------------------------------------------------

  Future<ChatMessageModel> sendImageMessage({
    required String requestId,
    required String senderUserId,
    required String receiverUserId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    // Upload to Supabase Storage
    final fileKey = '${const Uuid().v4()}_$fileName';
    final path = '$requestId/$fileKey';

    await _client.storage.from('chat-images').uploadBinary(path, imageBytes,
        fileOptions: const FileOptions(upsert: true));

    final imageUrl = _client.storage.from('chat-images').getPublicUrl(path);

    final response = await _client
        .from('chat_messages')
        .insert({
          'request_id': requestId,
          'sender_user_id': senderUserId,
          'receiver_user_id': receiverUserId,
          'message_content': '📷 Image',
          'message_type': 'image',
          'image_url': imageUrl,
        })
        .select()
        .single();

    return ChatMessageModel.fromMap(response);
  }

  // ----------------------------------------------------------------
  // Get messages stream (realtime) for a service request
  // ----------------------------------------------------------------

  Stream<List<ChatMessageModel>> getMessagesStream(String requestId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['message_id'])
        .eq('request_id', requestId)
        .order('timestamp', ascending: true)
        .map((rows) => rows.map((r) => ChatMessageModel.fromMap(r)).toList());
  }

  // ----------------------------------------------------------------
  // Get latest message stream for a service request
  // ----------------------------------------------------------------

  Stream<ChatMessageModel?> getLatestMessageStream(String requestId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['message_id'])
        .eq('request_id', requestId)
        .order('timestamp', ascending: false)
        .map((rows) =>
            rows.isNotEmpty ? ChatMessageModel.fromMap(rows.first) : null);
  }

  // ----------------------------------------------------------------
  // Get all messages between two users across all requests
  // ----------------------------------------------------------------

  Future<List<ChatMessageModel>> getMessagesBetweenUsers(
    String userId1,
    String userId2,
  ) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .or('and(sender_user_id.eq.$userId1,receiver_user_id.eq.$userId2),'
            'and(sender_user_id.eq.$userId2,receiver_user_id.eq.$userId1)')
        .order('timestamp');

    return response
        .map<ChatMessageModel>((r) => ChatMessageModel.fromMap(r))
        .toList();
  }

  // ----------------------------------------------------------------
  // Delete a message
  // ----------------------------------------------------------------

  Future<void> deleteMessage(String messageId) async {
    await _client.from('chat_messages').delete().eq('message_id', messageId);
  }

  // ----------------------------------------------------------------
  // Get latest message for a request
  // ----------------------------------------------------------------

  Future<ChatMessageModel?> getLastMessage(String requestId) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .eq('request_id', requestId)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return ChatMessageModel.fromMap(response);
  }
}
