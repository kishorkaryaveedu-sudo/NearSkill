import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/booking_model.dart';
import '../domain/review_model.dart';

/// Booking repository provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(client: SupabaseConfig.client);
});

/// User service requests stream provider
final userRequestsProvider =
    StreamProvider.family<List<ServiceRequestModel>, String>((ref, userId) {
  return ref.watch(bookingRepositoryProvider).getUserRequestsStream(userId);
});

/// Worker service requests stream provider
final workerRequestsProvider =
    StreamProvider.family<List<ServiceRequestModel>, String>((ref, workerId) {
  return ref.watch(bookingRepositoryProvider).getWorkerRequestsStream(workerId);
});

/// Pending requests for a worker
final pendingRequestsProvider =
    FutureProvider.family<List<ServiceRequestModel>, String>((ref, workerId) {
  return ref
      .read(bookingRepositoryProvider)
      .getPendingRequestsForWorker(workerId);
});

/// Fetch all reviews
final workerReviewsListProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, workerId) {
  return ref.watch(bookingRepositoryProvider).getWorkerReviews(workerId);
});

final allReviewsProvider = FutureProvider<List<ReviewModel>>((ref) {
  return ref.watch(bookingRepositoryProvider).getAllReviews();
});

/// Booking repository for service_requests and reviews
class BookingRepository {
  final SupabaseClient _client;

  BookingRepository({required SupabaseClient client}) : _client = client;

  // ----------------------------------------------------------------
  // Service Requests
  // ----------------------------------------------------------------

  Future<ServiceRequestModel> createRequest({
    required String userId,
    required String workerId,
    double? agreedPrice,
  }) async {
    final response = await _client
        .from('service_requests')
        .insert({
          'user_id': userId,
          'worker_id': workerId,
          'status': ServiceRequestStatus.pending.value,
          'agreed_price': agreedPrice,
        })
        .select()
        .single();

    return ServiceRequestModel.fromMap(response);
  }

  Future<ServiceRequestModel?> getRequestById(String requestId) async {
    final response = await _client
        .from('service_requests')
        .select()
        .eq('request_id', requestId)
        .maybeSingle();

    if (response == null) return null;
    return ServiceRequestModel.fromMap(response);
  }

  Stream<ServiceRequestModel?> getRequestStream(String requestId) {
    return _client
        .from('service_requests')
        .stream(primaryKey: ['request_id'])
        .eq('request_id', requestId)
        .map((rows) =>
            rows.isNotEmpty ? ServiceRequestModel.fromMap(rows.first) : null);
  }

  Future<ServiceRequestModel> getOrCreateRequest({
    required String userId,
    required String workerId,
  }) async {
    final response = await _client
        .from('service_requests')
        .select()
        .eq('user_id', userId)
        .eq('worker_id', workerId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      final request = ServiceRequestModel.fromMap(response);
      // If the last request between this user and worker is already completed or cancelled, starting a new chat should create a fresh request.
      if (request.status != ServiceRequestStatus.completed &&
          request.status != ServiceRequestStatus.cancelled) {
        return request;
      }
    }
    return createRequest(userId: userId, workerId: workerId);
  }

