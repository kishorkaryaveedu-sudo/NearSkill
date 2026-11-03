import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/utils/location_utils.dart';
import '../domain/worker_model.dart';
import '../domain/skill_model.dart';
import '../domain/support_ticket_model.dart';

/// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

/// Profile repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(client: ref.watch(supabaseProvider));
});

/// Reactive stream: true if userId has a worker_profiles row
final isWorkerProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  final response = await SupabaseConfig.client
      .from('worker_profiles')
      .select('worker_id')
      .eq('user_id', userId)
      .maybeSingle();
  return response != null;
});

/// Worker profile stream provider (realtime) by worker_id
final workerProfileProvider =
    StreamProvider.family<WorkerProfileModel?, String>((ref, workerId) {
  return ref.watch(profileRepositoryProvider).getWorkerStream(workerId);
});

/// Get worker profile by user_id
final workerProfileByUserIdProvider =
    FutureProvider.family<WorkerProfileModel?, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).getWorkerProfileByUserId(userId);
});

/// All skills provider (only approved)
final allSkillsProvider = FutureProvider<List<SkillModel>>((ref) {
  return ref.watch(profileRepositoryProvider).getAllSkills();
});

/// Admin skills provider (all skills including pending)
final adminSkillsProvider = FutureProvider<List<SkillModel>>((ref) {
  return ref.watch(profileRepositoryProvider).getAllSkillsAdmin();
});

/// Skills for a specific worker
final workerSkillsProvider =
    FutureProvider.family<List<SkillModel>, String>((ref, workerId) {
  return ref.watch(profileRepositoryProvider).getWorkerSkills(workerId);
});

/// All workers provider (for admin)
final allWorkersProvider = FutureProvider<List<WorkerProfileModel>>((ref) {
  return ref.watch(profileRepositoryProvider).getAllWorkers();
});

/// All support tickets (admin)
final allSupportTicketsProvider =
    FutureProvider<List<SupportTicketModel>>((ref) {
  return ref.watch(profileRepositoryProvider).getAllSupportTickets();
});

