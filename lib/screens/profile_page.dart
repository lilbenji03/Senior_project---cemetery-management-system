// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For AuthException
import '../services/auth_service.dart'; // Import your AuthService
import '../models/user_profile_model.dart'; // Import your UserProfile model
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile; // Nullable, as it will be fetched
  bool _isLoading = true; // Start with loading true
  String? _errorMessage;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController
  _emailController; // Email usually not editable directly by user here
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print("ProfilePage: Loading user profile...");
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) {
        if (profile != null) {
          setState(() {
            _userProfile = profile;
            _nameController.text = profile.fullName ?? '';
            _emailController.text =
                profile.email ??
                Supabase.instance.client.auth.currentUser?.email ??
                ''; // Get from profile or auth
            _phoneController.text = profile.phoneNumber ?? '';
            _isLoading = false;
          });
          print("ProfilePage: Profile loaded: ${profile.fullName}");
        } else {
          setState(() {
            _errorMessage =
                "Could not load profile. User might not have a profile entry or is not logged in.";
            _isLoading = false;
          });
          print("ProfilePage: Profile is null after fetching.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading profile: ${e.toString()}";
          _isLoading = false;
        });
        print("ProfilePage: Exception loading profile: $e");
      }
    }
  }

  Future<void> _saveUserProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save, user profile not loaded.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    print("ProfilePage: Saving user profile...");

    // Create a new UserProfile object or update the existing one
    // It's safer to create a new one or use copyWith if your model has it
    UserProfile updatedProfileData = UserProfile(
      id: _userProfile!.id, // Keep existing ID
      fullName: _nameController.text.trim(),
      email: _userProfile!.email, // Email typically not changed here by user
      phoneNumber: _phoneController.text.trim(),
      profilePhotoUrl:
          _userProfile!.profilePhotoUrl, // Preserve existing photo URL
      role: _userProfile!.role, // Role should not be changed by user
      createdAt: _userProfile!.createdAt, // Preserve original creation date
      updatedAt:
          DateTime.now(), // This will be overridden by DB trigger if present
    );

    try {
      await _authService.updateUserProfile(updatedProfileData);
      if (mounted) {
        setState(() {
          _userProfile =
              updatedProfileData; // Update local state with what was sent
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: AppColors.spotsAvailable,
          ),
        );
        print("ProfilePage: Profile saved.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        print("ProfilePage: Error saving profile: $e");
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

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    // value can be null
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.appBar, size: 22),
          const SizedBox(width: 16),
          SizedBox(
            width: 70, // Fixed width for labels
            child: Text(
              '$label:',
              style: AppStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value == null || value.isEmpty ? 'Not set' : value,
              style: AppStyles.bodyText1.copyWith(
                fontSize: 15,
                color:
                    (value == null || value.isEmpty)
                        ? Colors.grey.shade600
                        : AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    if (_userProfile == null) {
      return Text("No profile data to display.", style: AppStyles.bodyText2);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.person_outline, 'Name', _userProfile!.fullName),
        _buildInfoRow(
          Icons.email_outlined,
          'Email',
          _userProfile!.email ??
              Supabase.instance.client.auth.currentUser?.email,
        ),
        _buildInfoRow(Icons.phone_outlined, 'Phone', _userProfile!.phoneNumber),
        // You could add role display for debugging or if relevant
        // _buildInfoRow(Icons.admin_panel_settings_outlined, 'Role', _userProfile!.role),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
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
            // Email is usually not editable by the user directly here
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address (cannot be changed here)',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            style: AppStyles.bodyText1.copyWith(
              color: AppColors.secondaryText,
            ), // Indicate it's not primary input
            readOnly: true, // Make email read-only
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            style: AppStyles.bodyText1,
            keyboardType: TextInputType.phone,
            // Add validator for phone if needed
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This page is pushed, so it needs its own Scaffold & AppBar
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Profile' : 'My Profile',
          style: AppStyles.appBarTitleStyle,
        ),
        backgroundColor: AppColors.appBar,
        elevation: AppStyles.elevationLow,
        actions: [
          if (!_isLoading) // Only show actions if not globally loading
            if (!_isEditing)
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.notificationIcon,
                ),
                onPressed: () {
                  if (_userProfile != null) {
                    // Ensure profile is loaded before enabling edit
                    setState(() => _isEditing = true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile data not loaded yet.'),
                      ),
                    );
                  }
                },
                tooltip: 'Edit Profile',
              )
            else // In editing mode
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.notificationIcon,
                    ),
                    onPressed: () {
                      // Reset controllers to original values if cancelling edit
                      if (_userProfile != null) {
                        _nameController.text = _userProfile!.fullName ?? '';
                        _emailController.text =
                            _userProfile!.email ??
                            Supabase.instance.client.auth.currentUser?.email ??
                            '';
                        _phoneController.text = _userProfile!.phoneNumber ?? '';
                      }
                      setState(() => _isEditing = false);
                    },
                    tooltip: 'Cancel Edit',
                  ),
                  IconButton(
                    // Save button directly in AppBar when editing
                    icon: const Icon(
                      Icons.save_outlined,
                      color: AppColors.notificationIcon,
                    ),
                    onPressed: _saveUserProfile,
                    tooltip: 'Save Profile',
                  ),
                ],
              ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.appBar),
              )
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: AppStyles.bodyText1.copyWith(
                      color: AppColors.errorColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                                0.1,
                              ),
                              // TODO: Implement profile photo display using _userProfile.profilePhotoUrl
                              child:
                                  _userProfile?.profilePhotoUrl != null &&
                                          _userProfile!
                                              .profilePhotoUrl!
                                              .isNotEmpty
                                      ? ClipOval(
                                        child: Image.network(
                                          _userProfile!.profilePhotoUrl!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          errorBuilder:
                                              (c, e, s) => const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: AppColors.appBar,
                                              ),
                                        ),
                                      )
                                      : const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppColors.appBar,
                                      ),
                            ),
                            const SizedBox(height: 20),
                            if (_userProfile !=
                                null) // Only build form/info if profile exists
                              _isEditing
                                  ? _buildProfileForm()
                                  : _buildProfileView()
                            else if (!_isLoading) // If not loading and profile is still null
                              const Text("Could not load profile data."),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Save button is now in AppBar when editing, so removed from here
                    // if (_isEditing)
                    //   ElevatedButton.icon( /* ... */ ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
