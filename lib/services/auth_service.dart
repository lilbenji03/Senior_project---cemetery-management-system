// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart'; // Your UserProfile model

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber, // Optional
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          // This data can be used by a DB trigger to create a profile
          'full_name': fullName,
          'phone_number': phoneNumber,
          // 'initial_role': 'user' // If you want to set role via trigger data
        },
      );

      // If signup is successful and a user object is returned,
      // and email confirmation is NOT required or already handled,
      // you might create the profile row here.
      // However, it's often better to use a DB trigger on auth.users insert.
      if (res.user != null) {
        // Example of creating profile row if not using a trigger
        // This check avoids errors if email confirmation is enabled and user is not immediately active
        if (res.user!.aud == 'authenticated') {
          // Check if user is immediately authenticated
          await _createProfileOnSignUp(
            userId: res.user!.id,
            email: email,
            fullName: fullName,
            phoneNumber: phoneNumber,
          );
        }
      }
      return res;
    } on AuthException catch (e) {
      // print('AuthService SignUp Error: ${e.message}');
      rethrow; // Rethrow to be caught by UI
    } catch (e) {
      // print('AuthService SignUp Unexpected Error: $e');
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  // Helper function to create a profile row if you're not using a DB trigger
  // Ensure RLS allows this insert for newly authenticated users.
  Future<void> _createProfileOnSignUp({
    required String userId,
    required String email,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'full_name': fullName,
        'email': email, // Storing email in profiles can be convenient
        'phone_number': phoneNumber,
        'role': 'user', // Default role
      });
    } catch (e) {
      // print("Error creating profile on sign up: $e");
      // Decide how to handle this: maybe delete the auth user if profile creation fails critically
      // or log it and let user complete profile later.
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      // print('AuthService SignIn Error: ${e.message}');
      rethrow;
    } catch (e) {
      // print('AuthService SignIn Unexpected Error: $e');
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      // print('AuthService SignOut Error: ${e.message}');
      rethrow;
    } catch (e) {
      // print('AuthService SignOut Unexpected Error: $e');
      throw Exception('An unexpected error occurred during sign out.');
    }
  }

  Future<UserProfile?> getUserProfile([String? userId]) async {
    final targetUserId = userId ?? _supabase.auth.currentUser?.id;
    if (targetUserId == null) return null;

    try {
      final data =
          await _supabase
              .from('profiles')
              .select()
              .eq('id', targetUserId)
              .single();
      return UserProfile.fromJson(
        data,
        targetUserId,
        _supabase.auth.currentUser?.email,
      );
    } catch (e) {
      // print('AuthService GetUserProfile Error: $e');
      return null; // Or rethrow / handle error appropriately
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    if (_supabase.auth.currentUser == null)
      throw Exception("User not authenticated");
    try {
      await _supabase
          .from('profiles')
          .update(
            profile.toJson()..removeWhere(
              (key, value) =>
                  key == 'id' ||
                  key == 'email' ||
                  key == 'created_at' ||
                  key == 'updated_at' ||
                  key == 'role',
            ),
          ) // Don't update id, email, role directly here
          .eq('id', _supabase.auth.currentUser!.id);
    } catch (e) {
      // print('AuthService UpdateUserProfile Error: $e');
      throw Exception('Failed to update profile.');
    }
  }
}
