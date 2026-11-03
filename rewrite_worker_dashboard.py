import os

filepath = 'lib/features/dashboard/presentation/worker_dashboard_screen.dart'

new_code = '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../booking/data/booking_repository.dart';
import '../../booking/domain/booking_model.dart';
import '../../chat/presentation/chat_screen.dart';

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() =>
      _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(customAuthProvider);
    final workerAsync = user != null
        ? ref.watch(workerProfileByUserIdProvider(user.userId))
        : const AsyncValue.loading();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Nearby Services', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.location_on, color: AppColors.textSecondary), onPressed: () {}),
        actions: [IconButton(icon: const Icon(Icons.notifications, color: AppColors.textSecondary), onPressed: () {})],
      ),
      body: SafeArea(
        child: workerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (worker) {
            if (worker == null) {
              return const Center(child: Text('No worker profile found.'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  ref.invalidate(workerProfileByUserIdProvider(user.userId));
                }
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Dashboard Header / Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, ${user?.fullName?.split(' ').first ?? 'Worker'}', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('Here\\'s your summary for today.', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: worker.profilePhotoUrl != null ? NetworkImage(worker.profilePhotoUrl!) : null,
                        child: worker.profilePhotoUrl == null ? const Icon(Icons.person) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards Bento Grid
                  Row(
                    children: [
                      // Earnings / Rate Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.payments, color: AppColors.primary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                                    child: Text('Active', style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Hourly Rate', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                              Text('₹${worker.hourlyRate.toInt()}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Status Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.power_settings_new, color: Colors.white),
                                  ),
                                  Switch(
                                    value: worker.availabilityStatus,
                                    activeColor: Colors.white,
                                    activeTrackColor: AppColors.success,
                                    onChanged: (val) async {
                                      if (!worker.isVerified) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile pending verification.'), backgroundColor: AppColors.error));
                                        return;
                                      }
                                      await ref.read(profileRepositoryProvider).updateWorkerAvailability(worker.workerId, val);
                                      ref.invalidate(workerProfileByUserIdProvider(user!.userId));
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Current Status', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                              Text(worker.availabilityStatus ? 'Online' : 'Offline', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Active Jobs section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Active Jobs', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('View All', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ActiveJobsList(workerId: worker.workerId),

                  const SizedBox(height: 24),

                  // Pending Requests section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Pending Requests', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('View All', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PendingRequestsList(workerId: worker.workerId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Active Jobs List ────────────────────────────

class _ActiveJobsList extends ConsumerWidget {
  final String workerId;
  const _ActiveJobsList({required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(workerRequestsProvider(workerId));

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (requests) {
        final activeJobs = requests
            .where((r) =>
                r.status == ServiceRequestStatus.accepted ||
                r.status == ServiceRequestStatus.inProgress)
            .toList();

        if (activeJobs.isEmpty) {
           return Text('No active jobs', style: GoogleFonts.inter(color: AppColors.textSecondary));
        }

        return Column(
          children: activeJobs.map((job) => _ActiveJobCard(job: job)).toList(),
        );
      },
    );
  }
}

class _ActiveJobCard extends ConsumerWidget {
  final ServiceRequestModel job;
  const _ActiveJobCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInProgress = job.status == ServiceRequestStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 30, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh ?? const Color(0xFFE2E8F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.handyman, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FutureBuilder(
                            future: ref.read(authRepositoryProvider).getUserById(job.userId),
                            builder: (context, AsyncSnapshot snapshot) {
                              final userName = (snapshot.data as dynamic)?.fullName ?? 'Client';
                              return Text('$userName Request', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis);
                            },
                          ),
                        ),
                        if (job.agreedPrice != null)
                          Text('₹${job.agreedPrice!.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(isInProgress ? 'In Progress' : 'Accepted', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(DateFormat('MMM d, HH:mm').format(job.createdAt), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: job.requestId, otherUserId: job.userId, otherUserName: 'Client')));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Message', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (!isInProgress) {
                      await ref.read(bookingRepositoryProvider).startRequest(job.requestId);
                    } else {
                      await ref.read(bookingRepositoryProvider).completeRequest(job.requestId);
                    }
                    ref.invalidate(workerRequestsProvider(job.workerId));
                    ref.invalidate(userRequestsProvider(job.userId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isInProgress ? 'Complete Job' : 'Start Job', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pending Requests List ────────────────────────────

class _PendingRequestsList extends ConsumerWidget {
  final String workerId;
  const _PendingRequestsList({required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider(workerId));

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (requests) {
        if (requests.isEmpty) {
           return Text('No pending requests', style: GoogleFonts.inter(color: AppColors.textSecondary));
        }

        return Column(
          children: requests.map((req) => _PendingJobCard(job: req)).toList(),
        );
      },
    );
  }
}

class _PendingJobCard extends ConsumerWidget {
  final ServiceRequestModel job;
  const _PendingJobCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 30, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh ?? const Color(0xFFE2E8F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FutureBuilder(
                            future: ref.read(authRepositoryProvider).getUserById(job.userId),
                            builder: (context, AsyncSnapshot snapshot) {
                              final userName = (snapshot.data as dynamic)?.fullName ?? 'Client';
                              return Text('$userName Request', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis);
                            },
                          ),
                        ),
                        if (job.proposedPrice != null)
                          Text('₹${job.proposedPrice!.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Pending Review', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(DateFormat('MMM d, HH:mm').format(job.createdAt), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Decline/Cancel logic
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Decline', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: job.requestId, otherUserId: job.userId, otherUserName: 'Client')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Message & Accept', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
'''

with open(filepath, 'w') as f:
    f.write(new_code)
print("Rewrote worker_dashboard_screen.dart")
