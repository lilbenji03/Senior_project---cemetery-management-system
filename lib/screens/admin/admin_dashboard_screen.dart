// lib/screens/admin/admin_dashboard_screen.dart
import 'package:cmc/screens/admin/admin_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/auth_service.dart';
import 'manage_reservations_admin_screen.dart';
import 'manage_spots_admin_screen.dart';
import 'manage_reports_admin_screen.dart'; // <<< IMPORT THE NEW SCREEN

class AdminDashboardScreen extends StatefulWidget {
  final UserProfile userProfile;

  const AdminDashboardScreen({super.key, required this.userProfile});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  List<Widget> _adminPages = [];
  List<BottomNavigationBarItem> _navItems = [];

  String? _managedCemeteryId;
  String? _managedCemeteryName;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // ... (existing _loadInitialData logic remains the same) ...
    if (!mounted) return;
    setState(() => _isLoadingDetails = true);

    if (widget.userProfile.role == 'cemetery_manager') {
      try {
        final response =
            await Supabase.instance.client
                .from('cemeteries')
                .select('id, name')
                .eq('manager_user_id', widget.userProfile.id)
                .maybeSingle();

        if (mounted) {
          if (response != null) {
            _managedCemeteryId = response['id'] as String?;
            _managedCemeteryName = response['name'] as String?;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Error: Not assigned to manage any cemetery."),
                  backgroundColor: AppColors.errorColor,
                ),
              );
              AuthService().signOut();
            }
            return;
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error fetching cemetery assignment: $e"),
              backgroundColor: AppColors.errorColor,
            ),
          );
          AuthService().signOut();
        }
        return;
      }
    } else if (widget.userProfile.role == 'system_super_admin') {
      _managedCemeteryName = "All Cemeteries (Super Admin)";
    }

    _buildNavigation(); // This will now include the Reports tab
    if (mounted) {
      setState(() => _isLoadingDetails = false);
    }
  }

  void _buildNavigation() {
    List<Widget> pages = [];
    List<BottomNavigationBarItem> items = [];
    bool isSuperAdmin = widget.userProfile.role == 'system_super_admin';
    bool isCemeteryManagerWithAssignment =
        widget.userProfile.role == 'cemetery_manager' &&
        _managedCemeteryId != null;

    // Page 1: Overview (Always available)
    pages.add(
      AdminOverviewScreen(
        userProfile: widget.userProfile,
        cemeteryId: _managedCemeteryId,
        cemeteryName: _managedCemeteryName,
      ),
    );
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Overview',
      ),
    );

    // Page 2: Reservations
    if (isCemeteryManagerWithAssignment || isSuperAdmin) {
      pages.add(
        ManageReservationsAdminScreen(
          cemeteryId: _managedCemeteryId,
          cemeteryName: _managedCemeteryName,
        ),
      );
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Reservations',
        ),
      );
    }

    // Page 3: Spots Management
    if (isCemeteryManagerWithAssignment || isSuperAdmin) {
      pages.add(
        ManageSpotsAdminScreen(
          cemeteryId: _managedCemeteryId,
          cemeteryName: _managedCemeteryName,
        ),
      );
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.grid_on_outlined),
          activeIcon: Icon(Icons.grid_on),
          label: 'Spots',
        ),
      );
    }

    // Page 4: Reports (Available for both roles, screen handles context)
    if (isCemeteryManagerWithAssignment || isSuperAdmin) {
      // Or just `true` if all admins should see reports
      pages.add(
        ManageReportsAdminScreen(
          cemeteryId: _managedCemeteryId,
          cemeteryName: _managedCemeteryName,
          isSuperAdmin: isSuperAdmin,
        ),
      );
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.report_problem_outlined),
          activeIcon: Icon(Icons.report_problem),
          label: 'Reports',
        ),
      );
    }
    // TODO: Add other pages like Users (for super_admin), Settings, etc.

    if (mounted) {
      setState(() {
        _adminPages = pages;
        _navItems = items;
        // Adjust selectedIndex if it's out of bounds after rebuilding nav
        if (_selectedIndex >= _adminPages.length && _adminPages.isNotEmpty) {
          _selectedIndex = 0;
        } else if (_adminPages.isEmpty) {
          // This case should ideally not happen if Overview is always present
          // Or handle by showing an error/empty state for the whole dashboard
          _selectedIndex = 0;
        }
      });
    }
  }

  void _onItemTapped(int index) {
    if (index < _adminPages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing build method for loading, error, and main scaffold remains the same) ...
    // The BottomNavigationBar will automatically pick up the new item.
    // The AppBar title will also update based on the selected tab's label.
    if (_isLoadingDetails) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            "Loading Admin Portal...",
            style: AppStyles.appBarTitleStyle.copyWith(
              color: AppColors.appBarTitle,
            ),
          ),
          backgroundColor: AppColors.appBar,
          iconTheme: const IconThemeData(color: AppColors.appBarTitle),
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.activeTab),
        ),
      );
    }

    if (widget.userProfile.role == 'cemetery_manager' &&
        _managedCemeteryId == null &&
        !_isLoadingDetails) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            "Assignment Error",
            style: AppStyles.appBarTitleStyle.copyWith(
              color: AppColors.appBarTitle,
            ),
          ),
          backgroundColor: AppColors.appBar,
          iconTheme: const IconThemeData(color: AppColors.appBarTitle),
        ),
        body: Padding(
          padding: AppStyles.pagePadding,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.errorColor,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  "You are not assigned to manage a specific cemetery. Please contact the system administrator.",
                  textAlign: TextAlign.center,
                  style: AppStyles.titleStyle.copyWith(
                    fontSize: 18,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "You will be logged out.",
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyText2.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: AppColors.buttonText),
                  label: const Text(
                    "Logout",
                    style: TextStyle(color: AppColors.buttonText),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                  ),
                  onPressed: () async {
                    await AuthService().signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    String pageTitle =
        _navItems.isNotEmpty &&
                _selectedIndex < _navItems.length &&
                _adminPages.isNotEmpty
            ? _navItems[_selectedIndex].label ?? "Admin"
            : "Admin Portal";

    String appBarTitlePrefix = "";
    if (widget.userProfile.role == 'cemetery_manager' &&
        _managedCemeteryName != null) {
      appBarTitlePrefix = "$_managedCemeteryName - ";
    } else if (widget.userProfile.role == 'system_super_admin') {
      if (_managedCemeteryId != null &&
          _managedCemeteryName != "All Cemeteries (Super Admin)") {
        appBarTitlePrefix = "$_managedCemeteryName - ";
      } else {
        appBarTitlePrefix = "Super Admin - ";
      }
    }
    String finalAppBarTitle = "$appBarTitlePrefix$pageTitle";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          finalAppBarTitle,
          style: AppStyles.appBarTitleStyle.copyWith(
            color: AppColors.appBarTitle,
          ),
        ),
        backgroundColor: AppColors.appBar,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: AppColors.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: AppColors.appBarTitle,
            ),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body:
          _adminPages.isEmpty
              ? Center(
                child: Padding(
                  padding: AppStyles.pagePadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.layers_clear_outlined,
                        size: 60,
                        color: AppColors.secondaryText.withOpacity(0.7),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No management modules available.",
                        textAlign: TextAlign.center,
                        style: AppStyles.titleStyle.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "This might be due to your role or current selection context.",
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyText2.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : IndexedStack(index: _selectedIndex, children: _adminPages),
      bottomNavigationBar:
          _adminPages.length > 1 && _navItems.length == _adminPages.length
              ? BottomNavigationBar(
                items: _navItems,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.cardBackground,
                selectedItemColor: AppColors.activeTab,
                unselectedItemColor: AppColors.inactiveTab.withOpacity(0.8),
                selectedLabelStyle: AppStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppStyles.caption,
                showUnselectedLabels: true,
                elevation: 4.0,
              )
              : null,
    );
  }
}
