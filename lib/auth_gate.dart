// lib/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'models/user_profile_model.dart';
import 'services/auth_service.dart';
import 'constants/app_colors.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  UserProfile? _userProfile;
  bool _isInitialLoading = true; // For the very first load screen
  bool _isProfileLoading = false; // For "Loading user profile..." specifically
  final AuthService _authService = AuthService();
  String?
      _currentUserId; // To avoid refetching for the same user if already loaded

  @override
  void initState() {
    super.initState();
    print("AuthGate: initState called");

    // Attempt to get the current session immediately for a faster initial check
    // This helps determine if we need to show WelcomeScreen or attempt profile load sooner.
    final initialSession = Supabase.instance.client.auth.currentSession;
    if (initialSession != null && initialSession.user != null) {
      print("AuthGate: Initial session found. User: ${initialSession.user.id}");
      _currentUserId = initialSession.user.id;
      _fetchUserProfile(initialSession.user.id, isInitialSetup: true);
    } else {
      print("AuthGate: No initial session found.");
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (AuthState data) {
        if (!mounted) return;

        final session = data.session;
        final event = data.event;
        print(
          "AuthGate: AuthState changed! Event: $event, Session User ID: ${session?.user.id ?? 'N/A'}",
        );

        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.initialSession) {
          if (session != null && session.user != null) {
            // Only fetch if user ID changed or profile is null
            if (_currentUserId != session.user.id || _userProfile == null) {
              _currentUserId = session.user.id;
              _fetchUserProfile(session.user.id);
            } else if (_isInitialLoading) {
              // If initial session event and profile already loaded (e.g. by immediate check above)
              setState(() => _isInitialLoading = false);
            }
          } else {
            // Should not happen for signedIn/initialSession if session is not null
            _clearProfileAndSetLoadingState();
          }
        } else if (event == AuthChangeEvent.signedOut ||
            event == AuthChangeEvent.userDeleted) {
          _clearProfileAndSetLoadingState();
        } else if (event == AuthChangeEvent.passwordRecovery) {
          // Handle password recovery if needed, usually means user is not fully signed in yet.
        }
      },
      onError: (error) {
        print("AuthGate: Auth subscription error: $error");
        if (mounted) {
          setState(() {
            _userProfile = null;
            _isInitialLoading = false;
            _isProfileLoading = false;
          });
        }
      },
    );
  }

  void _clearProfileAndSetLoadingState() {
    setState(() {
      _userProfile = null;
      _currentUserId = null;
      _isInitialLoading =
          false; // Ensure initial loading is false if we sign out
      _isProfileLoading = false;
    });
  }

  Future<void> _fetchUserProfile(
    String userId, {
    bool isInitialSetup = false,
  }) async {
    if (!mounted) return;
    print("AuthGate: Fetching profile for user ID: $userId");
    setState(() {
      if (isInitialSetup)
        _isInitialLoading = true; // Keep initial loader if part of setup
      _isProfileLoading = true; // Show "Loading profile..." text
    });

    final profile = await _authService.getUserProfile(userId);

    if (!mounted) return;

    setState(() {
      _userProfile = profile;
      if (profile != null) {
        print("AuthGate: Profile fetched. Role: ${profile.role}");
      } else {
        print(
          "AuthGate: No profile found for user ID: $userId. User might need to complete profile or error occurred.",
        );
        // Consider if signing out the user is appropriate if profile is mandatory and not found
        // For now, it will fall back to WelcomeScreen or an error state if _currentSession exists but profile is null.
      }
      _isInitialLoading = false; // Done with any initial loading sequence
      _isProfileLoading = false; // Done with specific profile loading
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Widget _buildScreenBasedOnRole() {
    if (_userProfile!.role == 'cemetery_manager' ||
        _userProfile!.role == 'system_super_admin') {
      print(
        "AuthGate: Navigating to AdminDashboardScreen for role: ${_userProfile!.role}",
      );
      return AdminDashboardScreen(userProfile: _userProfile!);
    }
    print("AuthGate: Navigating to MainScreen for role: ${_userProfile!.role}");
    return MainScreen(); // Assuming MainScreen() is appropriate here
  }

  @override
  Widget build(BuildContext context) {
    final currentAuthSession = Supabase.instance.client.auth
        .currentSession; // More direct way to check session in build

    print(
      "AuthGate: Build. isInitialLoading: $_isInitialLoading, isProfileLoading: $_isProfileLoading, Has Session: ${currentAuthSession != null}, User Role: ${_userProfile?.role}",
    );

    if (_isInitialLoading) {
      return const Scaffold(
        backgroundColor:
            AppColors.background, // Or your splash screen background
        body: Center(child: CircularProgressIndicator(color: AppColors.appBar)),
      );
    }

    if (currentAuthSession != null) {
      if (_userProfile != null) {
        return _buildScreenBasedOnRole();
      } else {
        // Session exists, but profile is not yet loaded or failed to load
        if (_isProfileLoading) {
          // Check if we are actively trying to load it
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.appBar),
                  SizedBox(height: 16),
                  Text("Loading user profile..."),
                ],
              ),
            ),
          );
        } else {
          // Profile loading finished but profile is null (e.g., fetch failed, or profile doesn't exist)
          print(
            "AuthGate: Session exists, but profile is null and not currently loading. Displaying error/fallback.",
          );
          // This is a critical state: user is authenticated but profile is missing.
          // You might want to navigate them to a "complete profile" screen,
          // show an error, or log them out if a profile is mandatory.
          // For now, falling back to WelcomeScreen if profile is essential for app function.
          // Or show a specific error screen.
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Error: Could not load user profile."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      // AuthStateChange will handle UI update
                    },
                    child: const Text("Logout and try again"),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    // No session, navigate to WelcomeScreen
    print("AuthGate: No session, navigating to WelcomeScreen.");
    return const WelcomeScreen();
  }
}
