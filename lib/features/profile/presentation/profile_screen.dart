import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../domain/worker_model.dart';
import '../domain/skill_model.dart';

/// Profile screen for viewing and editing user/worker profile
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rateController = TextEditingController();
  final _expController = TextEditingController();

  List<SkillModel> _allSkills = [];
  List<String> _selectedSkillIds = [];
  bool _isEditing = false;
  bool _isLoading = false;
  WorkerProfileModel? _workerProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(customAuthProvider);
    if (user == null) return;

    _nameController.text = user.fullName;
    _phoneController.text = user.mobileNumber ?? '';

    // Load all skills
    final skills = await ref.read(profileRepositoryProvider).getAllSkills();

    // Load worker profile by user_id
    final workerProfile = await ref
        .read(profileRepositoryProvider)
        .getWorkerProfileByUserId(user.userId);

    if (workerProfile != null) {
      final workerSkills = await ref
          .read(profileRepositoryProvider)
          .getWorkerSkills(workerProfile.workerId);
      _selectedSkillIds = workerSkills.map((s) => s.skillId).toList();
      _rateController.text = workerProfile.hourlyRate.toString();
      _expController.text = workerProfile.experienceYears.toString();
    }

    if (mounted) {
      setState(() {
        _allSkills = skills;
        _workerProfile = workerProfile;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(customAuthProvider);
      if (user == null) return;

      final profileRepo = ref.read(profileRepositoryProvider);

      // Update user name/phone
      await ref.read(authRepositoryProvider).updateUser(
            user.copyWith(
              fullName: _nameController.text.trim(),
              mobileNumber: _phoneController.text.trim(),
            ),
          );

      // Upsert worker profile
      if (_workerProfile != null) {
        await profileRepo.updateWorkerProfile(
          _workerProfile!.copyWith(
            hourlyRate: double.tryParse(_rateController.text) ?? 0,
            experienceYears: int.tryParse(_expController.text) ?? 0,
          ),
        );
        // Update skills
        await profileRepo.setWorkerSkills(
            _workerProfile!.workerId, _selectedSkillIds);
      } else if (_selectedSkillIds.isNotEmpty) {
        // Create worker profile
        final newWorker = await profileRepo.createWorkerProfile(
          userId: user.userId,
          hourlyRate: double.tryParse(_rateController.text) ?? 0,
          experienceYears: int.tryParse(_expController.text) ?? 0,
        );
        await profileRepo.setWorkerSkills(
            newWorker.workerId, _selectedSkillIds);
        setState(() => _workerProfile = newWorker);
      }

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successProfileUpdated),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signOut() {
    ref.read(authRepositoryProvider).signOut();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rateController.dispose();
    _expController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(customAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline,
                      size: 80,
                      color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('Not logged in',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar placeholder
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person,
                          size: 60, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),

                    // Full name
                    _buildTextField(
                      controller: _nameController,
                      label: AppStrings.displayName,
                      icon: Icons.person_outline,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    // Email (read-only)
                    _buildTextField(
                      controller: TextEditingController(text: user.email),
                      label: AppStrings.email,
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Mobile
                    _buildTextField(
                      controller: _phoneController,
                      label: AppStrings.phoneNumber,
                      icon: Icons.phone_outlined,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Worker profile section
                    const Divider(height: 32),
                    Text(
                      'Worker Profile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    if (_workerProfile != null) ...[
                      // Verification Status Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _workerProfile!.verificationStatus ==
                                  'verified'
                              ? AppColors.success.withValues(alpha: 0.1)
                              : _workerProfile!.verificationStatus == 'pending'
                                  ? AppColors.accent.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          border: Border.all(
                            color: _workerProfile!.verificationStatus ==
                                    'verified'
                                ? AppColors.success.withValues(alpha: 0.3)
                                : _workerProfile!.verificationStatus ==
                                        'pending'
                                    ? AppColors.accent.withValues(alpha: 0.3)
                                    : AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _workerProfile!.verificationStatus == 'verified'
                                  ? Icons.verified
                                  : _workerProfile!.verificationStatus ==
                                          'pending'
                                      ? Icons.hourglass_top
                                      : Icons.error_outline,
                              color: _workerProfile!.verificationStatus ==
                                      'verified'
                                  ? AppColors.success
                                  : _workerProfile!.verificationStatus ==
                                          'pending'
                                      ? AppColors.accentDark
                                      : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _workerProfile!.verificationStatus == 'verified'
                                    ? 'Your profile is verified. You can accept jobs.'
                                    : _workerProfile!.verificationStatus ==
                                            'pending'
                                        ? 'Document uploaded. Waiting for admin approval.'
                                        : 'Your verification was rejected.',
                                style: TextStyle(
                                  color: _workerProfile!.verificationStatus ==
                                          'verified'
                                      ? AppColors.success
                                      : _workerProfile!.verificationStatus ==
                                              'pending'
                                          ? AppColors.accentDark
                                          : AppColors.error,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildTextField(
                      controller: _rateController,
                      label: AppStrings.hourlyRate,
                      icon: Icons.attach_money,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _expController,
                      label: 'Experience (years)',
                      icon: Icons.work_outline,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Skills
                    if (_isEditing && _allSkills.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.skills,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allSkills.map((skill) {
                          final isSelected =
                              _selectedSkillIds.contains(skill.skillId);
                          return FilterChip(
                            label: Text(skill.skillName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSkillIds.add(skill.skillId);
                                } else {
                                  _selectedSkillIds.remove(skill.skillId);
                                }
                              });
                            },
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primary,
                          );
                        }).toList(),
                      ),
                    ] else if (_selectedSkillIds.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allSkills
                            .where((s) => _selectedSkillIds.contains(s.skillId))
                            .map((skill) => Chip(
                                  label: Text(skill.skillName),
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                ))
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Save button
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  AppStrings.saveProfile,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: enabled
            ? AppColors.surface
            : AppColors.border.withValues(alpha: 0.3),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
