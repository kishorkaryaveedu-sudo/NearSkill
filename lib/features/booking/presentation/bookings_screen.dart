import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';
import '../../chat/presentation/chat_screen.dart';

/// Stitch "NearSkill — Bookings" screen
class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  int _activeTab = 0; // 0=Upcoming, 1=Past

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(customAuthProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }
    final isWorkerAsync = ref.watch(isWorkerProvider(user.userId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: isWorkerAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (isWorker) {
            final requestsAsync = isWorker
                ? ref.watch(workerProfileByUserIdProvider(user.userId)).whenData(
                    (wp) => wp != null
                        ? ref.watch(workerRequestsProvider(wp.workerId))
                        : const AsyncValue<List<dynamic>>.data([]))
                : AsyncValue.data(
                    ref.watch(userRequestsProvider(user.userId)));

            // Flatten async-in-async
            final flatAsync = isWorker
                ? ref
                    .watch(workerProfileByUserIdProvider(user.userId))
                    .when<AsyncValue<List<dynamic>>>(
                      loading: () => const AsyncValue.loading(),
                      error: (e, s) => AsyncValue.error(e, s),
                      data: (wp) => wp != null
                          ? ref.watch(workerRequestsProvider(wp.workerId))
                          : const AsyncValue.data([]),
                    )
                : ref.watch(userRequestsProvider(user.userId));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────
                _buildHeader(),
                // ── Tab Chips ─────────────────────────────────
                _buildTabChips(),
                const SizedBox(height: 8),
                // ── List ──────────────────────────────────────
                Expanded(
                  child: flatAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (e, _) =>
                        Center(child: Text('Error: $e')),
                    data: (requests) {
                      final now = DateTime.now();
                      final filtered = requests.where((r) {
                        final isUpcoming = r.status !=
                                ServiceRequestStatus.completed &&
                            r.status != ServiceRequestStatus.cancelled;
                        return _activeTab == 0 ? isUpcoming : !isUpcoming;
                      }).toList();

                      if (filtered.isEmpty) return _buildEmpty();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _BookingCard(
                          request: filtered[i],
                          isWorker: isWorker,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.handyman_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'NearSkill',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Text(
            'Bookings',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _chip('Upcoming', 0),
          const SizedBox(width: 10),
          _chip('Past', 1),
        ],
      ),
    );
  }

  Widget _chip(String label, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color:
                active ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _activeTab == 0
                    ? Icons.event_note_outlined
                    : Icons.history_rounded,
                size: 40,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _activeTab == 0
                  ? 'No upcoming bookings'
                  : 'No past bookings',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeTab == 0
                  ? 'Book a skilled professional to get started.'
                  : 'Your completed bookings will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final dynamic request;
  final bool isWorker;
  const _BookingCard({required this.request, required this.isWorker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = request.status as ServiceRequestStatus;
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);
    final skill = request.skillName ?? 'Service';
    final otherName = isWorker
        ? (request.clientName ?? 'Client')
        : (request.workerName ?? 'Pro');
    final price = request.agreedPrice != null
        ? '₹${request.agreedPrice!.toStringAsFixed(0)}'
        : request.bidAmount != null
            ? '₹${request.bidAmount!.toStringAsFixed(0)}'
            : null;
    final date = DateFormat('MMM d, yyyy').format(request.createdAt);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            requestId: request.requestId,
            otherUserId:
                isWorker ? request.userId : request.workerId,
            otherUserName: otherName,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Service icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handyman_rounded,
                        color: AppColors.primary, size: 24),
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
                        Text(
                          otherName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(
                  height: 1, color: AppColors.surfaceContainerHigh),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.outline),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (price != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer
                            .withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        price,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: AppColors.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ServiceRequestStatus s) {
    switch (s) {
      case ServiceRequestStatus.pending:
        return AppColors.secondary;
      case ServiceRequestStatus.accepted:
        return AppColors.primary;
      case ServiceRequestStatus.inProgress:
        return AppColors.primary;
      case ServiceRequestStatus.completed:
        return const Color(0xFF00685F);
      case ServiceRequestStatus.cancelled:
        return AppColors.error;
    }
  }

  String _statusLabel(ServiceRequestStatus s) {
    switch (s) {
      case ServiceRequestStatus.pending:
        return 'Pending';
      case ServiceRequestStatus.accepted:
        return 'Confirmed';
      case ServiceRequestStatus.inProgress:
        return 'In Progress';
      case ServiceRequestStatus.completed:
        return 'Completed';
      case ServiceRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}
