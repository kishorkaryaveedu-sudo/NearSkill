import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/data/auth_repository.dart';
import '../../booking/data/booking_repository.dart';
import '../../booking/domain/booking_model.dart';
import '../../booking/domain/review_model.dart';
import '../data/chat_repository.dart';
import '../domain/message_model.dart';

// Bid message prefix conventions
const _bidPrefix = '💰 PRICE BID: ₹';
const _acceptPrefix = '✅ BID ACCEPTED: ₹';
const _bookingConfirmed = '🎉 BOOKING CONFIRMED';

bool _isBidMessage(String content) =>
    content.startsWith(_bidPrefix) ||
    content.startsWith(_acceptPrefix) ||
    content.startsWith(_bookingConfirmed);

double? _extractBidAmount(String content) {
  if (content.startsWith(_bidPrefix)) {
    final numStr = content.substring(_bidPrefix.length).trim();
    return double.tryParse(numStr);
  }
  if (content.startsWith(_acceptPrefix)) {
    final numStr = content.substring(_acceptPrefix.length).trim();
    return double.tryParse(numStr);
  }
  return null;
}

/// Provider to watch a specific service request in real time
final requestStreamProvider =
    StreamProvider.family<ServiceRequestModel?, String>((ref, requestId) {
  return ref.watch(bookingRepositoryProvider).getRequestStream(requestId);
});

/// Provider to check if a review exists for a service request
final reviewForRequestProvider =
    FutureProvider.family<ReviewModel?, String>((ref, requestId) {
  return ref.read(bookingRepositoryProvider).getReviewForRequest(requestId);
});

