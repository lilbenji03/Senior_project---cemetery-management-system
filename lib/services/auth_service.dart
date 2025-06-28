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
          // Conditionally add phone_number if it's not null and not empty
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phone_number': phoneNumber,
        },
      );
      // The DB trigger 'on_auth_user_created_create_profile' handles profile creation.
      if (response.user == null && response.session == null) {
        print(
          "AuthService: signUp call successful. Email confirmation may be pending. User ID (from auth.users table, if created): not directly available in response here if confirmation pending, but trigger will use it.",
        );
      } else {
        print(
          "AuthService: signUp successful. User: ${response.user?.id}, Session: ${response.session != null}",
        );
      }
      return response;
    } on AuthException catch (e) {
      print(
        "AuthService: AuthException during signUp: (${e.statusCode}) ${e.message}",
      );
      rethrow; // Rethrow to be handled by UI
    } catch (e) {
      print("AuthService: Unexpected error during signUp: $e");
      // Consider a more specific custom exception or rethrow with more context
      throw Exception(
        'An unexpected error occurred during sign up. Please try again.',
      );
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
      print(
        "AuthService: signIn successful. User: ${response.user?.id}, Session: ${response.session != null}",
      );
      return response;
    } on AuthException catch (e) {
      print(
        "AuthService: AuthException during signIn: (${e.statusCode}) ${e.message}",
      );
      rethrow;
    } catch (e) {
      print("AuthService: Unexpected error during signIn: $e");
      throw Exception(
        'An unexpected error occurred during sign in. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    print("AuthService: Attempting signOut");
    try {
      await _supabase.auth.signOut();
      print("AuthService: signOut successful");
    } on AuthException catch (e) {
      print(
        "AuthService: AuthException during signOut: (${e.statusCode}) ${e.message}",
      );
      rethrow;
    } catch (e) {
      print("AuthService: Unexpected error during signOut: $e");
      throw Exception('An unexpected error occurred during sign out.');
    }
  }

  /// Fetches the user profile for the given [userId] or the current authenticated user.
  ///
  /// The [UserProfile] model should be able to handle cases where `email` might be
  /// sourced from `_supabase.auth.currentUser.email` if not directly in the profile data.
  Future<UserProfile?> getUserProfile([String? userId]) async {
    final targetUserId = userId ?? _supabase.auth.currentUser?.id;

    if (targetUserId == null) {
      print(
        "AuthService: getUserProfile - No user ID available (current user is null and no ID provided).",
      );
      return null;
    }

    print("AuthService: Fetching profile for user ID: $targetUserId");
    try {
      final data =
          await _supabase
              .from('profiles')
              .select() // Selects all columns from the 'profiles' table
              .eq('id', targetUserId) // CORRECTED: Changed 'user_id' to 'id'
              .single(); // Expects a single row or throws an error if 0 or >1

      print("AuthService: Profile data retrieved: $data");

      // Assuming UserProfile.fromJson can derive/use email from current user if needed
      return UserProfile.fromJson(
        data, // 1st argument: The map from Supabase
        targetUserId, // 2nd argument: The user's ID
        _supabase.auth.currentUser?.email,
      );
    } on PostgrestException catch (e) {
      // Handle cases like "JSON object requested, multiple (or zero) rows returned"
      print(
        "AuthService: getUserProfile PostgrestException: ${e.message} (Code: ${e.code})",
      );
      if (e.code == 'PGRST116') {
        // PGRST116: "JSON object requested, multiple (or zero) rows returned"
        print(
          "AuthService: getUserProfile - Profile not found for user ID: $targetUserId or multiple entries (should not happen for 'id').",
        );
      }
      return null;
    } catch (e) {
      print("AuthService: getUserProfile UNEXPECTED ERROR: $e");
      return null;
    }
  }

  /// Updates the current user's profile.
  /// The [UserProfile] object should contain the new values.
  /// Fields like 'id', 'email', 'role', 'created_at', and 'updated_at' (if handled by DB trigger)
  /// should be excluded from the update payload by the `toJson()` method or removed here.
  Future<void> updateUserProfile(UserProfile profileChanges) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      print("AuthService: updateUserProfile - User not authenticated.");
      throw Exception("User not authenticated. Cannot update profile.");
    }

    // Ensure the ID in profileChanges matches the current user, or just use currentUser.id
    // This is a safety check if profileChanges.id could be different.
    if (profileChanges.id != currentUser.id) {
      print(
        "AuthService: updateUserProfile - Mismatch between profile ID and current user ID. Using current user ID.",
      );
      // Potentially throw an error or log a warning, depending on how `profileChanges` is constructed.
    }

    print("AuthService: Updating profile for user ID: ${currentUser.id}");

    try {
      // Prepare the data for update.
      // The UserProfile.toJson() method should ideally only include fields
      // that are meant to be updated in the 'profiles' table by the user.
      final Map<String, dynamic> updateData = profileChanges.toJson();

      // Explicitly remove fields that should not be updated by the client
      // or are handled by the database (like primary key, audit timestamps, restricted fields).
      updateData.remove('id'); // Primary key, used in .eq()
      updateData.remove(
        'email',
      ); // Email should be updated via auth.updateUser()
      updateData.remove('role'); // Role changes should be admin-controlled
      updateData.remove('created_at'); // Should never be updated
      updateData.remove(
        'updated_at',
      ); // Let the DB trigger handle this for consistency

      if (updateData.isEmpty) {
        print("AuthService: updateUserProfile - No updatable data provided.");
        return; // Or throw an error if an update was expected
      }

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq(
            'id',
            currentUser.id,
          ); // Ensure we only update the current user's profile

      print(
        "AuthService: Profile update successful for user ${currentUser.id}.",
      );
    } on PostgrestException catch (e) {
      print("AuthService: updateUserProfile PostgrestException: ${e.message}");
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      print("AuthService: updateUserProfile UNEXPECTED ERROR: $e");
      throw Exception(
        'An unexpected error occurred while updating the profile.',
      );
    }
  }
}
