import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/internship_model.dart';
import '../models/activity_log_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.magangday://login-callback',
    );
  }

  static Future<void> signInWithApple() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'io.supabase.magangday://login-callback',
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> saveProfile(ProfileModel profile) async {
    await client.from('profiles').upsert(profile.toJson());
  }

  static Future<String> uploadAvatar({
    required String userId,
    required Uint8List fileBytes,
    required String extension,
  }) async {
    final String path = '$userId/avatar.$extension';
    await client.storage.from('avatar').uploadBinary(
      path,
      fileBytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/*',
      ),
    );
    return client.storage.from('avatar').getPublicUrl(path);
  }

  static Future<ProfileModel?> getProfile(String id) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }

  // --- Internship Queries ---
  static Future<InternshipModel?> getActiveInternship(String userId) async {
    final response = await client
        .from('internships')
        .select()
        .eq('user_id', userId)
        .eq('status', 'Active')
        .maybeSingle();
    if (response == null) return null;
    return InternshipModel.fromJson(response);
  }

  static Future<void> saveInternship(InternshipModel internship) async {
    await client.from('internships').upsert(internship.toJson());
  }

  // --- Activity Log Queries ---
  static Future<List<ActivityLogModel>> getActivityLogs(String internshipId) async {
    final List<dynamic> response = await client
        .from('activity_logs')
        .select()
        .eq('internship_id', internshipId)
        .order('activity_date', ascending: false);
    return response.map((json) => ActivityLogModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<void> saveActivityLog(ActivityLogModel log) async {
    await client.from('activity_logs').upsert(log.toJson());
  }

  static Future<void> deleteActivityLog(String id) async {
    await client.from('activity_logs').delete().eq('id', id);
  }

  static Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
