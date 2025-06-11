// lib/models/user_profile_model.dart
class UserProfile {
  final String id; // Matches auth.uid()
  String? fullName;
  String? email;
  String? phoneNumber;
  String? profilePhotoUrl;
  String role;
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
      id: userId,
      fullName: json['full_name'] as String?,
      email: userEmail,
      phoneNumber: json['phone_number'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // --- ADD THIS METHOD ---
  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Typically not included in update payload body, used in .eq()
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      // 'role': role, // Usually role is not updated by user directly
      // 'email': email, // Email is usually updated via Supabase Auth methods
      // 'updated_at': DateTime.now().toIso8601String(), // DB trigger handles this
    };
  }

  // ----------------------
}