/// Profile repository for worker_profiles and skills
class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({required SupabaseClient client}) : _client = client;

  // ----------------------------------------------------------------
  // Worker profile CRUD
  // ----------------------------------------------------------------

  Future<WorkerProfileModel?> getWorkerProfile(String workerId) async {
    final response = await _client
        .from('worker_profiles')
        .select('*, users(full_name)')
        .eq('worker_id', workerId)
        .maybeSingle();

    if (response == null) return null;
    return WorkerProfileModel.fromMap(response);
  }

  Future<WorkerProfileModel?> getWorkerProfileByUserId(String userId) async {
    final response = await _client
        .from('worker_profiles')
        .select('*, users(full_name)')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return WorkerProfileModel.fromMap(response);
  }

  Stream<WorkerProfileModel?> getWorkerStream(String workerId) {
    return _client
        .from('worker_profiles')
        .stream(primaryKey: ['worker_id'])
        .eq('worker_id', workerId)
        .map((rows) =>
            rows.isEmpty ? null : WorkerProfileModel.fromMap(rows.first));
  }

  Future<WorkerProfileModel> createWorkerProfile({
    required String userId,
    String? profilePhotoUrl,
    int experienceYears = 0,
    double hourlyRate = 0,
  }) async {
    // Capture real GPS so the worker immediately appears on the map
    final position = await LocationUtils.getCurrentPosition();
    final lat = position?.latitude ?? 0.0;
    final lng = position?.longitude ?? 0.0;

    final response = await _client
        .from('worker_profiles')
        .insert({
          'user_id': userId,
          'profile_photo_url': profilePhotoUrl,
          'experience_years': experienceYears,
          'hourly_rate': hourlyRate,
          'current_latitude': lat,
          'current_longitude': lng,
          'availability_status': true,
        })
        .select()
        .single();

    return WorkerProfileModel.fromMap(response);
  }

  Future<void> updateWorkerProfile(WorkerProfileModel worker) async {
    final map = worker.toMap()..remove('worker_id');
    await _client
        .from('worker_profiles')
        .update(map)
        .eq('worker_id', worker.workerId);
  }

  Future<void> updateWorkerAvailability(
      String workerId, bool isAvailable) async {
    await _client
        .from('worker_profiles')
        .update({'availability_status': isAvailable}).eq('worker_id', workerId);
  }

  Future<void> updateWorkerLocation(
    String workerId,
    double latitude,
    double longitude,
  ) async {
    await _client.from('worker_profiles').update({
      'current_latitude': latitude,
      'current_longitude': longitude,
    }).eq('worker_id', workerId);
  }

  Future<void> updateProfilePhoto(String workerId, String photoUrl) async {
    await _client
        .from('worker_profiles')
        .update({'profile_photo_url': photoUrl}).eq('worker_id', workerId);
  }

  // ----------------------------------------------------------------
  // ID Card Upload & Verification
  // ----------------------------------------------------------------

  Future<String> uploadIdCard({
    required String workerId,
    required Uint8List imageBytes,
    required String fileName,
    required String idCardType,
  }) async {
    final fileKey = '${const Uuid().v4()}_$fileName';
    final path = '$workerId/$fileKey';

    await _client.storage.from('id-cards').uploadBinary(path, imageBytes,
        fileOptions: const FileOptions(upsert: true));

    final url = _client.storage.from('id-cards').getPublicUrl(path);

    await _client.from('worker_profiles').update({
      'id_card_url': url,
      'id_card_type': idCardType,
      'verification_status': 'pending',
    }).eq('worker_id', workerId);

    return url;
  }

  /// Creates a signed URL for the ID card (workaround for non-public buckets).
  /// Extracts the storage path from the stored public URL and generates a
  /// time-limited signed URL.
  Future<String> getSignedIdCardUrl(String publicUrl) async {
    // publicUrl looks like: https://xxx.supabase.co/storage/v1/object/public/id-cards/workerId/file.jpg
    // We need just "workerId/file.jpg"
    const marker = '/id-cards/';
    final idx = publicUrl.indexOf(marker);
    if (idx == -1) return publicUrl; // fallback
    final path = publicUrl.substring(idx + marker.length);
    final signedUrl = await _client.storage
        .from('id-cards')
        .createSignedUrl(path, 3600); // 1 hour
    return signedUrl;
  }

  Future<void> verifyWorker(String workerId, {String? notes}) async {
    await _client.from('worker_profiles').update({
      'verification_status': 'verified',
      'verification_notes': notes,
    }).eq('worker_id', workerId);
  }

  Future<void> rejectWorker(String workerId, {String? notes}) async {
    await _client.from('worker_profiles').update({
      'verification_status': 'rejected',
      'verification_notes': notes,
    }).eq('worker_id', workerId);
  }

  // ----------------------------------------------------------------
  // Get all workers (admin)
  // ----------------------------------------------------------------

  Future<List<WorkerProfileModel>> getAllWorkers() async {
    final response = await _client
        .from('worker_profiles')
        .select('*, users(full_name)')
        .order('verification_status');
    return response
        .map<WorkerProfileModel>((r) => WorkerProfileModel.fromMap(r))
        .toList();
  }

  // ----------------------------------------------------------------
  // Skills
  // ----------------------------------------------------------------

  Future<List<SkillModel>> getAllSkills() async {
    final response = await _client
        .from('skills')
        .select()
        .eq('status', 'approved')
        .order('skill_name');
    return response.map<SkillModel>((r) => SkillModel.fromMap(r)).toList();
  }

  Future<List<SkillModel>> getAllSkillsAdmin() async {
    final response = await _client.from('skills').select().order('skill_name');
    return response.map<SkillModel>((r) => SkillModel.fromMap(r)).toList();
  }

  Future<List<SkillModel>> getWorkerSkills(String workerId) async {
    final response = await _client
        .from('worker_skills')
        .select('skills(*)')
        .eq('worker_id', workerId);

    return response
        .map<SkillModel>(
            (r) => SkillModel.fromMap(r['skills'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> addWorkerSkill(String workerId, String skillId) async {
    await _client.from('worker_skills').insert({
      'worker_id': workerId,
      'skill_id': skillId,
    });
  }

  Future<void> removeWorkerSkill(String workerId, String skillId) async {
    await _client
        .from('worker_skills')
        .delete()
        .eq('worker_id', workerId)
        .eq('skill_id', skillId);
  }

  Future<void> setWorkerSkills(String workerId, List<String> skillIds) async {
    await _client.from('worker_skills').delete().eq('worker_id', workerId);

    if (skillIds.isNotEmpty) {
      await _client.from('worker_skills').insert(
            skillIds
                .map((id) => {'worker_id': workerId, 'skill_id': id})
                .toList(),
          );
    }
  }

  // ----------------------------------------------------------------
  // Skills CRUD (admin)
  // ----------------------------------------------------------------

  Future<SkillModel> addSkill(String skillName) async {
    final response = await _client
        .from('skills')
        .insert({'skill_name': skillName, 'status': 'approved'})
        .select()
        .single();
    return SkillModel.fromMap(response);
  }

  Future<SkillModel> suggestSkill(String skillName) async {
    final response = await _client
        .from('skills')
        .insert({'skill_name': skillName, 'status': 'pending'})
        .select()
        .single();
    return SkillModel.fromMap(response);
  }

  Future<void> updateSkillStatus(String skillId, String status) async {
    await _client
        .from('skills')
        .update({'status': status}).eq('skill_id', skillId);
  }

  Future<void> deleteSkill(String skillId) async {
    await _client.from('skills').delete().eq('skill_id', skillId);
  }

  // ----------------------------------------------------------------
  // Support Tickets
  // ----------------------------------------------------------------
  Future<void> submitSupportTicket(String userId, String message,
      {String? subject}) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'message': message,
      'status': 'open',
    };
    if (subject != null && subject.isNotEmpty) {
      data['subject'] = subject;
    }
    await _client.from('support_tickets').insert(data);
  }

  Future<List<SupportTicketModel>> getAllSupportTickets() async {
    final response = await _client
        .from('support_tickets')
        .select()
        .order('created_at', ascending: false);
    return response
        .map<SupportTicketModel>((r) => SupportTicketModel.fromMap(r))
        .toList();
  }

  Future<void> replyToSupportTicket(String ticketId, String response) async {
    await _client.from('support_tickets').update({
      'admin_response': response,
      'status': 'resolved',
    }).eq('ticket_id', ticketId);
  }

  Future<List<SupportTicketModel>> getUserSupportTickets(String userId) async {
    final response = await _client
        .from('support_tickets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response
        .map<SupportTicketModel>((r) => SupportTicketModel.fromMap(r))
        .toList();
  }
}
