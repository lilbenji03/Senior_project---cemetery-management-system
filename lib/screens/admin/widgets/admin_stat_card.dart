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
    // A Tooltip is added for better UX, showing the full label on hover or long-press.
    return Tooltip(
      message: label,
      child: Card(
        // Use the Card's own properties for a cleaner implementation.
        elevation: AppStyles.elevationLow, // e.g., 2.0
        shadowColor: Colors.black.withOpacity(0.08),
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.cardBorderRadius,
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        // This ensures the InkWell splash effect is clipped to the card's rounded corners.
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
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
      ),
    );
  }
}
