// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For AuthException type
import 'signup_screen.dart';
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
  final AuthService _authService = AuthService();
  String? _errorMessage;

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthGate will handle navigation
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _errorMessage = 'An unexpected error occurred. Please try again.',
        );
      }
    } finally {
      if (mounted) {
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
    InputDecoration fieldDecoration(
      String label,
      String hint,
      IconData prefixIcon, {
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.secondaryText.withOpacity(0.7),
        ),
        suffixIcon: suffixIcon,
        labelStyle: AppStyles.bodyText2,
        hintStyle: AppStyles.bodyText2.copyWith(
          color: AppColors.secondaryText.withOpacity(0.5),
        ),
        filled: true,
        fillColor: AppColors.background.withOpacity(
          0.8,
        ), // A slightly different shade for fill
        border: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide: BorderSide.none, // No visible border initially
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide: BorderSide(
            color: AppColors.secondaryText.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide: BorderSide(
            color: AppColors.buttonBackground,
            width: 1.5,
          ), // Use accent color for focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide: BorderSide(color: AppColors.errorColor, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide: BorderSide(color: AppColors.errorColor, width: 1.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: AppStyles.pagePadding.copyWith(
            top: 40,
            bottom: 20,
          ), // More top padding
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppStyles.cardBorderRadius,
                boxShadow: AppStyles.cardBoxShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'assets/images/app_logo.png',
                      height: 80,
                    ), // Slightly smaller logo
                    const SizedBox(height: 24),
                    Text(
                      'Sign In', // Changed from 'Login' for common phrasing
                      textAlign: TextAlign.center,
                      style: AppStyles.titleStyle.copyWith(
                        fontSize: 28, // More prominent
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome back to EternalSpace!', // Friendly subtitle
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyText1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.errorColor,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    TextFormField(
                      controller: _emailController,
                      decoration: fieldDecoration(
                        'Email Address',
                        'you@example.com',
                        Icons.email_outlined,
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
                      decoration: fieldDecoration(
                        'Password',
                        'Enter your password',
                        Icons.lock_outline,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Forgot Password (Not Implemented Yet)',
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              AppColors
                                  .secondaryText, // Softer color for less emphasis
                          textStyle: AppStyles.bodyText2.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 24), // Increased spacing
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color:
                                AppColors
                                    .buttonBackground, // Use primary action color
                          ),
                        )
                        : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBackground,
                            foregroundColor: AppColors.buttonText,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppStyles.buttonBorderRadius,
                            ),
                            textStyle:
                                AppStyles
                                    .buttonTextStyle, // Your defined button text style
                          ),
                          onPressed: _loginUser,
                          child: const Text('Sign In'), // Changed from Login
                        ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Don't have an account? ",
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.secondaryText,
                          ),
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
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ), // Tighter padding
                            foregroundColor:
                                AppColors
                                    .buttonBackground, // Use primary action color for emphasis
                          ),
                          child: Text(
                            'Sign Up',
                            style: AppStyles.bodyText1.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  AppColors
                                      .buttonBackground, // Explicitly color the text
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
