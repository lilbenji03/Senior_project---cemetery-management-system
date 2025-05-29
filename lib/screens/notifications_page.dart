// lib/screens/notifications_page.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This page should have its own AppBar because it's a new route,
    // not part of the MainScreen's tabbed interface.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: AppStyles.appBarTitleStyle),
        backgroundColor: AppColors.appBar,
        elevation: AppStyles.elevationLow,
        // The back button will be automatically added by Navigator if this page is pushed
      ),
      body: ListView.builder(
        padding: AppStyles.pagePadding,
        itemCount: 5, // Replace with actual number of notifications
        itemBuilder: (context, index) {
          // Replace with actual notification data and widget
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.appBar.withOpacity(0.15),
                child: Icon(
                  index % 2 == 0
                      ? Icons.info_outline
                      : Icons.warning_amber_outlined,
                  color: AppColors.appBar,
                ),
              ),
              title: Text(
                'Notification Title ${index + 1}',
                style: AppStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'This is the detail for notification ${index + 1}. Tap to see more or take action.',
                style: AppStyles.bodyText2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // TODO: Handle tapping on a specific notification
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tapped on notification ${index + 1}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
