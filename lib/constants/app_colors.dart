// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF0F4F8);
  static const Color appBar = Color.fromARGB(255, 93, 134, 98);
  static const Color appBarTitle = Color.fromARGB(255, 11, 14, 11);
  static const Color notificationIcon = Color.fromARGB(255, 18, 26, 19);

  static const Color cardTitle = Color(0xFF263238);
  static const Color primaryText = Color(0xFF37474F);
  static const Color secondaryText = Color(0xFF546E7A);

  static const Color spotsAvailable = Color(
    0xFF388E3C,
  ); // This is a good green for "approved" or "available"
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color progressBarTrack = Color(0xFFE0E0E0);
  static const Color progressBarFill = Color(0xFF4CAF50);

  static const Color buttonBackground = Color(0xFF2E7D32);
  static const Color buttonText = Color(0xFFFFFFFF);

  static const Color activeTab = Color(0xFF2E7D32);
  static const Color inactiveTab = Color(0xFF757575);

  static const Color selectedPaymentMethod = Color(0xFFE8F5E9);
  static const Color attachmentIcon = Color(0xFF2E7D32);

  static const Color errorColor = Colors.redAccent;

  // --- CORRECTED STATUS COLORS ---
  // Assign actual Color values and make them const
  static const Color statusCompleted = Color(
    0xFF0D47A1,
  ); // Example: Dark Blue (like your admin app's completed)
  static const Color statusPending =
      Colors.orange; // Example: Orange (like your admin app's pending)
  static const Color statusApproved = Color(
    0xFF2E7D32,
  ); // Example: Your primary green (similar to spotsAvailable)
  static const Color statusRejected = Colors.red; // Example: Red
  static const Color statusExpired = Colors.grey; // Example: Grey
  // -----------------------------
}
