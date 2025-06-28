// lib/screens/admin/widgets/admin_stat_card.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';

class AdminStatCard extends StatelessWidget {
  final IconData iconData;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.iconData,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primaryText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.cardBorderRadius,
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppStyles.cardBorderRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppStyles.cardBorderRadius,
            color: AppColors.cardBackground,
            boxShadow: AppStyles.cardBoxShadow,
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(iconData, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: AppStyles.bodyText2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- VALUE ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Spacer(),
                  // Add a clear visual indicator if the card is tappable
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.secondaryText,
                      size: 20,
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
