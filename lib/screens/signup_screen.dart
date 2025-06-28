// lib/screens/signup_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // For the policy dialog
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../constants/legal_text.dart'; // For the T&C and Privacy Policy text
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final AuthService _authService = AuthService();

  // State variable for the checkbox
  bool _agreedToTerms = false;

  Future<void> _signUpUser() async {
    // Safeguard check, though the button UI should prevent this call
    if (!_formKey.currentState!.validate() || !_agreedToTerms) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sign up successful! Please check your email for verification.'),
            backgroundColor: AppColors.statusApproved,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Go back to login screen
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred: ${e.toString()}'),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method to show the legal text in a scrollable dialog
  void _showLegalDialog(
      BuildContext context, String title, String markdownContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
        title: Text(title, style: AppStyles.cardTitleStyle),
        content: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: markdownContent,
                styleSheet:
                    MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: AppStyles.bodyText1,
                  h2: AppStyles.cardTitleStyle.copyWith(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close',
                style: TextStyle(
                    color: AppColors.appBar, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
      String label, String hint, IconData prefixIcon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          Icon(prefixIcon, color: AppColors.secondaryText.withOpacity(0.7)),
      suffixIcon: suffixIcon,
      labelStyle: AppStyles.bodyText2,
      hintStyle: AppStyles.bodyText2
          .copyWith(color: AppColors.secondaryText.withOpacity(0.5)),
      filled: true,
      fillColor: AppColors.background.withOpacity(0.8),
      border: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide:
              BorderSide(color: AppColors.secondaryText.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide:
              const BorderSide(color: AppColors.buttonBackground, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide:
              const BorderSide(color: AppColors.errorColor, width: 1.0)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide:
              const BorderSide(color: AppColors.errorColor, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: AppStyles.pagePadding.copyWith(top: 40, bottom: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                    Image.asset('assets/images/app_logo.png', height: 70),
                    const SizedBox(height: 20),
                    Text('Create Your Account',
                        textAlign: TextAlign.center,
                        style: AppStyles.titleStyle.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText)),
                    const SizedBox(height: 8),
                    Text('Join the EternalSpace community today!',
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyText1
                            .copyWith(color: AppColors.secondaryText)),
                    const SizedBox(height: 28),
                    TextFormField(
                        controller: _nameController,
                        decoration: _fieldDecoration('Full Name',
                            'Enter your full name', Icons.person_outline),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter your full name'
                            : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _emailController,
                        decoration: _fieldDecoration('Email Address',
                            'you@example.com', Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please enter your email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                            return 'Enter a valid email';
                          return null;
                        }),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _phoneController,
                        decoration: _fieldDecoration('Phone Number (Optional)',
                            'e.g., +254712345678', Icons.phone_outlined),
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _passwordController,
                        decoration: _fieldDecoration('Password',
                            'Create a strong password', Icons.lock_outline,
                            suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword))),
                        obscureText: _obscurePassword,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please enter a password';
                          if (v.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        }),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _confirmPasswordController,
                        decoration: _fieldDecoration('Confirm Password',
                            'Re-enter your password', Icons.lock_outline,
                            suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword))),
                        obscureText: _obscureConfirmPassword,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please confirm your password';
                          if (v != _passwordController.text)
                            return 'Passwords do not match';
                          return null;
                        }),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (bool? value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                          activeColor: AppColors.appBar,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppStyles.bodyText2.copyWith(height: 1.4),
                              children: [
                                const TextSpan(
                                    text: 'I have read and agree to the '),
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: const TextStyle(
                                      color: AppColors.appBar,
                                      decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showLegalDialog(
                                        context,
                                        'Terms and Conditions',
                                        LegalText.termsAndConditions),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                      color: AppColors.appBar,
                                      decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showLegalDialog(
                                        context,
                                        'Privacy Policy',
                                        LegalText.privacyPolicy),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.buttonBackground))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonBackground,
                              foregroundColor: AppColors.buttonText,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppStyles.buttonBorderRadius),
                              textStyle: AppStyles.buttonTextStyle,
                              // Add a disabled color for when the button is inactive
                              disabledBackgroundColor:
                                  AppColors.buttonBackground.withOpacity(0.5),
                            ),
                            // The button is disabled until the user checks the box
                            onPressed: _agreedToTerms && !_isLoading
                                ? _signUpUser
                                : null,
                            child: const Text('Sign Up'),
                          ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text("Already have an account? ",
                            style: AppStyles.bodyText2
                                .copyWith(color: AppColors.secondaryText)),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              foregroundColor: AppColors.buttonBackground),
                          child: Text('Login',
                              style: AppStyles.bodyText1.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buttonBackground)),
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