  Stream<List<ServiceRequestModel>> getUserRequestsStream(String userId) {
    return _client
        .from('service_requests')
        .stream(primaryKey: ['request_id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
            (rows) => rows.map((r) => ServiceRequestModel.fromMap(r)).toList());
  }

  Stream<List<ServiceRequestModel>> getWorkerRequestsStream(String workerId) {
    return _client
        .from('service_requests')
        .stream(primaryKey: ['request_id'])
        .eq('worker_id', workerId)
        .order('created_at', ascending: false)
        .map(
            (rows) => rows.map((r) => ServiceRequestModel.fromMap(r)).toList());
  }

  Future<void> updateRequestStatus(
    String requestId,
    ServiceRequestStatus status, {
    double? agreedPrice,
  }) async {
    final data = <String, dynamic>{'status': status.value};
    if (agreedPrice != null) data['agreed_price'] = agreedPrice;
    if (status == ServiceRequestStatus.completed) {
      data['completed_at'] = DateTime.now().toIso8601String();
    }
    await _client
        .from('service_requests')
        .update(data)
        .eq('request_id', requestId);
  }

  Future<void> acceptRequest(String requestId, {double? agreedPrice}) async {
    await updateRequestStatus(requestId, ServiceRequestStatus.accepted,
        agreedPrice: agreedPrice);
  }

  Future<void> startRequest(String requestId) async {
    await updateRequestStatus(requestId, ServiceRequestStatus.inProgress);
  }

  Future<void> completeRequest(String requestId) async {
    await updateRequestStatus(requestId, ServiceRequestStatus.completed);
  }

  Future<void> cancelRequest(String requestId) async {
    await updateRequestStatus(requestId, ServiceRequestStatus.cancelled);
  }

  Future<List<ServiceRequestModel>> getAllRequests() async {
    final response = await _client
        .from('service_requests')
        .select()
        .order('created_at', ascending: false);
    return response
        .map<ServiceRequestModel>((r) => ServiceRequestModel.fromMap(r))
        .toList();
  }

  Future<List<ServiceRequestModel>> getPendingRequestsForWorker(
      String workerId) async {
    final response = await _client
        .from('service_requests')
        .select()
        .eq('worker_id', workerId)
        .eq('status', ServiceRequestStatus.pending.value)
        .order('created_at');
    return response
        .map<ServiceRequestModel>((r) => ServiceRequestModel.fromMap(r))
        .toList();
  }

  // ----------------------------------------------------------------
  // Reviews
  // ----------------------------------------------------------------

  Future<ReviewModel> submitReview({
    required String requestId,
    required String reviewerUserId,
    required String ratedWorkerId,
    required double rating,
    String? comment,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'request_id': requestId,
      'reviewer_user_id': reviewerUserId,
      'rated_worker_id': ratedWorkerId,
      'rating': rating.toInt(),
      'comment': comment,
    };
    if (imageUrl != null) data['image_url'] = imageUrl;

    final response =
        await _client.from('reviews').insert(data).select().single();

    return ReviewModel.fromMap(response);
  }

  /// Upload a review image to the 'review' storage bucket
  Future<String> uploadReviewImage({
    required String requestId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final fileKey = '${const Uuid().v4()}_$fileName';
    final path = '$requestId/$fileKey';

    await _client.storage.from('review').uploadBinary(path, imageBytes,
        fileOptions: const FileOptions(upsert: true));

    return _client.storage.from('review').getPublicUrl(path);
  }

  Future<ReviewModel?> getReviewForRequest(String requestId) async {
    final response = await _client
        .from('reviews')
        .select()
        .eq('request_id', requestId)
        .maybeSingle();

    if (response == null) return null;
    return ReviewModel.fromMap(response);
  }

  Future<List<ReviewModel>> getWorkerReviews(String ratedWorkerId) async {
    final response = await _client
        .from('reviews')
        .select()
        .eq('rated_worker_id', ratedWorkerId)
        .order('created_at', ascending: false);

    return response.map<ReviewModel>((r) => ReviewModel.fromMap(r)).toList();
  }

  Future<List<ReviewModel>> getAllReviews() async {
    final response = await _client
        .from('reviews')
        .select()
        .order('created_at', ascending: false);

    return response.map<ReviewModel>((r) => ReviewModel.fromMap(r)).toList();
  }

  /// Recalculate and update the average rating for a worker
  Future<void> recalculateWorkerRating(String workerId) async {
    final reviews = await getWorkerReviews(workerId);
    if (reviews.isEmpty) return;

    final avg =
        reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;

    await _client.from('worker_profiles').update({
      'average_rating': double.parse(avg.toStringAsFixed(2)),
    }).eq('worker_id', workerId);
  }
}
