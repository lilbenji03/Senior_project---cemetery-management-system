// lib/screens/admin/widgets/admin_info_card.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';

class AdminInfoCard extends StatelessWidget {
  final IconData iconData;
  final String title;
  final List<Widget> children;

  const AdminInfoCard({
    super.key,
    required this.iconData,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, // We will use a custom shadow for a more subtle effect.
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.cardBorderRadius,
        side:
            BorderSide(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppStyles.cardBorderRadius,
          color: AppColors.cardBackground,
          boxShadow: AppStyles.cardBoxShadow,
        ),
        child: Padding(
          padding: AppStyles.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Give the icon a modern, tinted background
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.activeTab.withOpacity(0.1),
                    child: Icon(iconData, color: AppColors.activeTab, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppStyles.cardTitleStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- CONTENT ---
              // This ensures consistent styling for content within the card
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
