import 'package:flutter/material.dart';
import 'login_screen.dart'; // To navigate to the LoginScreen
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Or a custom welcome background
      body: SafeArea(
        child: Padding(
          padding: AppStyles.pagePadding.copyWith(top: 40.0, bottom: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: [
                  // App Logo
                  Image.asset(
                    'assets/images/app_logo.png', // Ensure this path is correct
                    height: 150, // Adjust size as needed
                    width: 150,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Welcome to CMC', // Your App Name
                    style: AppStyles.cardTitleStyle.copyWith(
                      fontSize: 28,
                      color: AppColors.appBar, // Using your primary green
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Your compassionate guide to cemetery services. Find loved ones, manage grave care, and access essential information with ease and respect.',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyText1.copyWith(
                        fontSize: 16,
                        color: AppColors.cardTitle.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  foregroundColor: AppColors.buttonText,
                  minimumSize: const Size(
                    double.infinity,
                    50,
                  ), // Full width button
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: AppStyles.buttonTextStyle.copyWith(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        AppStyles
                            .cardBorderRadius, // Use consistent border radius
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    // Go to Login, don't allow back to Welcome
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
