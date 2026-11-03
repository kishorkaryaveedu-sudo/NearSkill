import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/worker_model.dart';
import '../../booking/data/booking_repository.dart';
import '../../booking/domain/booking_model.dart';

final allUsersProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.watch(authRepositoryProvider).getAllUsers();
});

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NearSkill',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: -0.3)),
                Text('Admin Control',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ],
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Refresh all data',
            onPressed: () {
              ref.invalidate(allUsersProvider);
              ref.invalidate(allWorkersProvider);
              ref.invalidate(allRequestsProvider);
              ref.invalidate(allReviewsProvider);
              ref.invalidate(allSupportTicketsProvider);
              ref.invalidate(adminSkillsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Workers', icon: Icon(Icons.engineering_rounded, size: 18)),
            Tab(text: 'Users', icon: Icon(Icons.people_rounded, size: 18)),
            Tab(text: 'Bookings', icon: Icon(Icons.receipt_long_rounded, size: 18)),
            Tab(text: 'Skills', icon: Icon(Icons.build_rounded, size: 18)),
            Tab(text: 'Reviews', icon: Icon(Icons.rate_review_rounded, size: 18)),
            Tab(text: 'Support', icon: Icon(Icons.support_agent_rounded, size: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          const _DashboardStats(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _WorkersTab(),
                _UsersTab(),
                _BookingsTab(),
                _SkillsTab(),
                _ReviewsTab(),
                _SupportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Stats (Stitch "Action Items") ───────
class _DashboardStats extends ConsumerWidget {
  const _DashboardStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(allWorkersProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final bookingsAsync = ref.watch(allRequestsProvider);
    final ticketsAsync = ref.watch(allSupportTicketsProvider);

    final pendingWorkers = workersAsync.maybeWhen(
      data: (d) => d.where((w) => w.verificationStatus == 'pending').length,
      orElse: () => 0,
    );

    return Column(
      children: [
        // Stitch amber alert banner: "X Pending — Verifications require attention"
        if (pendingWorkers > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.secondaryContainer,
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded,
                    color: AppColors.onSecondaryContainer, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$pendingWorkers Pending — Verifications require attention',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Stats row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            boxShadow: [
              BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              _StatCard(
                label: 'Active Users',
                value: usersAsync.maybeWhen(
                    data: (d) => '${d.length}', orElse: () => '–'),
                icon: Icons.people_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Active Workers',
                value: workersAsync.maybeWhen(
                    data: (d) => '${d.where((w) => w.availabilityStatus).length}',
                    orElse: () => '–'),
                icon: Icons.engineering_rounded,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Bookings',
                value: bookingsAsync.maybeWhen(
                    data: (d) => '${d.length}', orElse: () => '–'),
                icon: Icons.receipt_long_rounded,
                color: AppColors.tertiary,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Open Tickets',
                value: ticketsAsync.maybeWhen(
                    data: (d) =>
                        '${d.where((t) => t.status != 'resolved').length}',
                    orElse: () => '–'),
                icon: Icons.support_agent_rounded,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.85)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Workers Tab ───────────────────────────────────

class _WorkersTab extends ConsumerStatefulWidget {
  const _WorkersTab();

  @override
  ConsumerState<_WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends ConsumerState<_WorkersTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(allWorkersProvider);

    return Column(
      children: [
        _SearchBar(
          hint: 'Search workers...',
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
        ),
        Expanded(
          child: workersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (workers) {
              final filtered = _search.isEmpty
                  ? workers
                  : workers
                      .where((w) =>
                          w.displayName.toLowerCase().contains(_search))
                      .toList();
              if (filtered.isEmpty) {
                return Center(
                    child: Text(_search.isEmpty
                        ? 'No workers registered'
                        : 'No matching workers'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(allWorkersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _WorkerCard(worker: filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WorkerCard extends ConsumerWidget {
  final WorkerProfileModel worker;
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    IconData statusIcon;
    switch (worker.verificationStatus) {
      case 'verified':
        statusColor = AppColors.success;
        statusIcon = Icons.verified;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.accent;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                backgroundImage: worker.profilePhotoUrl != null
                    ? NetworkImage(worker.profilePhotoUrl!)
                    : null,
                child: worker.profilePhotoUrl == null
                    ? Text(worker.displayName[0].toUpperCase(),
                        style: TextStyle(
                            color: statusColor, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.displayName,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(worker.verificationStatus.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(worker.averageRating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textMuted)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          if (worker.hasIdCard) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('ID: ${worker.idCardType ?? 'Uploaded'}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showIdCard(context, worker.idCardUrl!),
                    child: Text('View',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
          if (worker.verificationStatus == 'pending' && worker.hasIdCard) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    onPressed: () async {
                      await ref.read(profileRepositoryProvider).rejectWorker(
                          worker.workerId,
                          notes: 'Rejected by admin');
                      ref.invalidate(allWorkersProvider);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Verify'),
                    onPressed: () async {
                      await ref.read(profileRepositoryProvider).verifyWorker(
                          worker.workerId,
                          notes: 'Verified by admin');
                      ref.invalidate(allWorkersProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (worker.verificationStatus == 'verified') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.remove_circle_outline, size: 16),
                label: const Text('Revoke Verification'),
                onPressed: () async {
                  await ref.read(profileRepositoryProvider).rejectWorker(
                      worker.workerId,
                      notes: 'Verification revoked by admin');
                  ref.invalidate(allWorkersProvider);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
              ),
            ),
          ],
          if (worker.verificationStatus == 'rejected') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.verified_outlined, size: 16),
                label: const Text('Re-Verify'),
                onPressed: () async {
                  await ref.read(profileRepositoryProvider).verifyWorker(
                      worker.workerId,
                      notes: 'Re-verified by admin');
                  ref.invalidate(allWorkersProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showIdCard(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(dialogCtx),
          child: Consumer(
            builder: (context, ref, _) {
              return FutureBuilder<String>(
                future: ref
                    .read(profileRepositoryProvider)
                    .getSignedIdCardUrl(url),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: Text(
                            'Failed to load image.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: AppColors.error)),
                      ),
                    );
                  }
                  return InteractiveViewer(
                    child: Image.network(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, stack) => Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(8))),
                          child: Text('Failed to load image.\n$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.error)),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Users Tab (FIXED: uses provider, not FutureBuilder) ─────

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Column(
      children: [
        _SearchBar(
          hint: 'Search users by name or email...',
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (users) {
              final filtered = _search.isEmpty
                  ? users
                  : users
                      .where((u) =>
                          u.fullName.toLowerCase().contains(_search) ||
                          u.email.toLowerCase().contains(_search))
                      .toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('No users found'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(allUsersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _UserCard(user: filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserModel user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: user.isBanned
            ? AppColors.error.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: user.isBanned
            ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
            : null,
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: user.isBanned
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: user.profilePhotoUrl != null
                ? NetworkImage(user.profilePhotoUrl!)
                : null,
            child: user.profilePhotoUrl == null
                ? Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: user.isBanned
                            ? AppColors.error
                            : AppColors.primary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(user.fullName,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    if (user.isBanned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Text('BANNED',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                Text(user.email,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: user.isAdmin
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Text(user.role.toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        user.isAdmin ? AppColors.error : AppColors.primary)),
          ),
          if (!user.isAdmin) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                user.isBanned ? Icons.lock_open : Icons.block,
                color: user.isBanned ? AppColors.success : AppColors.error,
                size: 20,
              ),
              tooltip: user.isBanned ? 'Unban' : 'Ban',
              onPressed: () => _confirmAction(
                context,
                ref,
                title: user.isBanned ? 'Unban User' : 'Ban User',
                message:
                    'Are you sure you want to ${user.isBanned ? 'unban' : 'ban'} ${user.fullName}?',
                confirmLabel: user.isBanned ? 'Unban' : 'Ban',
                confirmColor:
                    user.isBanned ? AppColors.success : AppColors.error,
                action: () async {
                  await ref
                      .read(authRepositoryProvider)
                      .toggleBanStatus(user.userId, !user.isBanned);
                  ref.invalidate(allUsersProvider);
                },
                successMessage:
                    '${user.fullName} has been ${user.isBanned ? 'unbanned' : 'banned'}',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              tooltip: 'Delete user',
              onPressed: () => _confirmAction(
                context,
                ref,
                title: 'Delete User',
                message:
                    'Are you sure you want to permanently delete ${user.fullName}? This cannot be undone.',
                confirmLabel: 'Delete',
                confirmColor: AppColors.error,
                action: () async {
                  await ref
                      .read(authRepositoryProvider)
                      .deleteUser(user.userId);
                  ref.invalidate(allUsersProvider);
                  ref.invalidate(allWorkersProvider);
                },
                successMessage: '${user.fullName} has been deleted',
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await action();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }
}

// ─── Bookings Tab ───────────────────────────────────

final allRequestsProvider = FutureProvider<List<ServiceRequestModel>>((ref) {
  return ref.watch(bookingRepositoryProvider).getAllRequests();
});

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(allRequestsProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        if (bookings.isEmpty) return const Center(child: Text('No bookings'));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allRequestsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (_, i) {
              final b = bookings[i];
              Color sc;
              switch (b.status) {
                case ServiceRequestStatus.completed:
                  sc = AppColors.success;
                  break;
                case ServiceRequestStatus.inProgress:
                  sc = AppColors.info;
                  break;
                case ServiceRequestStatus.accepted:
                  sc = AppColors.info;
                  break;
                case ServiceRequestStatus.cancelled:
                  sc = AppColors.error;
                  break;
                default:
                  sc = AppColors.accent;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Icon(Icons.receipt, color: sc, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder(
                        future: Future.wait([
                          ref
                              .read(authRepositoryProvider)
                              .getUserById(b.userId),
                          ref
                              .read(profileRepositoryProvider)
                              .getWorkerProfile(b.workerId),
                        ]),
                        builder: (context,
                            AsyncSnapshot<List<dynamic>> snapNames) {
                          if (!snapNames.hasData) {
                            return const SizedBox.shrink();
                          }
                          final userName =
                              (snapNames.data![0] as UserModel?)?.fullName ??
                                  'Unknown User';
                          final workerName = (snapNames.data![1]
                                      as WorkerProfileModel?)
                                  ?.displayName ??
                              'Unknown Worker';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$userName → $workerName',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(
                                  DateFormat('MMM d, HH:mm')
                                      .format(b.createdAt),
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            ],
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Text(b.status.displayName,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: sc)),
                    ),
                    if (b.agreedPrice != null) ...[
                      const SizedBox(width: 8),
                      Text('₹${b.agreedPrice!.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              fontSize: 14)),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Skills Tab ───────────────────────────────────

class _SkillsTab extends ConsumerStatefulWidget {
  const _SkillsTab();

  @override
  ConsumerState<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends ConsumerState<_SkillsTab> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(adminSkillsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add new skill...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  final name = _controller.text.trim();
                  if (name.isEmpty) return;
                  await ref.read(profileRepositoryProvider).addSkill(name);
                  _controller.clear();
                  ref.invalidate(adminSkillsProvider);
                  ref.invalidate(allSkillsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: skillsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (skills) {
              if (skills.isEmpty) {
                return const Center(child: Text('No skills added'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: skills.length,
                itemBuilder: (_, i) {
                  final s = skills[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            s.status == 'approved'
                                ? Icons.handyman
                                : Icons.pending_actions,
                            size: 18,
                            color: s.status == 'approved'
                                ? AppColors.primary
                                : AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.skillName,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500)),
                              if (s.status == 'pending')
                                Text('Suggested by worker',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.accent)),
                            ],
                          ),
                        ),
                        if (s.status == 'pending') ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline,
                                color: AppColors.success, size: 20),
                            onPressed: () async {
                              await ref
                                  .read(profileRepositoryProvider)
                                  .updateSkillStatus(s.skillId, 'approved');
                              ref.invalidate(adminSkillsProvider);
                              ref.invalidate(allSkillsProvider);
                            },
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error, size: 20),
                          onPressed: () async {
                            await ref
                                .read(profileRepositoryProvider)
                                .deleteSkill(s.skillId);
                            ref.invalidate(adminSkillsProvider);
                            ref.invalidate(allSkillsProvider);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Reviews Tab ───────────────────────────────────

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(allReviewsProvider);

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(child: Text('No reviews found.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allReviewsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.star, size: 20),
                            const SizedBox(width: 4),
                            Text(review.rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(review.createdAt),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder(
                      future: Future.wait([
                        ref
                            .read(authRepositoryProvider)
                            .getUserById(review.reviewerUserId),
                        ref
                            .read(profileRepositoryProvider)
                            .getWorkerProfile(review.ratedWorkerId),
                      ]),
                      builder:
                          (context, AsyncSnapshot<List<dynamic>> snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final user = snapshot.data![0] as UserModel?;
                        final workerProfile =
                            snapshot.data![1] as WorkerProfileModel?;
                        final workerName =
                            workerProfile?.displayName ?? 'Unknown Worker';
                        final userName = user?.fullName ?? 'Unknown User';

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Reviewed by ',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                    children: [
                                      TextSpan(
                                          text: userName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary)),
                                      const TextSpan(text: ' for '),
                                      TextSpan(
                                          text: workerName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (review.comment != null && review.comment!.isNotEmpty)
                      Text(review.comment!,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary, height: 1.4)),
                    if (review.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        child: Image.network(
                          review.imageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Support Tab (improved with status filter) ─────

class _SupportTab extends ConsumerStatefulWidget {
  const _SupportTab();

  @override
  ConsumerState<_SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends ConsumerState<_SupportTab> {
  String _filter = 'all'; // all, open, resolved

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(allSupportTicketsProvider);

    return Column(
      children: [
        // Status filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _FilterChip(
                  label: 'All',
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Open',
                  isSelected: _filter == 'open',
                  color: AppColors.accent,
                  onTap: () => setState(() => _filter = 'open')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Resolved',
                  isSelected: _filter == 'resolved',
                  color: AppColors.success,
                  onTap: () => setState(() => _filter = 'resolved')),
            ],
          ),
        ),
        Expanded(
          child: ticketsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (tickets) {
              final filtered = _filter == 'all'
                  ? tickets
                  : tickets.where((t) => t.status == _filter).toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('No tickets found.'));
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(allSupportTicketsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ticket = filtered[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        border: ticket.status == 'open'
                            ? Border.all(
                                color:
                                    AppColors.accent.withValues(alpha: 0.3))
                            : null,
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ticket.status == 'resolved'
                                      ? AppColors.success
                                          .withValues(alpha: 0.1)
                                      : AppColors.accent
                                          .withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Text(
                                  ticket.status.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ticket.status == 'resolved'
                                        ? AppColors.success
                                        : AppColors.accent,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, yyyy – h:mm a')
                                    .format(ticket.createdAt),
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          if (ticket.subject != null &&
                              ticket.subject!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(ticket.subject!,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                          const SizedBox(height: 8),
                          FutureBuilder<UserModel?>(
                            future: ref
                                .read(authRepositoryProvider)
                                .getUserById(ticket.userId),
                            builder: (context, userSnap) {
                              final userName =
                                  userSnap.data?.fullName ?? 'Unknown User';
                              return Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(userName,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.primary)),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(ticket.message,
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary, height: 1.4)),
                          if (ticket.adminResponse != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: 0.08),
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                border: Border.all(
                                    color: AppColors.success
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.admin_panel_settings,
                                          size: 14,
                                          color: AppColors.success),
                                      const SizedBox(width: 6),
                                      Text('Admin Response',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppColors.success)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(ticket.adminResponse!,
                                      style: GoogleFonts.inter(
                                          color: AppColors.textPrimary,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.reply, size: 16),
                                label: const Text('Reply to Ticket'),
                                onPressed: () => _showReplyDialog(
                                    context, ref, ticket),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8))),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showReplyDialog(BuildContext context, WidgetRef ref, dynamic ticket) {
    final controller = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            title: Text('Reply to Ticket',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Text(ticket.message,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type your response...',
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (controller.text.trim().isEmpty) return;
                        setState(() => isSubmitting = true);
                        try {
                          await ref
                              .read(profileRepositoryProvider)
                              .replyToSupportTicket(
                                  ticket.ticketId, controller.text.trim());
                          if (context.mounted) {
                            Navigator.pop(context);
                            ref.invalidate(allSupportTicketsProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reply sent!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8))),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                          setState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Send Reply'),
              ),
            ],
          );
        });
      },
    );
  }
}

// ─── Shared Widgets ────────────────────────────────

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              color: AppColors.textMuted, fontSize: 13),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide:
                BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.isSelected,
      this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c : Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(
              color: isSelected ? c : AppColors.border, width: 1.5),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}
