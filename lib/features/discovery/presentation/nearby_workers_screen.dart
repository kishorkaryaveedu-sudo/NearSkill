import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/location_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/worker_model.dart';
import '../../profile/presentation/worker_profile_screen.dart';
import '../data/discovery_repository.dart';

/// Pixel-perfect Stitch "Live Discovery Map" screen
class NearbyWorkersScreen extends ConsumerStatefulWidget {
  const NearbyWorkersScreen({super.key});

  @override
  ConsumerState<NearbyWorkersScreen> createState() =>
      _NearbyWorkersScreenState();
}

class _NearbyWorkersScreenState extends ConsumerState<NearbyWorkersScreen> {
  double? _lat;
  double? _lng;
  String? _selectedSkill;
  double _searchRadius = 10.0;
  bool _isLoading = true;
  List<WorkerProfileModel> _workers = [];
  String _searchQuery = '';
  int _activeChip = 0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoading = true);
    final pos = await LocationUtils.getCurrentPosition();
    if (mounted) {
      setState(() {
        _lat = pos?.latitude;
        _lng = pos?.longitude;
        _isLoading = false;
      });
      if (pos != null) _fetchWorkers();
    }
  }

  Future<void> _fetchWorkers() async {
    if (_lat == null || _lng == null) return;
    try {
      final workers =
          await ref.read(discoveryRepositoryProvider).getNearbyWorkers(
                latitude: _lat!,
                longitude: _lng!,
                radiusKm: _searchRadius,
                skillId: _selectedSkill,
              );
      if (mounted) setState(() => _workers = workers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredWorkers = _workers.where((w) {
      if (_searchQuery.isEmpty) return true;
      return w.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── 1. Full-Screen Map Background ──────────────────
          if (_lat != null && _lng != null)
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_lat!, _lng!),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nearskill.app',
                  ),
                  MarkerLayer(
                    markers: [
                      // User location pin
                      Marker(
                        point: LatLng(_lat!, _lng!),
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      // Worker pins with profile photos & price
                      ...filteredWorkers.map((w) => Marker(
                            point: LatLng(
                                w.currentLatitude, w.currentLongitude),
                            width: 64,
                            height: 72,
                            child: GestureDetector(
                              onTap: () => _showWorkerDetail(w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Avatar in white ring with green dot
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0x30000000),
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              AppColors.surfaceContainer,
                                          backgroundImage: w.profilePhotoUrl !=
                                                  null
                                              ? NetworkImage(
                                                  w.profilePhotoUrl!)
                                              : null,
                                          child:
                                              w.profilePhotoUrl == null
                                                  ? Text(
                                                      w.displayName
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                          color: AppColors
                                                              .onSurface),
                                                    )
                                                  : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -1,
                                        right: -1,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  // Price label
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(9999),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x20000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '₹${w.hourlyRate.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ],
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: AppColors.surfaceVariant,
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.primary)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off,
                                size: 48, color: AppColors.outline),
                            const SizedBox(height: 12),
                            Text('Location unavailable',
                                style: GoogleFonts.inter(
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                ),
              ),
            ),

          // ── 2. Floating Search Bar + Chips ─────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Search bar
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                            color: AppColors.surfaceVariant, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(Icons.search,
                              color: AppColors.onSurfaceVariant, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: AppColors.onSurface,
                                height: 22 / 17,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search for nearby services...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 17,
                                  color: AppColors.outline,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: AppColors.outlineVariant,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                              ),
                              child: const Icon(Icons.tune,
                                  color: AppColors.primary, size: 24),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter chips
                    SizedBox(
                      height: 32,
                      child: ref.watch(allSkillsProvider).when(
                            data: (skills) {
                              final chips = [
                                'All Pros',
                                ...skills.map((s) => s.skillName)
                              ];
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: chips.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final isActive = _activeChip == i;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _activeChip = i;
                                        _selectedSkill =
                                            i == 0 ? null : chips[i];
                                      });
                                      _fetchWorkers();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.primary
                                            : Colors.white.withOpacity(0.9),
                                        borderRadius:
                                            BorderRadius.circular(9999),
                                        border: isActive
                                            ? null
                                            : Border.all(
                                                color:
                                                    AppColors.surfaceVariant,
                                                width: 1),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x10000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          chips[i],
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.01 * 13,
                                            color: isActive
                                                ? AppColors.onPrimary
                                                : AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. My Location FAB ─────────────────────────────
          Positioned(
            right: 20,
            bottom: 360,
            child: GestureDetector(
              onTap: _initLocation,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location,
                    color: AppColors.onSurface, size: 24),
              ),
            ),
          ),

          // ── 4. Bottom Sheet (Nearby Pros) ──────────────────
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 30,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Grabber handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 36,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                  // Title row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nearby Pros',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.01 * 22,
                                color: AppColors.onSurface,
                                height: 28 / 22,
                              ),
                            ),
                            Text(
                              '${filteredWorkers.length} available in your area',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.onSurfaceVariant,
                                height: 20 / 15,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'View List',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward,
                                size: 18, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal scrolling pro cards
                  Expanded(
                    child: filteredWorkers.isEmpty
                        ? Center(
                            child: Text(
                              'No workers found nearby',
                              style: GoogleFonts.inter(
                                  color: AppColors.outline, fontSize: 14),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredWorkers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (_, i) =>
                                _buildProCard(filteredWorkers[i]),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stitch "Pro Card" — 240px min width, surface-container-low bg
  Widget _buildProCard(WorkerProfileModel worker) {
    return GestureDetector(
      onTap: () => _showWorkerDetail(worker),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar + name + skill
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  backgroundImage: worker.profilePhotoUrl != null
                      ? NetworkImage(worker.profilePhotoUrl!)
                      : null,
                  child: worker.profilePhotoUrl == null
                      ? Text(
                          worker.displayName.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                          height: 25 / 20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${worker.experienceYears}y experience',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.02 * 12,
                          color: AppColors.onSurfaceVariant,
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Rating + price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppColors.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        worker.averageRating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${worker.hourlyRate.toStringAsFixed(0)}/hr',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkerDetail(WorkerProfileModel worker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WorkerDetailSheet(worker: worker),
    );
  }
}

/// Bottom sheet shown when tapping a worker pin on the map
class _WorkerDetailSheet extends StatelessWidget {
  final WorkerProfileModel worker;
  const _WorkerDetailSheet({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryFixed,
                backgroundImage: worker.profilePhotoUrl?.isNotEmpty == true
                    ? NetworkImage(worker.profilePhotoUrl!)
                    : null,
                child: worker.profilePhotoUrl?.isNotEmpty != true
                    ? Text(
                        worker.displayName.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimaryFixed),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.displayName,
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.star),
                        const SizedBox(width: 4),
                        Text(
                          '${worker.averageRating.toStringAsFixed(1)}  •  ${worker.experienceYears}yr exp',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '₹${worker.hourlyRate.toStringAsFixed(0)}/hr',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Verification badge
              if (worker.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Verified',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Book now button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Book Now',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
