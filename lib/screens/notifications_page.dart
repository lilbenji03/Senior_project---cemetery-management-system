// lib/screens/notifications_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _notificationSubscription;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User not authenticated.");
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications =
              response.map((data) => NotificationModel.fromJson(data)).toList();
          _isLoading = false;
        });
        _subscribeToChanges(userId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load notifications.";
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToChanges(String userId) {
    _notificationSubscription?.cancel();
    _notificationSubscription =
        _supabase.from('notifications').stream(primaryKey: ['id']).listen(
      (data) {
        if (mounted) {
          _fetchNotifications();
        }
      },
      onError: (e) => print("Notification stream error: $e"),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  // --- START OF FIX ---

  // Helper function to get the icon data based on type
  IconData _getIconDataForType(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  // Helper function to get the color based on type
  Color _getColorForType(String type) {
    switch (type) {
      case 'success':
        return AppColors.statusApproved;
      case 'warning':
        return AppColors.statusPending;
      case 'error':
        return AppColors.errorColor;
      case 'info':
      default:
        return AppColors.appBar;
    }
  }

  // --- END OF FIX ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: AppStyles.appBarTitleStyle),
        backgroundColor: AppColors.appBar,
        elevation: AppStyles.elevationLow,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.appBar));
    }
    if (_errorMessage != null) {
      return Center(
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined,
                size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text("No notifications yet", style: AppStyles.titleStyle),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: AppStyles.pagePadding,
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final bool isUnread = !notification.isRead;

          // --- START OF FIX ---
          // Get the icon and color using our new helper methods
          final iconData = _getIconDataForType(notification.type);
          final iconColor = _getColorForType(notification.type);
          // --- END OF FIX ---

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            color: isUnread ? AppColors.cardBackground : AppColors.background,
            elevation: isUnread ? AppStyles.elevationLow : 0,
            child: ListTile(
              // --- START OF FIX ---
              leading: CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(iconData,
                    color: iconColor), // Use the determined color
              ),
              // --- END OF FIX ---
              title: Text(
                notification.title,
                style: AppStyles.bodyText1.copyWith(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.body,
                    style: AppStyles.bodyText2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy, hh:mm a')
                        .format(notification.createdAt.toLocal()),
                    style: AppStyles.caption,
                  )
                ],
              ),
              onTap: () {
                if (isUnread) {
                  _markAsRead(notification.id);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
