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
  bool _isLoading = true; // Start with loading true for the initial fetch
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fetch initial data and show a loader. Subsequent updates will be smooth.
    _fetchNotifications(isInitialLoad: true);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // --- START OF FIX ---

  /// Fetches notifications from Supabase.
  ///
  /// Set [isInitialLoad] to true to show the centered loading indicator.
  /// Subsequent calls (e.g., from stream updates or pull-to-refresh) can
  /// omit this to provide a smoother update without a full-screen loader.
  Future<void> _fetchNotifications({bool isInitialLoad = false}) async {
    if (!mounted) return;

    // Only show the full-screen loader on the initial load.
    if (isInitialLoad) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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
        // Subscribe to real-time changes only once after the initial fetch succeeds.
        if (isInitialLoad) {
          _subscribeToChanges(userId);
        }

        setState(() {
          _notifications =
              response.map((data) => NotificationModel.fromJson(data)).toList();
          // If it was an initial load, we can now turn off the loader.
          if (isInitialLoad) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load notifications.";
          if (isInitialLoad) {
            _isLoading = false;
          }
        });
      }
    }
  }

  /// Subscribes to real-time changes in the user's notifications.
  ///
  /// This sets up a stream that listens for any inserts or updates to the
  /// notifications table for the current user, and then triggers a silent
  /// refresh of the notification list.
  void _subscribeToChanges(String userId) {
    _notificationSubscription?.cancel();
    _notificationSubscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId) // Important: Filter stream for the current user
        .listen(
          (data) {
            if (mounted) {
              // Refetch notifications without showing the full-screen loader.
              // This prevents the "blinking" UI.
              _fetchNotifications();
            }
          },
          onError: (e) => print("Notification stream error: $e"),
        );
  }

  /// Marks a notification as read with an optimistic UI update.
  Future<void> _markAsRead(String notificationId) async {
    // Optimistic UI update for instant feedback. The UI updates immediately
    // without waiting for the database call to complete.
    if (mounted) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        setState(() {
          final oldNotification = _notifications[index];
          _notifications[index] = NotificationModel(
            id: oldNotification.id,
            userId: oldNotification.userId,
            title: oldNotification.title,
            body: oldNotification.body,
            type: oldNotification.type,
            isRead: true, // The change
            createdAt: oldNotification.createdAt,
          );
        });
      }
    }

    // Perform the actual database update in the background.
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      print("Error marking notification as read: $e");
      // Optional: Revert the optimistic UI update on failure
    }
  }

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
          final iconData = _getIconDataForType(notification.type);
          final iconColor = _getColorForType(notification.type);

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            color: isUnread ? AppColors.cardBackground : AppColors.background,
            elevation: isUnread ? AppStyles.elevationLow : 0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(iconData, color: iconColor),
              ),
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
