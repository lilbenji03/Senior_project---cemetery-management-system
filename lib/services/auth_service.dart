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
    print("AuthService: Attempting signUp for email: $email"); // DEBUG
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          // <--- CORRECT: 'data' is a direct named parameter of signUp
          'full_name': fullName,
          'phone_number': phoneNumber,
          // 'initial_role': 'user' // If your Supabase DB trigger 'handle_new_user' uses this
        },
      );
      print(
        "AuthService: Supabase signUp call completed. User: ${res.user?.id}, Session: ${res.session != null}",
      ); // DEBUG
      // Profile creation is handled by the Supabase DB trigger 'handle_new_user'.
      return res;
    } on AuthException catch (e) {
      print(
        "AuthService: AuthException during signUp: Code: ${e.statusCode}, Message: ${e.message}",
      ); // DEBUG
      rethrow;
    } catch (e) {
      print("AuthService: Unexpected error during signUp: $e"); // DEBUG
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  // _createProfileOnSignUp method has been REMOVED as this logic
  // should be handled by a Supabase Database Trigger on auth.users inserts.

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    print("AuthService: Attempting signInWithPassword for email: $email");
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print(
        "AuthService: signInWithPassword successful. User: ${response.user?.id}, Session: ${response.session != null}",
      );
      return response;
    } on AuthException catch (e) {
      print(
        "AuthService: AuthException during signIn: Code: ${e.statusCode}, Message: ${e.message}",
      );
      rethrow;
    } catch (e) {
      print("AuthService: Unexpected error during signIn: $e");
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  Future<void> signOut() async {
    print("AuthService: Attempting signOut");
    try {
      await _supabase.auth.signOut();
      print("AuthService: signOut successful");
    } on AuthException catch (e) {
      print("AuthService: AuthException during signOut: ${e.message}");
      rethrow;
    } catch (e) {
      print("AuthService: Unexpected error during signOut: $e");
      throw Exception('An unexpected error occurred during sign out.');
    }
  }

  Future<UserProfile?> getUserProfile([String? userId]) async {
    final targetUserId = userId ?? _supabase.auth.currentUser?.id;
    if (targetUserId == null) {
      print("AuthService: getUserProfile - No targetUserId.");
      return null;
    }
    print(
      "AuthService: getUserProfile - Fetching profile for User ID: $targetUserId",
    );
    try {
      final data =
          await _supabase
              .from('profiles')
              .select()
              .eq('user_id', targetUserId)
              .single();
      print("AuthService: getUserProfile - Supabase response: $data");
      return UserProfile.fromJson(
        data,
        targetUserId,
        _supabase.auth.currentUser?.email,
      );
    } catch (e) {
      print("AuthService: GetUserProfile ERROR: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    if (_supabase.auth.currentUser == null) {
      print("AuthService: updateUserProfile - User not authenticated.");
      throw Exception("User not authenticated");
    }
    print(
      "AuthService: Attempting to update profile for User ID: ${profile.id}",
    );
    try {
      final updateData = profile.toJson();
      updateData.remove('id');
      updateData.remove('email');
      updateData.remove('role');
      updateData.remove('created_at');

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', _supabase.auth.currentUser!.id);
      print("AuthService: updateUserProfile successful.");
    } catch (e) {
      print("AuthService: UpdateUserProfile ERROR: $e");
      throw Exception('Failed to update profile.');
    }
  }
}
