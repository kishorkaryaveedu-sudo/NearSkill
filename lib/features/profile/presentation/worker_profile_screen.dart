import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/location_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../../booking/data/booking_repository.dart';
import '../../booking/domain/review_model.dart';
import '../data/profile_repository.dart';
import '../domain/skill_model.dart';
import '../domain/support_ticket_model.dart';
import '../domain/worker_model.dart';

/// Worker-specific profile screen: shows stats, skills, availability, reviews
class WorkerProfileScreen extends ConsumerStatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  ConsumerState<WorkerProfileScreen> createState() =>
      _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends ConsumerState<WorkerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  WorkerProfileModel? _profile;
  List<SkillModel> _allSkills = [];
  List<SkillModel> _workerSkills = [];
  List<ReviewModel> _reviews = [];

  bool _isLoading = true;
  bool _isSaving = false;

  // Edit controllers
  final _rateCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _suggestSkillCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _rateCtrl.dispose();
    _expCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _suggestSkillCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = ref.read(customAuthProvider);
    if (user == null) return;

    final profileRepo = ref.read(profileRepositoryProvider);
    final bookingRepo = ref.read(bookingRepositoryProvider);

    final results = await Future.wait([
      profileRepo.getWorkerProfileByUserId(user.userId),
      profileRepo.getAllSkills(),
    ]);

    var profile = results[0] as WorkerProfileModel?;
    final allSkills = results[1] as List<SkillModel>;

    List<SkillModel> workerSkills = [];
    List<ReviewModel> reviews = [];

    if (profile != null) {
      final ws = await Future.wait([
        profileRepo.getWorkerSkills(profile.workerId),
        bookingRepo.getWorkerReviews(profile.workerId),
      ]);
      workerSkills = ws[0] as List<SkillModel>;
      reviews = ws[1] as List<ReviewModel>;
      _rateCtrl.text = profile.hourlyRate.toStringAsFixed(0);
      _expCtrl.text = profile.experienceYears.toString();

      _nameCtrl.text = user.fullName;
      _phoneCtrl.text = user.mobileNumber ?? '';

      // Refresh GPS location so worker appears correctly on the map
      final pos = await LocationUtils.getCurrentPosition();
      if (pos != null) {
        await profileRepo.updateWorkerLocation(
            profile.workerId, pos.latitude, pos.longitude);
        profile = WorkerProfileModel(
          workerId: profile.workerId,
          userId: profile.userId,
          profilePhotoUrl: profile.profilePhotoUrl,
          experienceYears: profile.experienceYears,
          hourlyRate: profile.hourlyRate,
          availabilityStatus: profile.availabilityStatus,
          currentLatitude: pos.latitude,
          currentLongitude: pos.longitude,
          averageRating: profile.averageRating,
          verificationStatus: profile.verificationStatus,
        );
      }
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _allSkills = allSkills;
        _workerSkills = workerSkills;
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability() async {
    if (_profile == null) return;
    final newVal = !_profile!.availabilityStatus;
    await ref
        .read(profileRepositoryProvider)
        .updateWorkerAvailability(_profile!.workerId, newVal);
    setState(() => _profile = _profile!.copyWith(availabilityStatus: newVal));
  }

  Future<void> _saveProfile() async {
    final user = ref.read(customAuthProvider);
    if (_profile == null || user == null) return;
    setState(() => _isSaving = true);
    try {
      final updatedWorker = _profile!.copyWith(
        hourlyRate: double.tryParse(_rateCtrl.text) ?? _profile!.hourlyRate,
        experienceYears:
            int.tryParse(_expCtrl.text) ?? _profile!.experienceYears,
      );
      await ref
          .read(profileRepositoryProvider)
          .updateWorkerProfile(updatedWorker);

      final updatedUser = user.copyWith(
        fullName: _nameCtrl.text.trim(),
        mobileNumber: _phoneCtrl.text.trim(),
      );
      await ref.read(authRepositoryProvider).updateUser(updatedUser);
      ref.read(customAuthProvider.notifier).state = updatedUser;

      setState(() => _profile = updatedWorker);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('Profile updated!', AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_snackBar('Error: $e', AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final user = ref.read(customAuthProvider);
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final img =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img == null) return;
      final bytes = await img.readAsBytes();

      setState(() => _isSaving = true);
      // Uploading photo updates the user's profile_photo_url via auth repository.
      // Additionally we'll update the worker's.
      final url = await ref.read(authRepositoryProvider).uploadProfilePhoto(
            userId: user.userId,
            imageBytes: bytes,
            fileName: img.name,
          );

      if (_profile != null) {
        await ref
            .read(profileRepositoryProvider)
            .updateProfilePhoto(_profile!.workerId, url);
        setState(() => _profile = _profile!.copyWith(profilePhotoUrl: url));
      }

      final updatedUser =
          await ref.read(authRepositoryProvider).getUserById(user.userId);
      if (updatedUser != null) {
        ref.read(customAuthProvider.notifier).state = updatedUser;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            _snackBar('Error uploading photo: $e', AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  SnackBar _snackBar(String msg, Color color) => SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      );

  void _showSupportDialog() {
    final subjectCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            title: Text('Contact Support',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Describe your issue or complaint below:'),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                    hintText: 'Subject (e.g. Payment issue)',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final msg = msgCtrl.text.trim();
                        if (msg.isEmpty) return;

                        setStateDialog(() => isSubmitting = true);
                        try {
                          final user = ref.read(customAuthProvider);
                          await ref
                              .read(profileRepositoryProvider)
                              .submitSupportTicket(user!.userId, msg,
                                  subject: subjectCtrl.text.trim());
                          if (mounted) {
                            Navigator.pop(ctx);
                            setState(() {}); // refresh ticket list
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message sent to support!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setStateDialog(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to send: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(customAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [
                _buildHeader(user),
              ],
              body: TabBarView(
                controller: _tabs,
                children: [
                  _buildOverviewTab(),
                  _buildSkillsTab(),
                  _buildReviewsTab(),
                ],
              ),
            ),
    );
  }

  SliverAppBar _buildHeader(user) {
    final profile = _profile;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Skills'),
          Tab(text: 'Reviews'),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: profile?.profilePhotoUrl?.isNotEmpty == true
                            ? ClipOval(
                                child: Image.network(
                                  profile!.profilePhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.handyman_rounded,
                                          color: Colors.white, size: 38),
                                ),
                              )
                            : const Icon(Icons.handyman_rounded,
                                color: Colors.white, size: 38),
                      ),
                      // Profile photo edit button
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                      // Online indicator
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: profile?.availabilityStatus == true
                                ? AppColors.primary
                                : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Worker',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75)),
                  ),
                  const SizedBox(height: 12),
                  // Quick stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HeaderBadge(
                        icon: Icons.star_rounded,
                        label:
                            '${profile?.averageRating.toStringAsFixed(1) ?? '0.0'} Rating',
                      ),
                      const SizedBox(width: 10),
                      _HeaderBadge(
                        icon: Icons.verified_outlined,
                        label: profile?.verificationStatus == 'verified'
                            ? 'Verified'
                            : 'Pending',
                      ),
                      const SizedBox(width: 10),
                      _HeaderBadge(
                        icon: Icons.reviews_outlined,
                        label: '${_reviews.length} Reviews',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Overview ─────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    if (_profile == null) {
      return _buildSetupProfile();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Availability toggle
          _SectionCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                  color: _profile!.availabilityStatus
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _profile!.availabilityStatus
                        ? Icons.wifi_tethering_rounded
                        : Icons.wifi_tethering_off_rounded,
                    color: _profile!.availabilityStatus
                        ? AppColors.primary
                        : AppColors.outline,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Availability',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        _profile!.availabilityStatus
                            ? 'You are visible to clients'
                            : 'You are hidden from clients',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _profile!.availabilityStatus,
                  onChanged: (_) => _toggleAvailability(),
                  activeColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withOpacity(0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Edit rates/experience
          _SectionCard(
            title: 'Service Details',
            child: Column(
              children: [
                _EditField(
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 14),
                _EditField(
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _EditField(
                  label: 'Hourly Rate (₹)',
                  icon: Icons.attach_money,
                  controller: _rateCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _EditField(
                  label: 'Years of Experience',
                  icon: Icons.work_outline,
                  controller: _expCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Save Changes',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.star_rounded,
                  value: _profile!.averageRating.toStringAsFixed(1),
                  label: 'Avg Rating',
                  color: AppColors.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.reviews_outlined,
                  value: '${_reviews.length}',
                  label: 'Reviews',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.work_history,
                  value: '${_profile!.experienceYears}yr',
                  label: 'Experience',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Verification & ID Card Upload
          _SectionCard(
            title: 'Verification',
            child: Column(
              children: [
                // Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _profile!.isVerified
                        ? AppColors.secondary.withOpacity(0.08)
                        : AppColors.tertiary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _profile!.isVerified ? Icons.verified : Icons.pending,
                        color: _profile!.isVerified
                            ? AppColors.secondary
                            : AppColors.tertiary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile!.isVerified
                                  ? 'Verified Worker'
                                  : 'Verification ${_profile!.verificationStatus}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: _profile!.isVerified
                                    ? AppColors.secondary
                                    : AppColors.tertiary,
                              ),
                            ),
                            if (!_profile!.isVerified)
                              Text(
                                'Upload your ID card for admin verification',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_profile!.isVerified) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _uploadIdCard,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(_profile!.hasIdCard
                          ? 'Re-upload ID Card'
                          : 'Upload ID Card'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                if (_profile!.verificationNotes != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Text(
                      'Note: ${_profile!.verificationNotes}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Support Card
          _SectionCard(
            title: 'Support',
            child: Column(
              children: [
                ListTile(
                  onTap: _showSupportDialog,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline, color: AppColors.accent),
                  ),
                  title: Text(
                    'Contact Support',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Report an issue or ask a question',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                ),
                // Ticket list with admin responses
                Consumer(builder: (context, ref, _) {
                  final user = ref.watch(customAuthProvider);
                  if (user == null) return const SizedBox.shrink();
                  return FutureBuilder<List<SupportTicketModel>>(
                    future: ref
                        .read(profileRepositoryProvider)
                        .getUserSupportTickets(user.userId),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: snap.data!.map((t) {
                          return Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (t.subject != null &&
                                        t.subject!.isNotEmpty)
                                      Flexible(
                                        child: Text(t.subject!,
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13)),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (t.status == 'resolved'
                                                ? AppColors.success
                                                : AppColors.accent)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            const BorderRadius.all(Radius.circular(8)),
                                      ),
                                      child: Text(
                                        t.status.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: t.status == 'resolved'
                                              ? AppColors.success
                                              : AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(t.message,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                if (t.adminResponse != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          const BorderRadius.all(Radius.circular(8)),
                                      border: Border.all(
                                          color: AppColors.success
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons
                                                    .admin_panel_settings,
                                                size: 14,
                                                color:
                                                    AppColors.success),
                                            const SizedBox(width: 6),
                                            Text('Admin Response',
                                                style: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 11,
                                                    color: AppColors
                                                        .success)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(t.adminResponse!,
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textPrimary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildSetupProfile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_business_outlined,
                size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Set Up Your Worker Profile',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Create your worker profile to start receiving service requests from clients.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createProfile,
              icon: const Icon(Icons.add),
              label: const Text('Create Worker Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    final user = ref.read(customAuthProvider);
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final newProfile = await ref
          .read(profileRepositoryProvider)
          .createWorkerProfile(userId: user.userId);
      // Invalidate so HomeScreen tabs refresh to show worker dashboard
      ref.invalidate(isWorkerProvider(user.userId));
      setState(() {
        _profile = newProfile;
        _rateCtrl.text = '0';
        _expCtrl.text = '0';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_snackBar('Error: $e', AppColors.error));
      }
    }
  }

  Future<void> _uploadIdCard() async {
    if (_profile == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isSaving = true);
    try {
      final bytes = await picked.readAsBytes();
      await ref.read(profileRepositoryProvider).uploadIdCard(
            workerId: _profile!.workerId,
            imageBytes: bytes,
            fileName: picked.name,
            idCardType: 'National ID',
          );
      await _load(); // Reload to get updated status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('ID card uploaded! Awaiting admin verification.',
              AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_snackBar('Error: $e', AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Tab 2: Skills ────────────────────────────────────────────────────

  Widget _buildSkillsTab() {
    if (_profile == null) {
      return const Center(child: Text('Create a worker profile first'));
    }
    final selectedIds = _workerSkills.map((s) => s.skillId).toSet();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select your skills',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allSkills.map((skill) {
              final sel = selectedIds.contains(skill.skillId);
              return FilterChip(
                label: Text(skill.skillName),
                selected: sel,
                onSelected: (_) => _toggleSkill(skill, sel),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: GoogleFonts.inter(
                  color: sel ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                ),
                side: BorderSide(
                    color: sel ? AppColors.primary : AppColors.border),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
          if (_workerSkills.isEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Add at least one skill so clients can find you.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Text('Can\'t find your skill?',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'Suggest a new skill category. It will be added once approved by an admin.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _suggestSkillCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Graphic Design',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _suggestSkill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Suggest'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _suggestSkill() async {
    final name = _suggestSkillCtrl.text.trim();
    if (name.isEmpty) return;

    // Check if it already exists
    if (_allSkills
        .any((s) => s.skillName.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context)
          .showSnackBar(_snackBar('Skill already exists', AppColors.error));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(profileRepositoryProvider).suggestSkill(name);
      _suggestSkillCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snackBar(
            'Skill suggested! Awaiting admin approval.', AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            _snackBar('Error suggesting skill: $e', AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleSkill(SkillModel skill, bool currentlySelected) async {
    if (_profile == null) return;
    try {
      if (currentlySelected) {
        await ref
            .read(profileRepositoryProvider)
            .removeWorkerSkill(_profile!.workerId, skill.skillId);
        setState(
            () => _workerSkills.removeWhere((s) => s.skillId == skill.skillId));
      } else {
        await ref
            .read(profileRepositoryProvider)
            .addWorkerSkill(_profile!.workerId, skill.skillId);
        setState(() => _workerSkills.add(skill));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_snackBar('Error: $e', AppColors.error));
      }
    }
  }

  // ── Tab 3: Reviews ───────────────────────────────────────────────────

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No reviews yet',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Complete jobs to receive reviews from clients.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // Calculate real average
    final avg = _reviews.isEmpty
        ? 0.0
        : _reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            _reviews.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(avg.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < avg.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.accent,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Column(
                children: [
                  Text('${_reviews.length}',
                      style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Total Reviews',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  const _SectionCard({required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.onSurface)),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.onSurface)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _EditField(
      {required this.label,
      required this.icon,
      required this.controller,
      this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(review.reviewerUserId));

    String reviewerName = 'User';
    String? reviewerPhoto;

    userAsync.whenData((user) {
      if (user != null) {
        reviewerName = user.fullName;
        reviewerPhoto = user.profilePhotoUrl;
      }
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.primaryContainer.withOpacity(0.4),
                backgroundImage:
                    reviewerPhoto != null ? NetworkImage(reviewerPhoto!) : null,
                child: reviewerPhoto == null
                    ? Text(
                        reviewerName.isNotEmpty
                            ? reviewerName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 14))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.onSurface),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(review.createdAt),
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Star rating
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.star,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
            ),
          ],
          // Review image
          if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Image.network(
                review.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
