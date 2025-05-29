// lib/services/profile_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String name;
  String email;
  String phone;

  UserProfile({this.name = '', this.email = '', this.phone = ''});
}

class ProfileService {
  static const String _nameKey = 'userName';
  static const String _emailKey = 'userEmail';
  static const String _phoneKey = 'userPhone';

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, profile.name);
    await prefs.setString(_emailKey, profile.email);
    await prefs.setString(_phoneKey, profile.phone);
  }

  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      name: prefs.getString(_nameKey) ?? '',
      email: prefs.getString(_emailKey) ?? '',
      phone: prefs.getString(_phoneKey) ?? '',
    );
  }
}
