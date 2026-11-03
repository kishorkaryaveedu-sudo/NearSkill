import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';

/// In-app notification model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? route; // optional: requestId or screen to navigate to
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.route,
    this.type = NotificationType.info,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

enum NotificationType { message, bid, booking, workComplete, info }

/// Notification state notifier
class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier() : super([]);

  /// Add a new notification and show an overlay
  void push(AppNotification notification) {
    state = [notification, ...state];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) (n..isRead = true) else n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n..isRead = true];
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

/// Provider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier();
});

/// Helper to show an in-app toast/banner notification
void showInAppNotification(
  BuildContext context, {
  required String title,
  required String body,
  NotificationType type = NotificationType.info,
  VoidCallback? onTap,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _NotificationBanner(
      title: title,
      body: body,
      type: type,
      onTap: () {
        entry.remove();
        onTap?.call();
      },
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);

  // Auto-dismiss after 4 seconds
  Future.delayed(const Duration(seconds: 4), () {
    if (entry.mounted) entry.remove();
  });
}

/// The overlay banner widget
class _NotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final NotificationType type;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.type,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.type) {
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.bid:
        return Icons.gavel;
      case NotificationType.booking:
        return Icons.event_available;
      case NotificationType.workComplete:
        return Icons.check_circle;
      case NotificationType.info:
        return Icons.notifications;
    }
  }

  Color get _color {
    switch (widget.type) {
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.bid:
        return AppColors.accent;
      case NotificationType.booking:
        return AppColors.success;
      case NotificationType.workComplete:
        return AppColors.success;
      case NotificationType.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy < -100) {
              widget.onDismiss();
            }
          },
          child: Material(
            elevation: 8,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            shadowColor: Colors.black26,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: _color.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, color: _color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 2),
                        Text(widget.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            )),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(Icons.close,
                        size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
