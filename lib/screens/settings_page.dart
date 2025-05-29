// lib/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    // ... (your existing _launchURL method - no changes needed here)
    final Uri url = Uri.parse(urlString);
    if (urlString.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('URL is not available.')));
      }
      return;
    }
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  void _logout(BuildContext context) {
    // ... (your existing _logout method - no changes needed here)
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout action (simulated)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // REMOVED Scaffold and AppBar from here
    return Container(
      // Or directly ListView
      color: AppColors.background,
      child: ListView(
        padding: AppStyles.pagePadding.copyWith(top: 10.0),
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
          const Divider(indent: 16, endIndent: 16, height: 20),

          _buildSectionTitle('Support'),
          _buildSettingsItem(
            context,
            icon: Icons.contact_support_outlined,
            title: 'Contact Support (Email)',
            onTap:
                () => _launchURL(
                  context,
                  'mailto:support@cmcapp.com?subject=CMC App Support Request',
                ),
          ),
          _buildSettingsItem(
            context,
            icon: Icons.message_outlined,
            title: 'Contact Support (WhatsApp)',
            onTap:
                () => _launchURL(
                  context,
                  'https://wa.me/254000000000?text=Hello%20CMC%20Support',
                ),
          ),
          const Divider(indent: 16, endIndent: 16, height: 20),

          _buildSectionTitle('Legal'),
          _buildSettingsItem(
            context,
            icon: Icons.gavel_outlined,
            title: 'Terms and Conditions',
            onTap: () => _launchURL(context, 'https://yourcompany.com/terms'),
          ),
          _buildSettingsItem(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchURL(context, 'https://yourcompany.com/privacy'),
          ),
          const Divider(indent: 16, endIndent: 16, height: 20),

          _buildSectionTitle('App Info'),
          _buildSettingsItem(
            context,
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0 (Build 1)',
            onTap: null,
          ),
          const Divider(indent: 16, endIndent: 16, height: 30),

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
    // ... (your existing _buildSectionTitle method - no changes needed here)
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
    // ... (your existing _buildSettingsItem method - no changes needed here)
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
                        color: titleColor ?? AppColors.primaryText,
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
