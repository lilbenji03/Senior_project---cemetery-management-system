// lib/screens/admin/admin_overview_page.dart
import 'package:flutter/material.dart';
import '../../models/user_profile_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import 'widgets/admin_info_card.dart'; // Import new widget
import 'widgets/admin_stat_card.dart'; // Import new widget

// Helper (can be moved to a common utils file later)
String _getRoleDescription(String? role) {
  switch (role) {
    case 'cemetery_manager':
      return 'Cemetery Manager';
    case 'system_super_admin':
      return 'System Super Admin';
    default:
      return role
              ?.replaceAll('_', ' ')
              .split(' ')
              .map(
                (word) =>
                    word.isNotEmpty
                        ? word[0].toUpperCase() + word.substring(1)
                        : '',
              )
              .join(' ') ??
          'Unknown Role';
  }
}

class AdminOverviewScreen extends StatelessWidget {
  final UserProfile userProfile;
  final String? cemeteryId;
  final String? cemeteryName;

  const AdminOverviewScreen({
    super.key,
    required this.userProfile,
    this.cemeteryId,
    this.cemeteryName,
  });

  @override
  Widget build(BuildContext context) {
    // Determine number of columns for GridView based on screen width
    int crossAxisCount = 2;
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    }

    // Adjust childAspectRatio for better fit
    double childAspectRatio =
        (screenWidth / crossAxisCount) / 150; // Aim for a card height of ~150
    if (screenWidth < 600) {
      // Mobile portrait
      childAspectRatio =
          (screenWidth / crossAxisCount) / 140; // Allow a bit more height
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: AppStyles.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: AppStyles.titleStyle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 20),
            AdminInfoCard(
              iconData: Icons.person_pin_outlined,
              title: 'Admin Profile',
              children: [
                Text(
                  'Welcome, ${userProfile.fullName ?? userProfile.email}!',
                  style: AppStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Role: ${_getRoleDescription(userProfile.role)}',
                  style: AppStyles.bodyText2.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            if (userProfile.role == 'cemetery_manager' ||
                (userProfile.role == 'system_super_admin' &&
                    cemeteryName != "All Cemeteries (Super Admin)"))
              AdminInfoCard(
                iconData: Icons.account_balance_outlined,
                title: 'Cemetery Management Focus',
                children: [
                  if (userProfile.role == 'system_super_admin' &&
                      cemeteryName == "All Cemeteries (Super Admin)")
                    Text(
                      'Scope: All Cemeteries',
                      style: AppStyles.bodyText1.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.secondaryText,
                      ),
                    )
                  else if (cemeteryName != null &&
                      cemeteryName != "All Cemeteries (Super Admin)")
                    Text(
                      'Currently Managing: $cemeteryName',
                      style: AppStyles.bodyText1.copyWith(
                        color: AppColors.primaryText,
                      ),
                    )
                  else if (cemeteryId != null && cemeteryName == null)
                    Text(
                      'Managing Cemetery ID: ${cemeteryId?.substring(0, 8)}...',
                      style: AppStyles.bodyText1.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            Text(
              'Quick Statistics',
              style: AppStyles.titleStyle.copyWith(
                fontSize: 20,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio, // Use adjusted aspect ratio
              children: [
                AdminStatCard(
                  iconData: Icons.event_note_outlined,
                  label: 'Pending Reservations',
                  value: '0', // TODO: Fetch real data
                  iconColor: AppColors.statusPending,
                ),
                AdminStatCard(
                  iconData: Icons.map_outlined,
                  label: 'Occupied Spots',
                  value: '0', // TODO: Fetch real data
                  iconColor: AppColors.statusCompleted,
                ),
                AdminStatCard(
                  iconData: Icons.warning_amber_outlined,
                  label: 'Open Reports',
                  value: '0', // TODO: Fetch real data
                  iconColor: AppColors.errorColor,
                ),
                if (userProfile.role == 'system_super_admin')
                  AdminStatCard(
                    iconData: Icons.people_alt_outlined,
                    label: 'Total Users',
                    value: '0', // TODO: Fetch real data
                    iconColor: AppColors.statusApproved,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Add more sections here e.g., Recent Activity, System Health using AdminInfoCard
          ],
        ),
      ),
    );
  }
}
