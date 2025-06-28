// lib/screens/admin/admin_dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart'; // ✅ Needed for .eq() and other query methods
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/user_profile_model.dart';
import '../../services/auth_service.dart';
import 'manage_reports_admin_screen.dart';
import 'manage_reservations_admin_screen.dart';
import 'manage_spaces_admin_screen.dart';
import 'widgets/admin_stat_card.dart';

// A helper class to organize page data for clean code.
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
  String _contextSubtitle = '';
  String? _managedCemeteryId;
  String? _managedCemeteryName;
  Map<String, String?> _dashboardStats = {
    'Pending Approval': null,
    'Completed Reservations': null,
    'Available Spaces': null,
    'Rejected Bookings': null,
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isScreenLoading = true);
    try {
      if (widget.userProfile.role == 'cemetery_manager') {
        final response = await Supabase.instance.client
            .from('cemeteries')
            .select('id, name')
            .eq('manager_user_id', widget.userProfile.id)
            .maybeSingle();

        if (response == null) {
          throw 'You are not assigned to manage a specific cemetery. Please contact the system administrator.';
        }

        _managedCemeteryId = response['id'] as String?;
        _managedCemeteryName = response['name'] as String?;
        _contextSubtitle = _managedCemeteryName ?? 'Manager';
      } else if (widget.userProfile.role == 'system_super_admin') {
        _contextSubtitle = 'System Overview';
      }

      _setupAdminPages();
      await _fetchDashboardStats();

      if (mounted) setState(() => _isScreenLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScreenLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      // Start queries with .select() to get a PostgrestFilterBuilder, which has the .eq() method.
      var reservationsQuery =
          Supabase.instance.client.from('reservations').select();
      var spacesQuery =
          Supabase.instance.client.from('cemetery_spaces').select();

      // Conditionally apply the cemetery filter. This works because .eq() returns a new PostgrestFilterBuilder.
      if (_managedCemeteryId != null) {
        reservationsQuery =
            reservationsQuery.eq('cemetery_id', _managedCemeteryId!);
        spacesQuery = spacesQuery.eq('cemetery_id', _managedCemeteryId!);
      }

      // Execute all count queries in parallel.
      // Each builder already contains the optional cemetery_id filter.
      final results = await Future.wait([
        reservationsQuery
            .eq('status', 'pending_approval')
            .count(CountOption.exact),
        reservationsQuery.eq('status', 'completed').count(CountOption.exact),
        spacesQuery.eq('status', 'available').count(CountOption.exact),
        reservationsQuery.eq('status', 'rejected').count(CountOption.exact),
      ]);

      if (mounted) {
        setState(() {
          // The result of a .count() query is a PostgrestResponse. Access the .count property.
          _dashboardStats = {
            'Pending Approval': results[0].count.toString(),
            'Completed Reservations': results[1].count.toString(),
            'Available Spaces': results[2].count.toString(),
            'Rejected Bookings': results[3].count.toString(),
          };
        });
      }
    } catch (e) {
      print("Error fetching dashboard stats: $e");
      if (mounted) {
        setState(() {
          _dashboardStats = {
            'Pending Approval': '!',
            'Completed Reservations': '!',
            'Available Spaces': '!',
            'Rejected Bookings': '!',
          };
        });
      }
    }
  }

  void _setupAdminPages() {
    final pages = <_AdminPage>[];
    final isSuperAdmin = widget.userProfile.role == 'system_super_admin';
    final isManager = widget.userProfile.role == 'cemetery_manager';
    final canManage = isSuperAdmin || (isManager && _managedCemeteryId != null);

    if (canManage) {
      pages.add(_AdminPage(
        title: 'Reservations',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        page: ManageReservationsAdminScreen(
          userProfile:
              widget.userProfile, // FIX: Added missing required parameter
          cemeteryId: _managedCemeteryId,
          cemeteryName: _managedCemeteryName,
        ),
      ));
      pages.add(_AdminPage(
        title: 'Spaces',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        page: ManageSpacesAdminScreen(
          cemeteryId: _managedCemeteryId,
          cemeteryName: _managedCemeteryName,
        ),
      ));
      pages.add(_AdminPage(
        title: 'Reports',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        page: ManageReportsAdminScreen(
          cemeteryId: _managedCemeteryId,
          cemeteryName: _managedCemeteryName,
          isSuperAdmin: isSuperAdmin,
        ),
      ));
    }

    setState(() => _pages = pages);
  }

  void _onItemTapped(int index) {
    if (index < _pages.length) setState(() => _selectedIndex = index);
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: AppColors.background,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.9,
        children: [
          AdminStatCard(
            iconData: Icons.hourglass_top_rounded,
            label: 'Pending Approval',
            value: _dashboardStats['Pending Approval'] ?? '–',
            iconColor: Colors.orange.shade700,
            onTap: () => _onItemTapped(0),
          ),
          AdminStatCard(
            iconData: Icons.task_alt_rounded,
            label: 'Completed',
            value: _dashboardStats['Completed Reservations'] ?? '–',
            iconColor: AppColors.statusCompleted,
          ),
          AdminStatCard(
            iconData: Icons.event_available_rounded,
            label: 'Available Spaces',
            value: _dashboardStats['Available Spaces'] ?? '–',
            iconColor: AppColors.activeTab,
            onTap: () {
              final index = _pages.indexWhere((p) => p.title == 'Spaces');
              if (index != -1) _onItemTapped(index);
            },
          ),
          AdminStatCard(
            iconData: Icons.thumb_down_outlined,
            label: 'Rejected',
            value: _dashboardStats['Rejected Bookings'] ?? '–',
            iconColor: AppColors.errorColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isScreenLoading) return _buildLoadingScaffold();
    if (_hasError) return _buildErrorScreen();
    return _buildMainDashboard();
  }

  Scaffold _buildMainDashboard() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Dashboard', style: AppStyles.appBarTitleStyle),
            Text(_contextSubtitle,
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
      body: Column(
        children: [
          _buildDashboardHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child: _pages.isEmpty
                ? const Center(child: Text("No management modules available."))
                : IndexedStack(
                    index: _selectedIndex,
                    children: _pages.map((p) => p.page).toList(),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _pages.length > 1
          ? BottomNavigationBar(
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
            )
          : null,
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Loading Admin Portal...',
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
