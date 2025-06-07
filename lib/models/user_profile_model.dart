// lib/models/user_profile_model.dart
class UserProfile {
  final String id; // Matches auth.uid()
  String? fullName;
  String?
  email; // Often fetched from auth.currentUser or stored for convenience
  String? phoneNumber;
  String? profilePhotoUrl;
  String role; // 'user', 'staff_cemetery_manager', 'system_super_admin'
  DateTime createdAt;
  DateTime updatedAt;

  UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(
    Map<String, dynamic> json,
    String userId,
    String? userEmail,
  ) {
    return UserProfile(
      id: userId, // Use the auth.uid() passed in
      fullName: json['full_name'] as String?,
      email: userEmail, // Use the email from auth.currentUser
      phoneNumber: json['phone_number'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      role: json['role'] as String? ?? 'user', // Default to 'user' if null
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Important for upsert
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'role': role,
      // created_at and updated_at are usually handled by the database
    };
  }
}
