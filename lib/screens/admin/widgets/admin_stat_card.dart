// lib/screens/admin/widgets/admin_stat_card.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';

class AdminStatCard extends StatelessWidget {
  final IconData iconData;
  final String label;
  final String value;
  final Color iconColor;

  const AdminStatCard({
    super.key,
    required this.iconData,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppStyles.elevationLow, // Or 1.5 directly
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        // Further reduced vertical padding, horizontal can remain
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(iconData, size: 30, color: iconColor), // Icon size 30
            const SizedBox(height: 6), // Spacing reduced to 6
            Text(
              value,
              style: AppStyles.titleStyle.copyWith(
                // Assuming titleStyle is appropriate base
                fontSize: 18, // Value font size 18
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold, // Make value stand out
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2), // Spacing reduced to 2
            Text(
              label,
              style: AppStyles.caption.copyWith(
                // Using caption style as a base for smaller text
                color: AppColors.secondaryText,
                fontSize: 12, // Label font size 12
                height: 1.1, // Line height very tight
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
