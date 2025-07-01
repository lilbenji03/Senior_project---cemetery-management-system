// lib/screens/admin/admin_dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/user_profile_model.dart';
import '../../services/auth_service.dart';

import 'admin_overview_screen.dart';
import 'manage_reports_admin_screen.dart';
import 'manage_reservations_admin_screen.dart';
import 'manage_spaces_admin_screen.dart';

// Helper class for page data
class _AdminPage {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;

  _AdminPage({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}

class AdminDashboardScreen extends StatefulWidget {
  final UserProfile userProfile;

  const AdminDashboardScreen({super.key, required this.userProfile});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  List<_AdminPage> _pages = [];
  bool _isScreenLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // These will now be set definitively for the manager
  String _managedCemeteryId = '';
  String _managedCemeteryName = '';

  @override
  void initState() {
    super.initState();
    _loadManagerData();
  }

  // SIMPLIFIED: This method now only handles the logic for a cemetery manager.
  Future<void> _loadManagerData() async {
    if (!mounted) return;
    setState(() => _isScreenLoading = true);

    // We assume the user profile role is 'cemetery_manager' to reach this screen.
    try {
      final response = await Supabase.instance.client
          .from('cemeteries')
          .select('id, name')
          .eq('manager_user_id', widget.userProfile.id)
          .single(); // Use .single() to throw an error if not exactly one is found

      _managedCemeteryId = response['id'] as String;
      _managedCemeteryName = response['name'] as String;

      _setupManagerPages();

      if (mounted) setState(() => _isScreenLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScreenLoading = false;
          _hasError = true;
          // Provide a much clearer error message for this specific case.
          _errorMessage =
              'Failed to load your assigned cemetery. Please ensure your account is correctly configured by a system administrator.';
        });
      }
    }
  }

  // SIMPLIFIED: This method no longer needs checks for different roles.
  void _setupManagerPages() {
    setState(() {
      _pages = [
        _AdminPage(
          title: 'Overview',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          page: AdminOverviewScreen(
            userProfile: widget.userProfile,
            cemeteryId: _managedCemeteryId,
            cemeteryName: _managedCemeteryName,
            onNavigateToTab: _onItemTapped,
          ),
        ),
        _AdminPage(
          title: 'Reservations',
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
          page: ManageReservationsAdminScreen(
            userProfile: widget.userProfile,
            cemeteryId: _managedCemeteryId,
            cemeteryName: _managedCemeteryName,
          ),
        ),
        _AdminPage(
          title: 'Spaces',
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          page: ManageSpacesAdminScreen(
            cemeteryId: _managedCemeteryId,
            cemeteryName: _managedCemeteryName,
          ),
        ),
        _AdminPage(
          title: 'Reports',
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
          page: ManageReportsAdminScreen(
            cemeteryId: _managedCemeteryId,
            cemeteryName: _managedCemeteryName,
          ),
        ),
      ];
    });
  }

  void _onItemTapped(int index) {
    if (index < _pages.length) setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isScreenLoading) return _buildLoadingScaffold();
    if (_hasError) return _buildErrorScreen();
    return _buildMainDashboard();
  }

  Scaffold _buildMainDashboard() {
    final currentPageTitle = _pages[_selectedIndex].title;
    // The subtitle is now always the managed cemetery name.
    final subtitle = _managedCemeteryName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentPageTitle, style: AppStyles.appBarTitleStyle),
            Text(subtitle,
                style: AppStyles.caption
                    .copyWith(color: AppColors.appBarTitle.withOpacity(0.8))),
          ],
        ),
        backgroundColor: AppColors.appBar,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () async => await AuthService().signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages.map((p) => p.page).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _pages
            .map((page) => BottomNavigationBarItem(
                  icon: Icon(page.icon),
                  activeIcon: Icon(page.activeIcon),
                  label: page.title,
                ))
            .toList(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.activeTab,
        unselectedItemColor: AppColors.inactiveTab,
        elevation: 8.0,
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Loading Manager Portal...',
            style: AppStyles.appBarTitleStyle),
        backgroundColor: AppColors.appBar,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.activeTab),
          ),
        ),
      ),
      body: const Center(
          child: CircularProgressIndicator(color: AppColors.activeTab)),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: AppStyles.elevationLow,
            shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.errorColor, size: 60),
                  const SizedBox(height: 20),
                  Text("Access Error",
                      textAlign: TextAlign.center,
                      style: AppStyles.titleStyle.copyWith(fontSize: 20)),
                  const SizedBox(height: 12),
                  Text(_errorMessage,
                      textAlign: TextAlign.center, style: AppStyles.bodyText2),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    onPressed: () async => await AuthService().signOut(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
