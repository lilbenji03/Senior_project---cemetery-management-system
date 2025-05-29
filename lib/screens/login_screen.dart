import 'package:flutter/material.dart';
import 'signup_screen.dart'; // To navigate to SignUpScreen
import '../screens/main_screen.dart'; // To navigate to MainScreen after login
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

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

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // --- Simulate Login ---
      await Future.delayed(const Duration(seconds: 2));
      String email = _emailController.text;
      // String password = _passwordController.text; // In a real app, send this to your auth service

      // For now, any valid email format logs in
      // In a real app, you'd authenticate against a backend
      if (email.contains('@')) {
        // Simple check for demo
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid login credentials (simulated).'),
            ),
          );
        }
      }
      // --- End Simulate Login ---
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Login', style: AppStyles.appBarTitleStyle),
        backgroundColor: AppColors.appBar,
        elevation: 0, // Clean look for login/signup
        automaticallyImplyLeading: false, // No back button from Welcome
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
                  height: 100,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: AppStyles.cardTitleStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'you@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground.withOpacity(0.5),
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
                  border: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground.withOpacity(0.5),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                style: AppStyles.bodyText1,
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  // Add more password validation if needed (e.g., length)
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement Forgot Password
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forgot Password (Not Implemented)'),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppColors.appBar),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.appBar),
                  )
                  : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      foregroundColor: AppColors.buttonText,
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      textStyle: AppStyles.buttonTextStyle.copyWith(
                        fontSize: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppStyles.cardBorderRadius,
                      ),
                    ),
                    onPressed: _loginUser,
                    child: const Text('Login'),
                  ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Don't have an account? ", style: AppStyles.bodyText2),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
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
