// lib/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart'; // User's main screen
import 'screens/admin/admin_dashboard_screen.dart'; // Admin's main screen
import 'models/user_profile_model.dart'; // To parse profile
import 'services/auth_service.dart'; // To fetch profile
import 'constants/app_colors.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  Session? _currentSession;
  UserProfile? _userProfile; // To store the fetched user profile
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    print("AuthGate: initState called");
    _initializeSessionAndProfile();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (AuthState data) {
        final sessionUserID = data.session?.user?.id;
        print(
          "AuthGate: AuthState changed! Event: ${data.event}, Session User ID: ${sessionUserID ?? 'N/A'}",
        );
        if (!mounted) return;

        setState(() {
          _currentSession = data.session;
        });

        if (data.session != null && data.session!.user != null) {
          _fetchUserProfile(
            data.session!.user.id,
          ); // Fetch profile on sign in/refresh
        } else {
          // User signed out
          setState(() {
            _userProfile = null;
            if (_isLoading) _isLoading = false; // If was still initial loading
          });
        }
      },
      onError: (error) {
        /* ... */
      },
    );
  }

  Future<void> _initializeSessionAndProfile() async {
    print("AuthGate: _initializeSessionAndProfile called");
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user != null) {
        _currentSession = session; // Set session first
        await _fetchUserProfile(
          session.user.id,
        ); // Then attempt to fetch profile
      }
      // If session is null, _userProfile will remain null
    } catch (e) {
      print("AuthGate: Error initializing session/profile: $e");
      _currentSession = null;
      _userProfile = null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    print("AuthGate: Fetching profile for user ID: $userId");
    // Potentially set a loading state specific to profile fetching if needed
    final profile = await _authService.getUserProfile(userId);
    if (mounted) {
      setState(() {
        _userProfile = profile;
        // _isLoading can be set to false here if it wasn't already by _initializeSessionAndProfile
        // This ensures that even if session exists, we wait for profile role before deciding the screen
      });
      print("AuthGate: Profile fetched. Role: ${_userProfile?.role}");
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      "AuthGate: Build. isLoading: $_isLoading, Has Session: ${_currentSession != null}, User Role: ${_userProfile?.role}",
    );

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.appBar)),
      );
    }

    if (_currentSession != null && _userProfile != null) {
      // User is logged in and profile is fetched
      if (_userProfile!.role == 'cemetery_manager' ||
          _userProfile!.role == 'system_super_admin') {
        print(
          "AuthGate: Navigating to AdminDashboardScreen for role: ${_userProfile!.role}",
        );
        // Pass necessary admin-specific data if needed
        return AdminDashboardScreen(userProfile: _userProfile!);
      } else {
        // Default to 'user' role
        print(
          "AuthGate: Navigating to MainScreen for role: ${_userProfile!.role}",
        );
        return const MainScreen();
      }
    } else {
      // Not logged in or profile couldn't be fetched
      print("AuthGate: Navigating to WelcomeScreen (no session or no profile)");
      return const WelcomeScreen();
    }
  }
}
