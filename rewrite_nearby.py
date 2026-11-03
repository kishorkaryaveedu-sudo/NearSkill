import os

filepath = 'lib/features/discovery/presentation/nearby_workers_screen.dart'

new_code = '''import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/location_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/domain/worker_model.dart';
import '../data/discovery_repository.dart';

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
          // 1. Full Screen Map
          if (_lat != null && _lng != null)
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_lat!, _lng!),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nearskill.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_lat!, _lng!),
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                      ),
                    ),
                    ...filteredWorkers.map((w) {
                      return Marker(
                        point: LatLng(w.currentLatitude, w.currentLongitude),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {
                            // Show details if needed
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: w.profilePhotoUrl?.isNotEmpty == true
                                  ? Image.network(w.profilePhotoUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.person, color: AppColors.primary),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          // 2. Floating Search Bar & Quick Filters
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.search, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search for nearby services...',
                            hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16),
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppColors.border),
                      IconButton(
                        icon: const Icon(Icons.tune, color: AppColors.primary),
                        onPressed: _showRadiusDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quick Filters
                SizedBox(
                  height: 32,
                  child: ref.watch(allSkillsProvider).when(
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                        data: (skills) {
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: skills.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final isAll = i == 0;
                              final label = isAll ? 'All Pros' : skills[i - 1].skillName;
                              final isSelected = isAll ? _selectedSkill == null : _selectedSkill == label;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedSkill = isAll ? null : label);
                                  _fetchWorkers();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                                    boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 2, offset: Offset(0, 1))],
                                  ),
                                  child: Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          ),

          // 3. Map Controls
          Positioned(
            right: 20,
            bottom: 300,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white.withOpacity(0.9),
              foregroundColor: AppColors.textPrimary,
              elevation: 4,
              onPressed: () {
                _initLocation();
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // 4. Bottom Sheet (Nearby Pros)
          Positioned(
            bottom: 0, // In Stitch it says bottom-72px because of the bottom nav bar. Here the nav bar is likely provided by a root wrapper, so bottom: 0 or bottom: 72 depending on how the app is structured. Wait, let's use bottom: 0 and pb: 80.
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -8))],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Grabber Handle
                  Container(
                    width: 36,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nearby Pros', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('${filteredWorkers.length} available in your area', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Row(
                            children: [
                              Text('View List', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Horizontal Scrollable Cards
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredWorkers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final worker = filteredWorkers[index];
                        return Container(
                          width: 240,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow ?? const Color(0xFFF6F3F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: worker.profilePhotoUrl?.isNotEmpty == true
                                        ? Image.network(worker.profilePhotoUrl!, width: 48, height: 48, fit: BoxFit.cover)
                                        : Container(width: 48, height: 48, color: AppColors.primary, child: const Icon(Icons.person, color: Colors.white)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(worker.displayName, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('${worker.experienceYears} yrs exp', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: AppColors.accent),
                                        const SizedBox(width: 4),
                                        Text(worker.averageRating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      ],
                                    ),
                                  ),
                                  Text('₹${worker.hourlyRate.toInt()}/hr', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRadiusDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double tempRadius = _searchRadius;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Search Radius', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${tempRadius.toInt()} km', style: GoogleFonts.inter()),
                  Slider(
                    value: tempRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setStateDialog(() => tempRadius = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () {
                    setState(() => _searchRadius = tempRadius);
                    Navigator.pop(context);
                    _fetchWorkers();
                  },
                  child: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
'''

with open(filepath, 'w') as f:
    f.write(new_code)
print("Rewrote nearby_workers_screen.dart")
