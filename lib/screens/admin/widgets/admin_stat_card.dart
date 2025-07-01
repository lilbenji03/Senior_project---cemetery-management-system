// lib/screens/admin/widgets/admin_stat_card.dart (Hypothetical/Example)
import 'package:flutter/material.dart';
import 'package:cmc/constants/app_colors.dart'; // Assuming you have this
import 'package:cmc/constants/app_styles.dart'; // Assuming you have this

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
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            // This is the Column mentioned in the error at line 41 (or similar)
            mainAxisAlignment:
                MainAxisAlignment.center, // or MainAxisAlignment.start
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  // This Text widget might be the one causing overflow if it's too long
                  // and not constrained.
                  Expanded(
                    // ✅ FIX 1: Wrap the label Text with Expanded
                    child: Text(
                      label,
                      style: AppStyles.bodyText2, // Adjust style if needed
                      overflow: TextOverflow
                          .ellipsis, // ✅ FIX 2: Add overflow ellipsis
                      maxLines: 1, // ✅ FIX 3: Limit max lines
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // This spacing might be too much
              Text(
                value,
                style: AppStyles.titleStyle
                    .copyWith(fontSize: 24), // Adjust font size if too large
              ),
            ],
          ),
        ),
      ),
    );
  }
}
