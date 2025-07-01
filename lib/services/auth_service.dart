// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart'; // Ensure this model is correctly defined

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    print("AuthService: Attempting signUp for email: $email");
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phone_number': phoneNumber,
        },
      );
      if (response.user == null && response.session == null) {
        print(
            "AuthService: signUp call successful. Email confirmation may be pending.");
      } else {
        print("AuthService: signUp successful. User: ${response.user?.id}");
      }
      return response;
    } on AuthException catch (e) {
      print(
          "AuthService: AuthException during signUp: (${e.statusCode}) ${e.message}");
      rethrow;
    } catch (e) {
      print("AuthService: Unexpected error during signUp: $e");
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

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
      print("AuthService: signIn successful. User: ${response.user?.id}");
      return response;
    } on AuthException catch (e) {
      print(
          "AuthService: AuthException during signIn: (${e.statusCode}) ${e.message}");
      rethrow;
    } catch (e) {
      print("AuthService: Unexpected error during signIn: $e");
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    print("AuthService: Sending password reset email to: $email");
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      print("AuthService: Password reset request sent successfully.");
    } on AuthException catch (e) {
      print("AuthService: AuthException during password reset: ${e.message}");
      rethrow;
    } catch (e) {
      print("AuthService: Unexpected error during password reset: $e");
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<void> signOut() async {
    print("AuthService: Attempting signOut");
    try {
      await _supabase.auth.signOut();
      print("AuthService: signOut successful");
    } on AuthException catch (e) {
      print(
          "AuthService: AuthException during signOut: (${e.statusCode}) ${e.message}");
      rethrow;
    } catch (e) {
      print("AuthService: Unexpected error during signOut: $e");
      throw Exception('An unexpected error occurred during sign out.');
    }
  }

  Future<UserProfile?> getUserProfile([String? userId]) async {
    final targetUserId = userId ?? _supabase.auth.currentUser?.id;

    if (targetUserId == null) {
      print("AuthService: getUserProfile - No user ID available.");
      return null;
    }

    print("AuthService: Fetching profile for user ID: $targetUserId");
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', targetUserId)
          .single();

      print("AuthService: Profile data retrieved: $data");

      // --- THIS IS THE FIX ---
      // Restored the 3 required arguments for the UserProfile.fromJson call.
      return UserProfile.fromJson(
        data,
        targetUserId,
        _supabase.auth.currentUser?.email,
      );
    } on PostgrestException catch (e) {
      print("AuthService: getUserProfile PostgrestException: ${e.message}");
      if (e.code == 'PGRST116') {
        print(
            "AuthService: getUserProfile - Profile not found for user ID: $targetUserId.");
      }
      return null;
    } catch (e) {
      print("AuthService: getUserProfile UNEXPECTED ERROR: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile profileChanges) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not authenticated. Cannot update profile.");
    }

    print("AuthService: Updating profile for user ID: ${currentUser.id}");

    try {
      final Map<String, dynamic> updateData = profileChanges.toJson();

      updateData.remove('id');
      updateData.remove('email');
      updateData.remove('role');
      updateData.remove('created_at');
      updateData.remove('updated_at');

      if (updateData.isEmpty) {
        print("AuthService: updateUserProfile - No updatable data provided.");
        return;
      }

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', currentUser.id);

      print(
          "AuthService: Profile update successful for user ${currentUser.id}.");
    } on PostgrestException catch (e) {
      print("AuthService: updateUserProfile PostgrestException: ${e.message}");
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      print("AuthService: updateUserProfile UNEXPECTED ERROR: $e");
      throw Exception(
          'An unexpected error occurred while updating the profile.');
    }
  }
}
