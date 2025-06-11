// lib/constants/app_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  static const String fontFamily =
      'Roboto'; // Assuming Roboto is in your pubspec.yaml and assets

  // --- Text Styles ---
  static const TextStyle appBarTitleStyle = TextStyle(
    color: AppColors.appBarTitle,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 25, // Note: Your admin dashboard code uses 20 for app bar titles
  );

  static const TextStyle cardTitleStyle = TextStyle(
    color: AppColors.cardTitle,
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  // THIS IS THE STYLE THAT WAS MISSING AND CAUSING THE ERROR
  // Define it based on your needs. For the admin dashboard,
  // it was used as a base for text like "Dashboard Overview" and card titles.
  static final TextStyle titleStyle = TextStyle(
    // Changed from 'var' to 'final TextStyle'
    color:
        AppColors
            .primaryText, // Or AppColors.cardTitle, depending on default usage
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600, // Common for titles
    fontSize: 20, // A good default title size
  );

  static const TextStyle bodyText1 = TextStyle(
    color: AppColors.primaryText,
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
  );

  static const TextStyle regularText = TextStyle(
    color: AppColors.primaryText,
    fontFamily: fontFamily,
    fontSize: 16,
  );

  static final TextStyle bodyText2 = TextStyle(
    // Keep as 'final' not 'const' if using .withOpacity
    color: AppColors.secondaryText,
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.4,
  );

  static final TextStyle caption = TextStyle(
    // Keep as 'final' not 'const' if using .withOpacity
    color: AppColors.secondaryText.withOpacity(0.9),
    fontFamily: fontFamily,
    fontSize: 12,
  );

  static const TextStyle button = TextStyle(
    color: AppColors.buttonText,
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: AppColors.buttonText,
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle spotsAvailableStyle = TextStyle(
    color: AppColors.spotsAvailable,
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // DEFINE subtitleText if you plan to use it
  static final TextStyle subtitleText = TextStyle(
    // Changed from 'var' to 'final TextStyle'
    color: AppColors.secondaryText,
    fontFamily: fontFamily,
    fontSize: 16, // Example size, adjust as needed
    fontWeight: FontWeight.normal,
  );

  // --- Box Shadows ---
  static final List<BoxShadow> cardBoxShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      spreadRadius: 0,
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  // --- Borders & Radii ---
  static final BorderRadius cardBorderRadius = BorderRadius.circular(12.0);
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(8.0);

  // --- Paddings ---
  static const EdgeInsets pagePadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  // --- Elevations ---
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}
