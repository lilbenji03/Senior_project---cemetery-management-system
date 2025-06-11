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
      elevation: 2.0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: AppStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: AppColors.activeTab, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppStyles.titleStyle.copyWith(
                    fontSize: 18,
                    color: AppColors.cardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
