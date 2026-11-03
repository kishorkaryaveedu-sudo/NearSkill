import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../booking/data/booking_repository.dart';
import '../../booking/domain/booking_model.dart';
import '../../profile/data/profile_repository.dart';
import '../data/chat_repository.dart';
import 'chat_screen.dart';

/// Messages / Inbox screen — Stitch "Hyper-Local Trust"
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(customAuthProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }
    final isWorkerAsync = ref.watch(isWorkerProvider(user.userId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Text(
                    'Messages',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // ── Conversations ───────────────────────────────
            Expanded(
              child: isWorkerAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) =>
                    Center(child: Text('Error: $e')),
                data: (isWorker) {
                  if (!isWorker) {
                    final requests =
                        ref.watch(userRequestsProvider(user.userId));
                    return _buildList(ref, requests, isWorker: false);
                  }
                  final wpAsync = ref.watch(
                      workerProfileByUserIdProvider(user.userId));
                  return wpAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (e, _) =>
                        Center(child: Text('Error: $e')),
                    data: (wp) {
                      if (wp == null) {
                        return const Center(
                            child: Text('Worker profile not found'));
                      }
                      final requests =
                          ref.watch(workerRequestsProvider(wp.workerId));
                      return _buildList(ref, requests, isWorker: true);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(WidgetRef ref, AsyncValue<List<dynamic>> requests,
      {required bool isWorker}) {
    return requests.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final active = all.where((r) {
          return r.status != ServiceRequestStatus.completed &&
              r.status != ServiceRequestStatus.cancelled;
        }).toList();

        if (active.isEmpty) {
          return _buildEmpty();
        }

        return ListView.builder(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: active.length,
          itemBuilder: (ctx, i) => _ConversationTile(
            request: active[i],
            isWorker: isWorker,
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: AppColors.outline),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Book a pro to start chatting.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final dynamic request;
  final bool isWorker;
  const _ConversationTile({required this.request, required this.isWorker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isWorker) {
      return _buildForUser(context, ref, request.userId);
    }
    final wpAsync = ref.watch(workerProfileProvider(request.workerId));
    return wpAsync.when(
      loading: () => _shimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (wp) {
        if (wp == null) return const SizedBox.shrink();
        return _buildForUser(context, ref, wp.userId);
      },
    );
  }

  Widget _buildForUser(
      BuildContext context, WidgetRef ref, String otherUserId) {
    final profileAsync = ref.watch(userProfileProvider(otherUserId));
    return profileAsync.when(
      loading: () => _shimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final lastMsgAsync =
            ref.watch(latestMessageProvider(request.requestId));
        final currentUser = ref.watch(customAuthProvider);

        String snippet = 'Tap to open conversation';
        bool hasUnread = false;

        lastMsgAsync.whenData((msg) {
          if (msg != null) {
            snippet = msg.messageContent.startsWith('💰')
                ? '💰 New bid placed'
                : msg.messageContent.startsWith('✅')
                    ? '✅ Bid accepted'
                    : msg.messageContent;
            hasUnread =
                currentUser != null &&
                    msg.senderUserId != currentUser.userId;
          }
        });

        final statusColor = _statusColor(request.status);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                requestId: request.requestId,
                otherUserId: otherUserId,
                otherUserName: profile.fullName,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasUnread
                  ? AppColors.primaryFixed.withOpacity(0.15)
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasUnread
                    ? AppColors.primary.withOpacity(0.25)
                    : AppColors.outlineVariant.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with status dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryFixed,
                      backgroundImage: profile.profilePhotoUrl?.isNotEmpty ==
                              true
                          ? NetworkImage(profile.profilePhotoUrl!)
                          : null,
                      child: profile.profilePhotoUrl?.isNotEmpty != true
                          ? Text(
                              profile.fullName.isNotEmpty
                                  ? profile.fullName[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: AppColors.onPrimaryFixed,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name + snippet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: GoogleFonts.inter(
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        snippet,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: hasUnread
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                          fontWeight: hasUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Time + unread dot
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(request.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: hasUnread
                            ? AppColors.primary
                            : AppColors.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 26, backgroundColor: AppColors.surfaceContainerHigh),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 120, height: 13,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(
                  width: 180, height: 11,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(6))),
            ],
          ),
        ],
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
        return AppColors.outline;
      case ServiceRequestStatus.cancelled:
        return AppColors.error;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dt);
  }
}
