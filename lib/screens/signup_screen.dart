import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
// Potentially import login_screen.dart or main_screen.dart for navigation after signup

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  // Add controllers for name, email, password, confirm password etc.

  void _signUpUser() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement actual sign-up logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign Up successful (Simulated)! Please login.'),
        ),
      );
      // Optionally navigate to login or main screen
      Navigator.pop(context); // Go back to login screen after simulated signup
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account', style: AppStyles.appBarTitleStyle),
        backgroundColor: AppColors.appBar,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppStyles.pagePadding.copyWith(top: 30, bottom: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Image.asset(
                  'assets/images/app_logo.png', // Ensure this path is correct
                  height: 80, // Smaller logo here
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Join CMC Community',
                textAlign: TextAlign.center,
                style: AppStyles.cardTitleStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 30),
              // --- Add TextFormField for Name ---
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground.withOpacity(0.5),
                ),
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? 'Please enter your full name'
                            : null,
              ),
              const SizedBox(height: 20),
              // --- Add TextFormField for Email ---
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground.withOpacity(0.5),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // --- Add TextFormField for Password ---
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground.withOpacity(0.5),
                  // Add suffix icon for show/hide password if desired
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // --- Add TextFormField for Confirm Password ---
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground.withOpacity(0.5),
                ),
                obscureText: true,
                validator: (value) {
                  // Add logic to compare with password field
                  // if (value != _passwordController.text) return 'Passwords do not match';
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  foregroundColor: AppColors.buttonText,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: AppStyles.buttonTextStyle.copyWith(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                  ),
                ),
                onPressed: _signUpUser,
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Already have an account? ", style: AppStyles.bodyText2),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to Login Screen
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: AppColors.appBar,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
