// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For AuthException type
import 'signup_screen.dart';
// MainScreen import is not needed here as AuthGate handles navigation
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../services/auth_service.dart'; // Import your AuthService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final AuthService _authService = AuthService(); // Instance of AuthService
  String? _errorMessage; // To display errors on the UI

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      print("LoginScreen: Form validation failed."); // DEBUG
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error message
    });
    print(
      "LoginScreen: Attempting to sign in with email: ${_emailController.text.trim()}",
    ); // DEBUG

    try {
      final AuthResponse res = await _authService.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // If Supabase call was successful (didn't throw AuthException)
      print(
        "LoginScreen: AuthService.signInWithPassword call completed.",
      ); // DEBUG
      print(
        "LoginScreen: Response User ID: ${res.user?.id}, Has Session: ${res.session != null}",
      ); // DEBUG
      // AuthGate should now handle navigation based on onAuthStateChange.

      // If login is successful and res.user is not null,
      // _isLoading will be set to false in the finally block.
      // AuthGate will then see the new session and navigate.
      // No explicit navigation from here.
    } on AuthException catch (e) {
      print(
        "LoginScreen: CAUGHT AuthException: Code: ${e.statusCode}, Message: ${e.message}",
      ); // DEBUG
      if (mounted) {
        setState(() {
          _errorMessage = e.message; // Display the Supabase specific error
        });
      }
    } catch (e) {
      print("LoginScreen: CAUGHT general Exception: ${e.toString()}"); // DEBUG
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        print(
          "LoginScreen: Finally block, setting _isLoading to false.",
        ); // DEBUG
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Login', style: AppStyles.appBarTitleStyle),
        automaticallyImplyLeading:
            false, // No back button if pushed from WelcomeScreen
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: AppStyles.pagePadding.copyWith(top: 30, bottom: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('assets/images/app_logo.png', height: 100),
                  const SizedBox(height: 20), // Reduced space
                  Text(
                    'Sign in to EternalSpace', // App Name
                    textAlign: TextAlign.center,
                    style: AppStyles.cardTitleStyle.copyWith(
                      fontSize: 22,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display Error Message if any
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _errorMessage!,
                        style: AppStyles.bodyText2.copyWith(
                          color: AppColors.errorColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    style: AppStyles.bodyText1,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.secondaryText.withOpacity(0.7),
                        ),
                        onPressed:
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      ),
                    ),
                    style: AppStyles.bodyText1,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement Forgot Password functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Forgot Password (Not Implemented Yet)',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                      ), // Style from TextButtonTheme
                    ),
                  ),
                  const SizedBox(height: 25),
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.appBar,
                        ),
                      )
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(
                            double.infinity,
                            50,
                          ), // Use global theme
                          // textStyle: AppStyles.buttonTextStyle, // Comes from global theme
                        ),
                        onPressed: _loginUser,
                        child: const Text('Login'),
                      ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Don't have an account? ",
                        style: AppStyles.bodyText2,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ), // Uses TextButtonTheme
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
