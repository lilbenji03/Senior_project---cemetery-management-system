// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
// Or where your service/model are
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ... (all the logic from your provided ProfilePage code) ...
  // Including _loadUserProfile, _saveUserProfile, _buildProfileInfo, _buildProfileForm, etc.
  final ProfileService _profileService = ProfileService();
  UserProfile _userProfile = UserProfile(name: '', email: '', phone: '');
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    _userProfile = await _profileService.loadProfile();
    _nameController.text = _userProfile.name;
    _emailController.text = _userProfile.email;
    _phoneController.text = _userProfile.phone;
    setState(() => _isLoading = false);
  }

  Future<void> _saveUserProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final updatedProfile = UserProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );
      await _profileService.saveProfile(updatedProfile);
      _userProfile = updatedProfile;
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildProfileInfo() {
    // ... (your existing _buildProfileInfo method)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.person_outline, 'Name', _userProfile.name),
        _buildInfoRow(Icons.email_outlined, 'Email', _userProfile.email),
        _buildInfoRow(Icons.phone_outlined, 'Phone', _userProfile.phone),
      ],
    );
  }

  Widget _buildProfileForm() {
    // ... (your existing _buildProfileForm method)
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_outline),
              labelStyle: AppStyles.caption,
              hintStyle: AppStyles.caption.copyWith(color: Colors.grey),
            ),
            style: AppStyles.bodyText1,
            validator:
                (value) =>
                    (value == null || value.isEmpty)
                        ? 'Please enter your name'
                        : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.email_outlined),
              labelStyle: AppStyles.caption,
              hintStyle: AppStyles.caption.copyWith(color: Colors.grey),
            ),
            style: AppStyles.bodyText1,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.phone_outlined),
              labelStyle: AppStyles.caption,
              hintStyle: AppStyles.caption.copyWith(color: Colors.grey),
            ),
            style: AppStyles.bodyText1,
            keyboardType: TextInputType.phone,
            validator:
                (value) =>
                    (value == null || value.isEmpty)
                        ? 'Please enter your phone'
                        : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    // ... (your existing _buildInfoRow method)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.appBar, size: 24),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppStyles.bodyText1.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: AppStyles.bodyText1.copyWith(
                color:
                    value.isEmpty
                        ? Colors.grey[600]
                        : AppStyles.bodyText1.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (your existing build method for ProfilePage) ...
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Profile' : 'My Profile',
          style: AppStyles.appBarTitleStyle,
        ),
        backgroundColor: AppColors.appBar,
        elevation: AppStyles.elevationMedium,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.notificationIcon,
              ),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.notificationIcon),
              onPressed: () {
                _nameController.text = _userProfile.name;
                _emailController.text = _userProfile.email;
                _phoneController.text = _userProfile.phone;
                setState(() => _isEditing = false);
              },
              tooltip: 'Cancel Edit',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.appBar),
              )
              : SingleChildScrollView(
                padding: AppStyles.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: AppStyles.elevationLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppStyles.cardBorderRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.appBar.withOpacity(
                                0.2,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.appBar,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _isEditing
                                ? _buildProfileForm()
                                : _buildProfileInfo(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          foregroundColor: AppColors.buttonText,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          textStyle: AppStyles.buttonTextStyle,
                        ),
                        onPressed: _saveUserProfile,
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}

// You'll need UserProfile and ProfileService defined, for example:
// MOCK IMPLEMENTATIONS - MOVE TO DEDICATED FILES (e.g., lib/models/user_profile.dart, lib/services/profile_service.dart)
class UserProfile {
  String name;
  String email;
  String phone;
  UserProfile({this.name = '', this.email = '', this.phone = ''});
  // Add toJson/fromJson if needed
}

class ProfileService {
  Future<UserProfile> loadProfile() async {
    await Future.delayed(const Duration(seconds: 1));
    return UserProfile(
      name: "Mock User",
      email: "mock@example.com",
      phone: "0700000000",
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    await Future.delayed(const Duration(seconds: 1));
    // print("Saving profile: ${profile.name}");
  }
}
