import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../services/notification_service.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/booking/data/booking_repository.dart';
import '../../features/profile/data/profile_repository.dart';

/// Widget that listens for real-time events and triggers notifications.
/// Designed to be placed in the widget tree once, typically at your root/home screen.
class NotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationListener({super.key, required this.child});

  @override
  ConsumerState<NotificationListener> createState() =>
      _NotificationListenerState();
}

class _NotificationListenerState extends ConsumerState<NotificationListener> {
  RealtimeChannel? _messageChannel;
  RealtimeChannel? _bookingChannel;
  RealtimeChannel? _newRequestChannel;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    final client = Supabase.instance.client;
    final user = ref.read(customAuthProvider);
    if (user == null) return;

    // Listen for new chat messages sent TO this user
    _messageChannel = client
        .channel('notif_messages_${user.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_user_id',
            value: user.userId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            final senderId = data['sender_user_id'] as String?;

            // Skip self-notifications
            if (senderId == user.userId) return;

            final content = data['message_content'] as String? ?? 'New message';
            final type = data['message_type'] as String? ?? 'text';

            String title = 'New Message';
            String body = content;
            NotificationType nType = NotificationType.message;

            if (content.startsWith('💰')) {
              title = 'New Bid Received';
              body = 'Someone placed a bid on your request';
              nType = NotificationType.bid;
            } else if (content.startsWith('✅')) {
              title = 'Bid Accepted!';
              body = 'Your bid has been accepted';
              nType = NotificationType.booking;
            } else if (content.startsWith('🎉')) {
              title = 'Booking Confirmed!';
              body = 'A booking has been confirmed';
              nType = NotificationType.booking;
            } else if (type == 'image') {
              body = '📷 Sent you an image';
            }

            // Push to notification state
            ref.read(notificationProvider.notifier).push(
                  AppNotification(
                    id: const Uuid().v4(),
                    title: title,
                    body: body,
                    route: data['request_id'] as String?,
                    type: nType,
                  ),
                );

            // Show overlay banner if the widget is still mounted
            if (mounted) {
              showInAppNotification(
                context,
                title: title,
                body: body,
                type: nType,
              );
            }
          },
        )
        .subscribe();

    // Listen for booking status changes
    _bookingChannel = client
        .channel('notif_bookings_${user.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'service_requests',
          callback: (payload) {
            final data = payload.newRecord;
            final status = data['status'] as String?;
            final userId = data['user_id'] as String?;
            final workerId = data['worker_id'] as String?;

            // Only notify if this booking involves our user
            if (userId != user.userId && workerId != user.userId) return;

            String? title;
            String? body;
            NotificationType nType = NotificationType.booking;

            switch (status) {
              case 'in_progress':
                title = 'Work Started';
                body = 'A worker has started working on your request';
                break;
              case 'completed':
                title = 'Work Completed! 🎉';
                body = 'The worker has finished the job';
                nType = NotificationType.workComplete;
                break;
              case 'cancelled':
                title = 'Booking Cancelled';
                body = 'A booking has been cancelled';
                break;
            }

            if (title != null && body != null) {
              ref.read(notificationProvider.notifier).push(
                    AppNotification(
                      id: const Uuid().v4(),
                      title: title,
                      body: body,
                      route: data['request_id'] as String?,
                      type: nType,
                    ),
                  );

              if (mounted) {
                showInAppNotification(context,
                    title: title, body: body, type: nType);
              }

              // Refresh pending requests for worker dashboard
              _invalidatePendingRequests();
            }
          },
        )
        .subscribe();

    // Listen for NEW service requests (assigned to this user as worker)
    _newRequestChannel = client
        .channel('notif_new_requests_${user.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'service_requests',
          callback: (payload) {
            final data = payload.newRecord;
            final workerId = data['worker_id'] as String?;

            // Check if this request is for our worker profile
            final workerProfileAsync =
                ref.read(workerProfileByUserIdProvider(user.userId));
            final workerProfile = workerProfileAsync.valueOrNull;
            if (workerProfile != null && workerId == workerProfile.workerId) {
              // Refresh pending requests
              ref.invalidate(pendingRequestsProvider(workerProfile.workerId));

              ref.read(notificationProvider.notifier).push(
                    AppNotification(
                      id: const Uuid().v4(),
                      title: 'New Service Request',
                      body: 'You have a new pending request',
                      route: data['request_id'] as String?,
                      type: NotificationType.booking,
                    ),
                  );

              if (mounted) {
                showInAppNotification(
                  context,
                  title: 'New Service Request',
                  body: 'You have a new pending request',
                  type: NotificationType.booking,
                );
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();
    _bookingChannel?.unsubscribe();
    _newRequestChannel?.unsubscribe();
    super.dispose();
  }

  void _invalidatePendingRequests() {
    final user = ref.read(customAuthProvider);
    if (user == null) return;
    final workerProfileAsync =
        ref.read(workerProfileByUserIdProvider(user.userId));
    final workerProfile = workerProfileAsync.valueOrNull;
    if (workerProfile != null) {
      ref.invalidate(pendingRequestsProvider(workerProfile.workerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
