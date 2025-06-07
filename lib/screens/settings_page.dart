// lib/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'profile_page.dart';
import '../services/auth_service.dart'; // Ensure this path is correct

class SettingsPage extends StatelessWidget {
  // It's good practice to make StatelessWidget constructors const if all fields are final.
  // However, since _authService is final but initialized here, we remove 'const' from the constructor.
  SettingsPage({super.key});

  final AuthService _authService = AuthService(); // Instance of AuthService

  // CORRECTED AND ROBUST _launchURL METHOD
  Future<void> _launchURL(BuildContext context, String? urlString) async {
    // For debugging:
    // print("Attempting to launch URL: '$urlString'");

    if (urlString == null || urlString.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL is not available or is invalid.')),
        );
      }
      return;
    }

    String effectiveUrlString = urlString.trim();

    // Attempt to prepend a scheme if it looks like a web URL without one
    if (!effectiveUrlString.startsWith(RegExp(r'[a-zA-Z]+://')) &&
        (effectiveUrlString.contains('.') ||
            effectiveUrlString.startsWith('www.'))) {
      effectiveUrlString = 'https://$effectiveUrlString';
      // print("Prepended https, new URL: '$effectiveUrlString'");
    }

    Uri? uri;
    try {
      uri = Uri.parse(effectiveUrlString);
      // A more robust check for web URLs after parsing
      if ((uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isEmpty) {
        throw FormatException("Parsed URI has no host: $effectiveUrlString");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid URL format: $effectiveUrlString')),
        );
      }
      return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // This specific error might not be reached often if Uri.parse succeeds and canLaunchUrl handles it
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch $effectiveUrlString. Please check if a supporting app is installed.',
            ),
          ),
        );
      }
    }
  }

  void _logout(BuildContext context) async {
    try {
      await _authService.signOut();
      // AuthGate will handle navigation after signOut.
      // No explicit navigation needed here if AuthGate is correctly set up.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is the body content for a tab in MainScreen.
    // NO Scaffold or AppBar here.
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: AppStyles.pagePadding.copyWith(top: 10.0, bottom: 20.0),
        children: <Widget>[
          _buildSectionTitle('Account'),
          _buildSettingsItem(
            context,
            icon: Icons.person_outline,
            title: 'Profile Management',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 20, thickness: 0.5),

          _buildSectionTitle('Support'),
          _buildSettingsItem(
            context,
            icon: Icons.contact_support_outlined,
            title: 'Contact Support (Email)',
            onTap:
                () => _launchURL(
                  context,
                  'mailto:support@eternalspace.com?subject=EternalSpace App Support Request',
                ),
          ),
          _buildSettingsItem(
            context,
            icon: Icons.message_outlined,
            title: 'Contact Support (WhatsApp)',
            onTap:
                () => _launchURL(
                  context,
                  // Ensure this is a valid WhatsApp link structure
                  'https://wa.me/254700000000?text=Hello%20EternalSpace%20Support', // Replace with actual number
                ),
          ),
          const Divider(indent: 16, endIndent: 16, height: 20, thickness: 0.5),

          _buildSectionTitle('Legal'),
          _buildSettingsItem(
            context,
            icon: Icons.gavel_outlined,
            title: 'Terms and Conditions',
            // Example: if your URL is just 'eternalspace.com/terms', the _launchURL will prepend 'https://'
            onTap: () => _launchURL(context, 'eternalspace.com/terms'),
          ),
          _buildSettingsItem(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchURL(context, 'eternalspace.com/privacy'),
          ),
          const Divider(indent: 16, endIndent: 16, height: 20, thickness: 0.5),

          _buildSectionTitle('App Info'),
          _buildSettingsItem(
            context,
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle:
                '1.0.0 (Build 1)', // TODO: Get this dynamically using package_info_plus
            onTap: null,
          ),
          const Divider(indent: 16, endIndent: 16, height: 30, thickness: 0.5),

          _buildSettingsItem(
            context,
            icon: Icons.logout_outlined,
            title: 'Logout',
            titleColor: AppColors.errorColor,
            iconColor: AppColors.errorColor,
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 8.0,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppStyles.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.appBar.withOpacity(0.9),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.appBar, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? AppStyles.bodyText1.color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppStyles.caption.copyWith(
                          color: AppStyles.caption.color?.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade500,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
