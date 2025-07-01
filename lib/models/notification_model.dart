// lib/models/notification_model.dart

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // e.g., 'info', 'success', 'warning'
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id'],
      userId: data['user_id'],
      title: data['title'] ?? 'No Title',
      body: data['body'] ?? 'No content.',
      type: data['type'] ?? 'info',
      isRead: data['is_read'] ?? false,
      createdAt: DateTime.parse(data['created_at']),
    );
  }
}
