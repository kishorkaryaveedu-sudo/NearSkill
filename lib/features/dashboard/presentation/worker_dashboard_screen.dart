import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../booking/data/booking_repository.dart';
import '../../booking/domain/booking_model.dart';
import '../../chat/presentation/chat_screen.dart';

/// Worker Dashboard — Stitch "Hyper-Local Trust" design
class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() =>
      _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState
    extends ConsumerState<WorkerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(customAuthProvider);
    final workerAsync = user != null
        ? ref.watch(workerProfileByUserIdProvider(user.userId))
        : const AsyncValue<dynamic>.loading();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: workerAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (worker) {
          if (worker == null) {
            return const Center(child: Text('No worker profile found.'));
          }

          final requestsAsync =
              ref.watch(workerRequestsProvider(worker.workerId));

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              if (user != null) {
                ref.invalidate(workerProfileByUserIdProvider(user.userId));
              }
            },
            child: CustomScrollView(
              slivers: [
                // ── Teal Top Section ──────────────────────────
                SliverToBoxAdapter(
                  child: _buildTopSection(user, worker),
                ),
                // ── Earnings/Status Bento ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _buildBento(worker),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                // ── New Requests ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'New Requests',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        requestsAsync.whenOrNull(
                          data: (reqs) {
                            final pending = reqs
                                .where((r) =>
                                    r.status ==
                                    ServiceRequestStatus.pending)
                                .length;
                            if (pending == 0) return null;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                '$pending new',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSecondaryContainer,
                                ),
                              ),
                            );
                          },
                        ) ??
                            const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                // ── Requests List ─────────────────────────────
                requestsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                      child: Center(child: Text('Error: $e'))),
                  data: (requests) {
                    final pending = requests
                        .where((r) =>
                            r.status == ServiceRequestStatus.pending)
                        .toList();

                    if (pending.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptyRequests(),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _RequestCard(
                            request: pending[index],
                            workerId: worker.workerId,
                          ),
                        ),
                        childCount: pending.length,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopSection(user, worker) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${(user?.fullName ?? 'Worker').split(' ').first} 👋',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's your summary for today.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: worker.profilePhotoUrl?.isNotEmpty == true
                ? ClipOval(
                    child: Image.network(worker.profilePhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28)),
                  )
                : const Icon(Icons.person_rounded,
                    color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildBento(worker) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Row(
        children: [
          // Earnings card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Daily Earnings',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${worker.hourlyRate.toStringAsFixed(0)}/hr',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Status card
          Expanded(
            child: _AvailabilityCard(worker: worker),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRequests() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined,
                size: 40, color: AppColors.outline),
          ),
          const SizedBox(height: 16),
          Text(
            'No new requests',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'New job requests will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Availability toggle card
class _AvailabilityCard extends ConsumerStatefulWidget {
  final dynamic worker;
  const _AvailabilityCard({required this.worker});

  @override
  ConsumerState<_AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends ConsumerState<_AvailabilityCard> {
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.worker.availabilityStatus;
  }

  Future<void> _toggle() async {
    final newVal = !_isOnline;
    setState(() => _isOnline = newVal);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateWorkerAvailability(widget.worker.workerId, newVal);
    } catch (_) {
      setState(() => _isOnline = !newVal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _isOnline ? AppColors.primary : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.outline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isOnline
                        ? Icons.wifi_tethering_rounded
                        : Icons.wifi_tethering_off_rounded,
                    color: _isOnline ? Colors.white : AppColors.outline,
                    size: 20,
                  ),
                ),
                const Spacer(),
                // Mini toggle indicator
                Container(
                  width: 32,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Align(
                    alignment: _isOnline
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.white : AppColors.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Current Status',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _isOnline
                    ? Colors.white.withOpacity(0.75)
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _isOnline ? Colors.white : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual new-request card with Accept / Decline
class _RequestCard extends ConsumerStatefulWidget {
  final dynamic request;
  final String workerId;
  const _RequestCard({required this.request, required this.workerId});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _loading = false;

  Future<void> _respond(bool accept) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      if (accept) {
        await repo.acceptRequest(widget.request.requestId);
        if (mounted) {
          final user = ref.read(customAuthProvider);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                requestId: widget.request.requestId,
                otherUserId: widget.request.userId,
                otherUserName: widget.request.clientName ?? 'Client',
              ),
            ),
          );
        }
      } else {
        await repo.cancelRequest(widget.request.requestId);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final skill = req.skillName ?? 'Service Request';
    final distance = req.distanceKm != null
        ? '${req.distanceKm!.toStringAsFixed(1)} km away'
        : 'Nearby';

    final statusColor = _statusColor(req.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Service icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.handyman_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.outline),
                          const SizedBox(width: 3),
                          Text(
                            distance,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    req.status.value.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (req.status == ServiceRequestStatus.pending) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => _respond(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text('Decline',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => _respond(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Accept',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pending:
        return AppColors.secondary;
      case ServiceRequestStatus.accepted:
        return AppColors.primary;
      case ServiceRequestStatus.inProgress:
        return AppColors.primary;
      case ServiceRequestStatus.completed:
        return AppColors.success;
      case ServiceRequestStatus.cancelled:
        return AppColors.error;
    }
  }
}