/// Chat screen for real-time messaging with live bidding
class ChatScreen extends ConsumerStatefulWidget {
  final String requestId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  // Review System State
  double _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmittingReview = false;
  Uint8List? _reviewImageBytes;
  String? _reviewImageName;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first')),
      );
      return;
    }

    final currentUser = ref.read(customAuthProvider);
    final request = ref.read(requestStreamProvider(widget.requestId)).value;
    if (currentUser == null || request == null) return;

    setState(() => _isSubmittingReview = true);

    try {
      String? imageUrl;
      // Upload review image if selected
      if (_reviewImageBytes != null) {
        imageUrl = await ref.read(bookingRepositoryProvider).uploadReviewImage(
              requestId: widget.requestId,
              imageBytes: _reviewImageBytes!,
              fileName: _reviewImageName ?? 'review.jpg',
            );
      }

      await ref.read(bookingRepositoryProvider).submitReview(
            requestId: widget.requestId,
            reviewerUserId: currentUser.userId,
            ratedWorkerId: request.workerId,
            rating: _rating,
            comment: _reviewController.text.trim(),
            imageUrl: imageUrl,
          );

      // Recalculate the worker's average rating
      await ref
          .read(bookingRepositoryProvider)
          .recalculateWorkerRating(request.workerId);

      // Invalidate the review provider to refresh UI
      ref.invalidate(reviewForRequestProvider(widget.requestId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = ref.read(customAuthProvider);
    if (currentUser == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            requestId: widget.requestId,
            senderUserId: currentUser.userId,
            receiverUserId: widget.otherUserId,
            messageContent: text,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;

    final currentUser = ref.read(customAuthProvider);
    if (currentUser == null) return;

    setState(() => _isSending = true);
    try {
      final bytes = await picked.readAsBytes();
      await ref.read(chatRepositoryProvider).sendImageMessage(
            requestId: widget.requestId,
            senderUserId: currentUser.userId,
            receiverUserId: widget.otherUserId,
            imageBytes: bytes,
            fileName: picked.name,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error sending image: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendBid(double amount) async {
    final currentUser = ref.read(customAuthProvider);
    if (currentUser == null) return;

    try {
      await ref.read(bookingRepositoryProvider).updateRequestStatus(
            widget.requestId,
            ServiceRequestStatus.pending,
            agreedPrice: amount,
          );
      await ref.read(chatRepositoryProvider).sendMessage(
            requestId: widget.requestId,
            senderUserId: currentUser.userId,
            receiverUserId: widget.otherUserId,
            messageContent: '$_bidPrefix${amount.toStringAsFixed(0)}',
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending bid: $e')),
        );
      }
    }
  }

  Future<void> _acceptBid(double amount) async {
    final currentUser = ref.read(customAuthProvider);
    if (currentUser == null) return;

    try {
      await ref.read(bookingRepositoryProvider).acceptRequest(
            widget.requestId,
            agreedPrice: amount,
          );
      await ref.read(chatRepositoryProvider).sendMessage(
            requestId: widget.requestId,
            senderUserId: currentUser.userId,
            receiverUserId: widget.otherUserId,
            messageContent: '$_acceptPrefix${amount.toStringAsFixed(0)}',
          );
      await ref.read(chatRepositoryProvider).sendMessage(
            requestId: widget.requestId,
            senderUserId: currentUser.userId,
            receiverUserId: widget.otherUserId,
            messageContent:
                '$_bookingConfirmed at ₹${amount.toStringAsFixed(0)}! 🤝',
          );
      ref.invalidate(userRequestsProvider(currentUser.userId));
      ref.invalidate(workerRequestsProvider(currentUser.userId));
      ref.invalidate(pendingRequestsProvider(currentUser.userId));
      ref.invalidate(userRequestsProvider(widget.otherUserId));
      ref.invalidate(workerRequestsProvider(widget.otherUserId));
      ref.invalidate(pendingRequestsProvider(widget.otherUserId));
      _scrollToBottom();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting bid: $e')),
        );
      }
    }
  }

  Future<void> _updateBookingStatus(ServiceRequestStatus newStatus) async {
    try {
      if (newStatus == ServiceRequestStatus.inProgress) {
        await ref
            .read(bookingRepositoryProvider)
            .startRequest(widget.requestId);
      } else if (newStatus == ServiceRequestStatus.completed) {
        await ref
            .read(bookingRepositoryProvider)
            .completeRequest(widget.requestId);
      } else if (newStatus == ServiceRequestStatus.cancelled) {
        await ref
            .read(bookingRepositoryProvider)
            .cancelRequest(widget.requestId);
      }

      final currentUser = ref.read(customAuthProvider);
      if (currentUser != null) {
        ref.invalidate(userRequestsProvider(currentUser.userId));
        ref.invalidate(workerRequestsProvider(currentUser.userId));
        ref.invalidate(pendingRequestsProvider(currentUser.userId));
      }
      ref.invalidate(userRequestsProvider(widget.otherUserId));
      ref.invalidate(workerRequestsProvider(widget.otherUserId));
      ref.invalidate(pendingRequestsProvider(widget.otherUserId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showBidDialog({double? currentAmount}) {
    final priceController = TextEditingController(
      text: currentAmount != null ? currentAmount.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child:
                  const Icon(Icons.gavel, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              currentAmount != null ? 'Counter Offer' : 'Make an Offer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentAmount != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Current: ₹${currentAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style:
                  GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                hintText: '0',
                hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.4)),
                filled: true,
                fillColor: AppColors.background,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final text = priceController.text.trim();
              if (text.isNotEmpty) {
                final amount = double.tryParse(text);
                if (amount != null && amount > 0) {
                  Navigator.pop(ctx);
                  _sendBid(amount);
                }
              }
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Offer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.requestId));
    final requestAsync = ref.watch(requestStreamProvider(widget.requestId));
    final currentUser = ref.watch(customAuthProvider);
    // Resolve the real name from DB
    final otherUserAsync = ref.watch(userProfileProvider(widget.otherUserId));
    final resolvedName = otherUserAsync.whenOrNull(data: (u) => u?.fullName) ??
        widget.otherUserName;
    final resolvedPhoto =
        otherUserAsync.whenOrNull(data: (u) => u?.profilePhotoUrl) ??
            widget.otherUserPhoto;

    final currentPrice = requestAsync.whenOrNull(data: (r) => r?.agreedPrice);
    final requestStatus = requestAsync.whenOrNull(data: (r) => r?.status);
    final isAccepted = requestStatus == ServiceRequestStatus.accepted ||
        requestStatus == ServiceRequestStatus.inProgress ||
        requestStatus == ServiceRequestStatus.completed;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: resolvedPhoto?.isNotEmpty == true
                  ? Image.network(
                      resolvedPhoto!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          resolvedName.isNotEmpty
                              ? resolvedName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        resolvedName.isNotEmpty
                            ? resolvedName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  _StatusBadge(status: requestStatus),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isAccepted)
            IconButton(
              icon: const Icon(Icons.gavel_rounded, color: Colors.white70),
              tooltip: 'Place Bid',
              onPressed: () => _showBidDialog(currentAmount: currentPrice),
            ),
          // Booking action button based on status
          if (requestStatus == ServiceRequestStatus.accepted)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (val) {
                if (val == 'start') {
                  _updateBookingStatus(ServiceRequestStatus.inProgress);
                }
                if (val == 'cancel') {
                  _updateBookingStatus(ServiceRequestStatus.cancelled);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'start',
                    child: Row(children: [
                      Icon(Icons.play_circle_fill,
                          color: AppColors.info, size: 20),
                      SizedBox(width: 8),
                      Text('Start Work'),
                    ])),
                const PopupMenuItem(
                    value: 'cancel',
                    child: Row(children: [
                      Icon(Icons.cancel, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Cancel Booking'),
                    ])),
              ],
            ),
          if (requestStatus == ServiceRequestStatus.inProgress)
            TextButton.icon(
              onPressed: () =>
                  _updateBookingStatus(ServiceRequestStatus.completed),
              icon: const Icon(Icons.check_circle,
                  size: 18, color: AppColors.success),
              label: Text('Done',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: AppColors.success)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Price/status bar
          if (currentPrice != null)
            _BidStatusBar(
              price: currentPrice,
              status: requestStatus,
              onPlaceBid: () => _showBidDialog(currentAmount: currentPrice),
            ),

          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined,
                            size: 64,
                            color: AppColors.textMuted.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(AppStrings.startConversation,
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showBidDialog(),
                          icon: const Icon(Icons.gavel, size: 16),
                          label: const Text('Make an Offer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                // Find the LAST bid message that is from the OTHER person (not me)
                // Only that one gets accept/counter buttons
                int? lastIncomingBidIndex;
                for (int i = messages.length - 1; i >= 0; i--) {
                  final msg = messages[i];
                  if (msg.messageContent.startsWith(_bidPrefix) &&
                      msg.senderUserId != currentUser?.userId) {
                    lastIncomingBidIndex = i;
                    break;
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderUserId == currentUser?.userId;
                    final showDate = index == 0 ||
                        !_isSameDay(
                          messages[index - 1].timestamp,
                          message.timestamp,
                        );

                    if (_isBidMessage(message.messageContent)) {
                      // Only the LAST incoming bid gets action buttons
                      final isLastIncomingBid =
                          index == lastIncomingBidIndex && !isAccepted;

                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(message.timestamp),
                          _BidCard(
                            message: message,
                            isMe: isMe,
                            onAccept: isLastIncomingBid
                                ? () {
                                    final amount = _extractBidAmount(
                                        message.messageContent);
                                    if (amount != null) _acceptBid(amount);
                                  }
                                : null,
                            onCounter: isLastIncomingBid
                                ? () {
                                    final amount = _extractBidAmount(
                                        message.messageContent);
                                    _showBidDialog(currentAmount: amount);
                                  }
                                : null,
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(message.timestamp),
                        _MessageBubble(message: message, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input area or Review UI
          if (requestStatus == ServiceRequestStatus.completed &&
              requestAsync.value?.userId == currentUser?.userId)
            // Show review UI for the user if the job is completed
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5))),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: SafeArea(
                child: ref
                    .watch(reviewForRequestProvider(widget.requestId))
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error loading review: $e'),
                      data: (review) {
                        if (review != null) {
                          // Already reviewed
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: AppColors.accent, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'You rated this service ${review.rating.toStringAsFixed(1)} stars',
                                  style: GoogleFonts.inter(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Input review UI
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'How was the service?',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  onPressed: () {
                                    setState(() => _rating = index + 1.0);
                                  },
                                  icon: Icon(
                                    index < _rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: AppColors.star,
                                    size: 24,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _reviewController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Share your experience (optional)',
                                hintStyle: GoogleFonts.inter(
                                    color: AppColors.textMuted, fontSize: 13),
                                filled: true,
                                fillColor: AppColors.background,
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Image picker for review
                            if (_reviewImageBytes != null)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                                    child: Image.memory(
                                      _reviewImageBytes!,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _reviewImageBytes = null;
                                        _reviewImageName = null;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              GestureDetector(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1200,
                                    maxHeight: 1200,
                                    imageQuality: 80,
                                  );
                                  if (picked != null) {
                                    final bytes = await picked.readAsBytes();
                                    setState(() {
                                      _reviewImageBytes = bytes;
                                      _reviewImageName = picked.name;
                                    });
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                                    border: Border.all(
                                      color: AppColors.border,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo_outlined,
                                          size: 18,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 8),
                                      Text('Add Photo',
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    _isSubmittingReview ? null : _submitReview,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8))),
                                ),
                                child: _isSubmittingReview
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Submit Review'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
              ),
            )
          else if (requestStatus == ServiceRequestStatus.completed &&
              requestAsync.value?.userId != currentUser?.userId)
            // If completed and I am the worker, just show completed status message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5))),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'This service request is completed.',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            // Regular chat input area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5))),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Image picker button
                    GestureDetector(
                      onTap: _pickAndSendImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                        ),
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                    ),

                    // Bid shortcut
                    if (!isAccepted)
                      GestureDetector(
                        onTap: () =>
                            _showBidDialog(currentAmount: currentPrice),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: const Icon(Icons.gavel,
                              color: AppColors.accent, size: 20),
                        ),
                      ),

                    // Text field
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: AppStrings.typeMessage,
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Send button
                    GestureDetector(
                      onTap: _isSending ? null : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send,
                                size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String text;
    if (_isSameDay(date, now)) {
      text = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      text = 'Yesterday';
    } else {
      text = DateFormat('MMM d, yyyy').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Text(
            text,
            style:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─────────────────────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ServiceRequestStatus? status;
  const _StatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case ServiceRequestStatus.accepted:
        color = AppColors.success;
        label = 'Booked';
        break;
      case ServiceRequestStatus.inProgress:
        color = AppColors.info;
        label = 'In Progress';
        break;
      case ServiceRequestStatus.completed:
        color = AppColors.textMuted;
        label = 'Completed';
        break;
      case ServiceRequestStatus.cancelled:
        color = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.accent;
        label = 'Negotiating';
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bid Status Bar
// ─────────────────────────────────────────────────────────────

class _BidStatusBar extends StatelessWidget {
  final double price;
  final ServiceRequestStatus? status;
  final VoidCallback onPlaceBid;

  const _BidStatusBar({
    required this.price,
    required this.status,
    required this.onPlaceBid,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = status == ServiceRequestStatus.accepted ||
        status == ServiceRequestStatus.inProgress;
    final isCompleted = status == ServiceRequestStatus.completed;

    Color bgColor;
    String label;
    IconData icon;
    if (isCompleted) {
      bgColor = AppColors.textMuted;
      label = 'Completed';
      icon = Icons.check_circle;
    } else if (isAccepted) {
      bgColor = AppColors.success;
      label = 'Booking Confirmed';
      icon = Icons.check_circle;
    } else {
      bgColor = AppColors.accent;
      label = 'Current Bid';
      icon = Icons.gavel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bgColor.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(icon, color: bgColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                      color: bgColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
                Text('₹${price.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      color: bgColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
          ),
          if (!isAccepted && !isCompleted)
            TextButton(
              onPressed: onPlaceBid,
              style: TextButton.styleFrom(
                backgroundColor: bgColor.withValues(alpha: 0.1),
                foregroundColor: bgColor,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: Text('Counter',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bid Card
// ─────────────────────────────────────────────────────────────

class _BidCard extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onAccept;
  final VoidCallback? onCounter;

  const _BidCard({
    required this.message,
    required this.isMe,
    this.onAccept,
    this.onCounter,
  });

  @override
  Widget build(BuildContext context) {
    final content = message.messageContent;
    final isBid = content.startsWith(_bidPrefix);
    final isAccept = content.startsWith(_acceptPrefix);
    final isConfirmation = content.startsWith(_bookingConfirmed);
    final amount = _extractBidAmount(content);

    Color cardColor;
    IconData cardIcon;
    String cardTitle;

    if (isConfirmation) {
      cardColor = AppColors.success;
      cardIcon = Icons.celebration;
      cardTitle = 'Booking Confirmed!';
    } else if (isAccept) {
      cardColor = AppColors.success;
      cardIcon = Icons.check_circle;
      cardTitle = 'Bid Accepted';
    } else {
      cardColor = AppColors.accent;
      cardIcon = Icons.gavel;
      cardTitle = isMe ? 'You offered' : 'Offer received';
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: cardColor.withValues(alpha: 0.2)),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.06),
              ),
              child: Row(
                children: [
                  Icon(cardIcon, color: cardColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cardTitle,
                        style: GoogleFonts.inter(
                          color: cardColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ),
                  Text(message.formattedTime,
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),

            // Amount
            if (amount != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text('₹${amount.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: cardColor,
                    )),
              ),

            if (isConfirmation)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: Text(content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    )),
              ),

            // Actions — only for the latest incoming bid
            if (isBid && !isMe && onAccept != null) ...[
              Divider(height: 1, color: cardColor.withValues(alpha: 0.1)),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCounter,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text('Counter',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text('Accept',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isImage = message.isImage && message.imageUrl != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isImage) ...[
              GestureDetector(
                onTap: () => _showFullImage(context, message.imageUrl!),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 240, maxHeight: 300),
                    child: Image.network(
                      message.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          width: 200,
                          height: 150,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: isMe ? Colors.white : AppColors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => SizedBox(
                        width: 200,
                        height: 80,
                        child: Center(
                          child: Icon(Icons.broken_image,
                              color:
                                  isMe ? Colors.white54 : AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 6, top: 4),
                child: Text(message.formattedTime,
                    style: GoogleFonts.inter(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textMuted,
                      fontSize: 10,
                    )),
              ),
            ] else ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(message.messageContent,
                        style: GoogleFonts.inter(
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 3),
                    Text(message.formattedTime,
                        style: GoogleFonts.inter(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppColors.textMuted,
                          fontSize: 10,
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
