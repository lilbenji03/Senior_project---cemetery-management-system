// lib/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import for RPC call
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../constants/legal_text.dart';
import 'profile_page.dart';
import '../services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final AuthService _authService = AuthService();

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not perform this action.'),
              backgroundColor: AppColors.errorColor),
        );
      }
    } else {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showLegalDialog(
      BuildContext context, String title, String markdownContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
        title: Text(title, style: AppStyles.cardTitleStyle),
        content: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: markdownContent,
                styleSheet:
                    MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: AppStyles.bodyText1,
                  h2: AppStyles.cardTitleStyle.copyWith(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close',
                style: TextStyle(
                    color: AppColors.appBar, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // ===                 *** DELETION LOGIC STARTS HERE ***              ===
  // =======================================================================

  // Method to handle the entire deletion flow with multiple confirmations
  void _handleAccountDeletion(BuildContext context) async {
    final userEmail =
        Supabase.instance.client.auth.currentUser?.email ?? 'your account';

    // First confirmation dialog
    final bool? confirmFirst = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
            'This action is permanent and cannot be undone. All your data, including reservations and profile information, will be deleted forever.\n\nAre you sure you want to proceed?'),
        shape: RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Continue'),
          ),
        ],
      ),
    );

    if (confirmFirst != true || !context.mounted) return;

    // Second confirmation: User must type their email to confirm
    final TextEditingController emailConfirmationController =
        TextEditingController();
    final bool? confirmSecond = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Final Confirmation'),
          content: SingleChildScrollView(
            // To avoid overflow when keyboard appears
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'To confirm permanent deletion, please type your email address below:'),
                const SizedBox(height: 8),
                Text(userEmail,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: emailConfirmationController,
                  decoration: const InputDecoration(labelText: 'Confirm Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            TextButton(
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.errorColor),
              onPressed: () {
                if (emailConfirmationController.text.trim().toLowerCase() ==
                    userEmail.toLowerCase()) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Email does not match.'),
                        backgroundColor: AppColors.errorColor),
                  );
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );

    if (confirmSecond != true || !context.mounted) return;

    // If both confirmations passed, execute the deletion
    _executeAccountDeletion(context);
  }

  void _executeAccountDeletion(BuildContext context) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.appBar)),
    );

    try {
      await Supabase.instance.client.rpc('delete_user_account');
      if (context.mounted)
        Navigator.of(context, rootNavigator: true).pop(); // Pop loading dialog
      // AuthGate will handle navigation
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deletion failed: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  // =======================================================================
  // ===                  *** END OF DELETION LOGIC ***                  ===
  // =======================================================================

  void _confirmLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Logout'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) _logout(context);
  }

  void _logout(BuildContext context) async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: AppColors.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: AppStyles.pagePadding.copyWith(top: 24.0, bottom: 24.0),
        children: <Widget>[
          // --- Account Section ---
          _buildSectionTitle('Account'),
          Card(
            elevation: AppStyles.elevationLow,
            shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius),
            clipBehavior: Clip.antiAlias,
            child: _buildSettingsItem(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Profile Management',
              subtitle: 'Update your personal details',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage())),
            ),
          ),
          const SizedBox(height: 24),

          // --- Support Section ---
          _buildSectionTitle('Support'),
          Card(
            elevation: AppStyles.elevationLow,
            shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildSettingsItem(context,
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'benjaminwali03@gmail.com',
                    onTap: () => _launchURL(context,
                        'mailto:benjaminwali03@gmail.com?subject=EternalSpace App Support Request')),
                _buildDivider(),
                _buildSettingsItem(context,
                    icon: Icons.phone_outlined,
                    title: 'Call Support',
                    subtitle: '+254740823906',
                    onTap: () => _launchURL(context, 'tel:+254740823906')),
                _buildDivider(),
                _buildSettingsItem(context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Contact via WhatsApp',
                    subtitle: '+254740823906',
                    onTap: () => _launchURL(context,
                        'https://wa.me/254740823906?text=Hello%20EternalSpace%20Support')),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Legal Section ---
          _buildSectionTitle('Legal'),
          Card(
            elevation: AppStyles.elevationLow,
            shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildSettingsItem(context,
                    icon: Icons.gavel_rounded,
                    title: 'Terms and Conditions',
                    onTap: () => _showLegalDialog(context,
                        'Terms and Conditions', LegalText.termsAndConditions)),
                _buildDivider(),
                _buildSettingsItem(context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showLegalDialog(
                        context, 'Privacy Policy', LegalText.privacyPolicy)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===========================================================
          // ===        *** NEW ACCOUNT MANAGEMENT SECTION ***         ===
          // ===========================================================
          _buildSectionTitle('Account Management'),
          Card(
            elevation: AppStyles.elevationLow,
            shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  iconColor: AppColors.errorColor,
                  onTap: () => _confirmLogout(context),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  context,
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account',
                  subtitle: 'This action is permanent',
                  iconColor: AppColors.errorColor, // Style to indicate danger
                  onTap: () => _handleAccountDeletion(context),
                ),
              ],
            ),
          ),
          // ===========================================================

          const SizedBox(height: 40),
          Center(child: Text('App Version 1.0.0', style: AppStyles.caption)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: AppStyles.bodyText2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryText,
            letterSpacing: 0.8),
      ),
    );
  }

  // UPDATED to handle custom colors
  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent, // Use transparent to show card color
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.appBar, size: 24),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: titleColor, // Apply custom color if provided
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppStyles.caption.copyWith(fontSize: 14)),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1,
        thickness: 1,
        indent: 60,
        endIndent: 16,
        color: AppColors.background);
  }
}
