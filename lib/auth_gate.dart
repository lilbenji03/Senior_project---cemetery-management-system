// lib/auth_gate.dart
import 'dart:async'; // For StreamSubscription
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import '../constants/app_colors.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  Session? _currentSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("AuthGate: initState called");
    _initializeSession();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (AuthState data) {
        final sessionUserID = data.session?.user?.id; // Get it once
        print(
          "AuthGate: AuthState changed! Event: ${data.event}, Session User ID: ${sessionUserID ?? 'N/A'}, Has Session: ${data.session != null}",
        );
        if (!mounted) {
          print("AuthGate: onAuthStateChange - no longer mounted, returning.");
          return;
        }
        setState(() {
          _currentSession = data.session;
          if (_isLoading) {
            _isLoading = false;
          }
        });
      },
      onError: (error) {
        print("AuthGate: Auth Stream Error: $error");
        if (!mounted) return;
        setState(() {
          _currentSession = null;
          _isLoading = false;
        });
      },
      onDone: () {
        print("AuthGate: Auth Stream Done");
      },
    );
  }

  Future<void> _initializeSession() async {
    print("AuthGate: _initializeSession called");
    if (!mounted) {
      print("AuthGate: _initializeSession - no longer mounted, returning.");
      return;
    }
    try {
      // Assign to a local variable first to avoid multiple calls to currentSession getter
      final Session? session = Supabase.instance.client.auth.currentSession;
      final String? sessionUserID = session?.user?.id; // Get it once

      print(
        "AuthGate: Initial session check - User ID: ${sessionUserID ?? 'N/A'}, Has Session: ${session != null}",
      );
      if (mounted) {
        setState(() {
          _currentSession = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("AuthGate: Error initializing session: $e");
      if (mounted) {
        setState(() {
          _currentSession = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    print("AuthGate: dispose called");
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? currentSessionUserID =
        _currentSession?.user?.id; // Get it once
    print(
      "AuthGate: Build triggered. isLoading: $_isLoading, Has Session: ${_currentSession != null}, Session User ID: ${currentSessionUserID ?? 'N/A'}",
    );

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.appBar)),
      );
    }

    // If _currentSession is not null, it implies _currentSession.user is also not null.
    if (_currentSession != null) {
      // CORRECTED CONDITION
      print("AuthGate: User is logged in, navigating to MainScreen.");
      return const MainScreen();
    } else {
      print("AuthGate: User is NOT logged in, navigating to WelcomeScreen.");
      return const WelcomeScreen();
    }
  }
}
