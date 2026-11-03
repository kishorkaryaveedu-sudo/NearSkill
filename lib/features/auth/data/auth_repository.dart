import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/utils/location_utils.dart';
import '../domain/user_model.dart';

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

/// Custom auth state (DB-only login)
final customAuthProvider = StateProvider<UserModel?>((ref) => null);

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.watch(supabaseClientProvider),
    ref: ref,
  );
});

/// Current logged-in user model provider
final currentUserModelProvider = StateProvider<UserModel?>((ref) => null);

/// Get any user by ID provider
final userProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) {
  return ref.watch(authRepositoryProvider).getUserById(userId);
});

/// Authentication repository
class AuthRepository {
  final SupabaseClient _client;
  final Ref _ref;

  AuthRepository({required SupabaseClient client, required Ref ref})
      : _client = client,
        _ref = ref;

  // ----------------------------------------------------------------
  // Session Persistence
  // ----------------------------------------------------------------
  Future<void> saveUserSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      try {
        final user = await getUserById(userId);
        if (user != null) {
          if (user.isBanned) {
            await clearUserSession();
            return null;
          }
          _ref.read(customAuthProvider.notifier).state = user;
          return user;
        }
      } catch (_) {
        // Ignored
      }
    }
    return null;
  }

  // ----------------------------------------------------------------
  // Register via DB RPC
  // ----------------------------------------------------------------
  Future<UserModel> registerWithDatabase({
    required String email,
    required String password,
    required String fullName,
    String? mobileNumber,
    bool isWorker = false,
  }) async {
    final response = await _client.rpc('register_custom_user', params: {
      'p_email': email,
      'p_password': password,
      'p_full_name': fullName,
      'p_mobile_number': mobileNumber,
    });

    if (response == null) {
      throw Exception('Registration failed – no response from server');
    }

    final user = UserModel.fromMap(response as Map<String, dynamic>);

    if (isWorker) {
      try {
        final pos = await LocationUtils.getCurrentPosition();
        await _client.from('worker_profiles').insert({
          'user_id': user.userId,
          'current_latitude': pos?.latitude ?? 0.0,
          'current_longitude': pos?.longitude ?? 0.0,
          'availability_status': true,
        });
        debugPrint('Worker profile created for ${user.userId}');
      } catch (e) {
        debugPrint('Worker profile creation during signup: $e');
      }
    }

    return user;
  }

  // ----------------------------------------------------------------
  // Login via DB RPC
  // ----------------------------------------------------------------
  Future<UserModel> loginWithDatabase({
    required String email,
    required String password,
  }) async {
    // ── Hardcoded admin bypass (not in DB) ──────────────────────
    if (email.trim().toLowerCase() == 'admin@gmail.com' &&
        password == 'admin123') {
      final adminUser = UserModel(
        userId: '00000000-0000-0000-0000-000000000001',
        fullName: 'Admin',
        email: 'admin@gmail.com',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      _ref.read(customAuthProvider.notifier).state = adminUser;
      await saveUserSession(adminUser.userId);
      return adminUser;
    }

    // ── Normal DB login ─────────────────────────────────────────
    final response = await _client.rpc('login_custom_user', params: {
      'p_email': email,
      'p_password': password,
    });

    if (response == null) {
      throw Exception('Invalid email or password');
    }

    var userModel = UserModel.fromMap(response as Map<String, dynamic>);

    if (userModel.isBanned) {
      throw Exception(
          'Your account has been banned. Please contact support.');
    }

    // Check if this user is an admin in the admins table
    try {
      final adminRow = await _client
          .from('admins')
          .select('admin_id')
          .eq('user_id', userModel.userId)
          .maybeSingle();
      if (adminRow != null) {
        userModel = UserModel(
          userId: userModel.userId,
          fullName: userModel.fullName,
          email: userModel.email,
          mobileNumber: userModel.mobileNumber,
          role: 'admin',
          createdAt: userModel.createdAt,
        );
      }
    } catch (_) {
      // admins table may not exist, ignore
    }

    _ref.read(customAuthProvider.notifier).state = userModel;
    await saveUserSession(userModel.userId);
    return userModel;
  }

  // ----------------------------------------------------------------
  // Get user by id
  // ----------------------------------------------------------------
  Future<UserModel?> getUserById(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromMap(response);
  }

  // ----------------------------------------------------------------
  // Update user profile
  // ----------------------------------------------------------------
  Future<void> updateUser(UserModel user) async {
    await _client.from('users').update({
      'full_name': user.fullName,
      'mobile_number': user.mobileNumber,
    }).eq('user_id', user.userId);
  }

  // ----------------------------------------------------------------
  // Update profile photo
  // ----------------------------------------------------------------
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final fileKey = '${const Uuid().v4()}_$fileName';
    final path = '$userId/$fileKey';

    await _client.storage.from('profile-photos').uploadBinary(path, imageBytes,
        fileOptions: const FileOptions(upsert: true));

    final url = _client.storage.from('profile-photos').getPublicUrl(path);

    await _client.from('users').update({
      'profile_photo_url': url,
    }).eq('user_id', userId);

    return url;
  }

  // ----------------------------------------------------------------
  // Get all users (admin)
  // ----------------------------------------------------------------
  Future<List<UserModel>> getAllUsers() async {
    final response = await _client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return response.map<UserModel>((r) => UserModel.fromMap(r)).toList();
  }

  // ----------------------------------------------------------------
  // Delete user (admin) – relies on ON DELETE CASCADE in DB
  // ----------------------------------------------------------------
  Future<void> deleteUser(String userId) async {
    try {
      await _client.from('users').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // ----------------------------------------------------------------
  // Toggle ban status (admin)
  // ----------------------------------------------------------------
  Future<void> toggleBanStatus(String userId, bool isBanned) async {
    await _client.from('users').update({
      'is_banned': isBanned,
    }).eq('user_id', userId);
  }

  // ----------------------------------------------------------------
  // Reset password via DB RPC
  // ----------------------------------------------------------------
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final response = await _client.rpc('reset_user_password', params: {
      'p_email': email,
      'p_new_password': newPassword,
    });

    if (response == null) {
      throw Exception('No account found for this email');
    }
  }

  // ----------------------------------------------------------------
  // Sign out
  // ----------------------------------------------------------------
  void signOut() {
    _ref.read(customAuthProvider.notifier).state = null;
    clearUserSession();
    debugPrint('User signed out');
  }
}
