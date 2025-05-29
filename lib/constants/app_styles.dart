// lib/constants/app_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  static const String fontFamily = 'Roboto';

  // --- Text Styles ---
  static const TextStyle appBarTitleStyle = TextStyle(
    color: AppColors.appBarTitle,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 25,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    color: AppColors.cardTitle,
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  static const TextStyle bodyText1 = TextStyle(
    color: AppColors.primaryText, // Using defined primaryText
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
  );

  static const TextStyle regularText = TextStyle(
    color: AppColors.primaryText, // Using defined primaryText
    fontFamily: fontFamily,
    fontSize: 16,
  );

  static TextStyle bodyText2 = TextStyle(
    // Changed to TextStyle from const TextStyle
    color: AppColors.secondaryText, // Using defined secondaryText
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.4,
  );

  static TextStyle caption = TextStyle(
    // Changed to TextStyle from const TextStyle
    color: AppColors.secondaryText.withOpacity(
      0.9,
    ), // Using defined secondaryText
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
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(
    8.0,
  ); // DEFINED

  // --- Paddings ---
  static const EdgeInsets pagePadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  // --- Elevations ---
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}
