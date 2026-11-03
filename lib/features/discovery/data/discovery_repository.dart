import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/utils/location_utils.dart';
import '../../profile/domain/worker_model.dart';

/// Discovery repository provider
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(client: SupabaseConfig.client);
});

/// Nearby workers provider
final nearbyWorkersProvider =
    FutureProvider.family<List<WorkerProfileModel>, NearbyQuery>(
        (ref, query) async {
  return ref.watch(discoveryRepositoryProvider).getNearbyWorkers(
        latitude: query.latitude,
        longitude: query.longitude,
        radiusKm: query.radiusKm,
        skillId: query.skillId,
      );
});

/// All available workers stream
final allWorkersStreamProvider =
    StreamProvider<List<WorkerProfileModel>>((ref) {
  return ref.watch(discoveryRepositoryProvider).getAllWorkersStream();
});

/// Query parameters for nearby workers
class NearbyQuery {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final String? skillId;

  const NearbyQuery({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
    this.skillId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NearbyQuery &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.radiusKm == radiusKm &&
        other.skillId == skillId;
  }

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      radiusKm.hashCode ^
      skillId.hashCode;
}

/// Discovery repository for finding nearby workers
class DiscoveryRepository {
  final SupabaseClient _client;

  DiscoveryRepository({required SupabaseClient client}) : _client = client;

  // ----------------------------------------------------------------
  // Joined select: worker_profiles + users.full_name
  // ----------------------------------------------------------------
  static const _selectWithName = '*, users(full_name)';

  // ----------------------------------------------------------------
  // All available workers (realtime stream)
  // ----------------------------------------------------------------
  Stream<List<WorkerProfileModel>> getAllWorkersStream() {
    return _client
        .from('worker_profiles')
        .stream(primaryKey: ['worker_id'])
        .eq('availability_status', true)
        .order('average_rating', ascending: false)
        .map((rows) => rows.map((r) => WorkerProfileModel.fromMap(r)).toList());
  }

  // ----------------------------------------------------------------
  // Nearby workers (bounding-box filter + exact distance + name join)
  // ----------------------------------------------------------------
  Future<List<WorkerProfileModel>> getNearbyWorkers({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String? skillId,
  }) async {
    final box = LocationUtils.getBoundingBox(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );

    var query = _client
        .from('worker_profiles')
        .select(_selectWithName)
        .eq('availability_status', true)
        .gte('current_latitude', box['minLat']!)
        .lte('current_latitude', box['maxLat']!)
        .gte('current_longitude', box['minLon']!)
        .lte('current_longitude', box['maxLon']!);

    final response = await query;

    List<WorkerProfileModel> workers = response
        .map<WorkerProfileModel>((r) => WorkerProfileModel.fromMap(r))
        .toList();

    // If bounding box returned nothing, try fetching ALL available workers
    if (workers.isEmpty) {
      final allResp = await _client
          .from('worker_profiles')
          .select(_selectWithName)
          .eq('availability_status', true)
          .order('average_rating', ascending: false);

      workers = allResp
          .map<WorkerProfileModel>((r) => WorkerProfileModel.fromMap(r))
          .toList();
    }

    // Skill filter
    if (skillId != null && skillId.isNotEmpty) {
      final skillRow = await _client
          .from('skills')
          .select('skill_id')
          .ilike('skill_name', skillId)
          .maybeSingle();

      if (skillRow != null) {
        final actualSkillId = skillRow['skill_id'] as String;
        final workerIdsWithSkill = await _client
            .from('worker_skills')
            .select('worker_id')
            .eq('skill_id', actualSkillId);

        final ids =
            workerIdsWithSkill.map((r) => r['worker_id'] as String).toSet();
        workers = workers.where((w) => ids.contains(w.workerId)).toList();
      } else {
        workers = []; // Skill provided but not found, return empty
      }
    }

    // Exact distance filter & sort
    if (latitude != 0 && longitude != 0) {
      workers = workers.where((w) {
        if (w.currentLatitude == 0 && w.currentLongitude == 0) return true;
        final d = LocationUtils.calculateDistance(
          startLatitude: latitude,
          startLongitude: longitude,
          endLatitude: w.currentLatitude,
          endLongitude: w.currentLongitude,
        );
        return d <= radiusKm;
      }).toList();

      workers.sort((a, b) {
        final dA = LocationUtils.calculateDistance(
          startLatitude: latitude,
          startLongitude: longitude,
          endLatitude: a.currentLatitude,
          endLongitude: a.currentLongitude,
        );
        final dB = LocationUtils.calculateDistance(
          startLatitude: latitude,
          startLongitude: longitude,
          endLatitude: b.currentLatitude,
          endLongitude: b.currentLongitude,
        );
        return dA.compareTo(dB);
      });
    }

    return workers;
  }

  // ----------------------------------------------------------------
  // Top rated workers
  // ----------------------------------------------------------------
  Future<List<WorkerProfileModel>> getTopRatedWorkers({int limit = 10}) async {
    final response = await _client
        .from('worker_profiles')
        .select(_selectWithName)
        .eq('availability_status', true)
        .order('average_rating', ascending: false)
        .limit(limit);

    return response
        .map<WorkerProfileModel>((r) => WorkerProfileModel.fromMap(r))
        .toList();
  }

  Future<WorkerProfileModel?> getWorkerById(String workerId) async {
    final response = await _client
        .from('worker_profiles')
        .select(_selectWithName)
        .eq('worker_id', workerId)
        .maybeSingle();

    if (response == null) return null;
    return WorkerProfileModel.fromMap(response);
  }

  // ----------------------------------------------------------------
  // Workers with a specific skill
  // ----------------------------------------------------------------
  Future<List<WorkerProfileModel>> getWorkersBySkill(String skillId) async {
    final workerIdsResp = await _client
        .from('worker_skills')
        .select('worker_id')
        .eq('skill_id', skillId);

    if (workerIdsResp.isEmpty) return [];

    final ids = workerIdsResp.map((r) => r['worker_id']).toList();

    final response = await _client
        .from('worker_profiles')
        .select(_selectWithName)
        .eq('availability_status', true)
        .inFilter('worker_id', ids)
        .order('average_rating', ascending: false);

    return response
        .map<WorkerProfileModel>((r) => WorkerProfileModel.fromMap(r))
        .toList();
  }
}
