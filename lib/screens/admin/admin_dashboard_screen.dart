// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase client
import '../../models/user_profile_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/auth_service.dart';
// Removed import for WelcomeScreen as AuthGate handles it

// Import admin management screens
import 'manage_reservations_admin_screen.dart';
import 'manage_spots_admin_screen.dart'; // Ensure this file and class exist

// Placeholder for AdminOverviewPage if not in its own file
class AdminOverviewPage extends StatelessWidget {
  final UserProfile userProfile;
  final String? cemeteryId;
  final String? cemeteryName;
  const AdminOverviewPage({
    super.key,
    required this.userProfile,
    this.cemeteryId,
    this.cemeteryName,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Build a proper dashboard overview with actual data calls
    return Padding(
      padding: AppStyles.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: AppStyles.appBarTitleStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: AppStyles.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${userProfile.fullName ?? userProfile.email}!',
                  ),
                  Text('Your Role: ${userProfile.role}'),
                  if (cemeteryName != null) Text('Managing: $cemeteryName'),
                  if (cemeteryId != null && cemeteryName == null)
                    Text(
                      'Managing Cemetery ID: ${cemeteryId?.substring(0, 8)}...',
                    ),
                ],
              ),
            ),
          ),
          // Add more summary cards here later (e.g., pending reservations, open reports)
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  final UserProfile userProfile;

  const AdminDashboardScreen({super.key, required this.userProfile});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  List<Widget> _adminPages = []; // Initialize as empty
  List<BottomNavigationBarItem> _navItems = []; // Initialize as empty

  String? _managedCemeteryId;
  String? _managedCemeteryName;
  bool _isLoadingDetails = true; // Combined loading state

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Error: Not assigned to manage a specific cemetery.",
                ),
                backgroundColor: AppColors.errorColor,
              ),
            );
            // Consider logging out or showing a restricted UI
            AuthService().signOut(); // Example action
            return; // Stop further processing
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
          // Consider logging out
          AuthService().signOut();
          return;
        }
      }
    } else if (widget.userProfile.role == 'system_super_admin') {
      // Super admin doesn't manage one specific cemetery by default via manager_user_id
      // They might select one, or see all. For now, _managedCemeteryId remains null.
      _managedCemeteryName = "All Cemeteries (Super Admin)"; // Default display
    }

    _buildNavigation(); // Build navigation after attempting to fetch assignments
    if (mounted) {
      setState(() => _isLoadingDetails = false);
    }
  }

  void _buildNavigation() {
    List<Widget> pages = [];
    List<BottomNavigationBarItem> items = [];

    // Page 1: Overview
    pages.add(
      AdminOverviewPage(
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
    // Only add if cemetery_manager has an assigned cemetery OR if system_super_admin
    if ((widget.userProfile.role == 'cemetery_manager' &&
            _managedCemeteryId != null) ||
        widget.userProfile.role == 'system_super_admin') {
      pages.add(
        ManageReservationsAdminScreen(
          cemeteryId:
              _managedCemeteryId, // This will be null for super_admin initially, screen must handle it
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
    // Only add if cemetery_manager has an assigned cemetery OR if system_super_admin
    if ((widget.userProfile.role == 'cemetery_manager' &&
            _managedCemeteryId != null) ||
        widget.userProfile.role == 'system_super_admin') {
      pages.add(
        ManageSpotsAdminScreen(
          // Ensure this screen can handle a null cemeteryId for super_admin if needed
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

    // TODO: Add other pages like Reports, Services based on roles and cemetery context

    if (mounted) {
      setState(() {
        _adminPages = pages;
        _navItems = items;
        if (_selectedIndex >= _adminPages.length && _adminPages.isNotEmpty) {
          _selectedIndex = 0;
        } else if (_adminPages.isEmpty) {
          _selectedIndex =
              0; // Or handle this case by showing an error/empty state
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
    if (_isLoadingDetails) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Loading Admin Portal...",
            style: AppStyles.appBarTitleStyle,
          ),
          backgroundColor: AppColors.appBar,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.appBar),
        ),
      );
    }

    // This handles the case where a cemetery_manager has no assigned cemetery after loading
    if (widget.userProfile.role == 'cemetery_manager' &&
        _managedCemeteryId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Assignment Error", style: AppStyles.appBarTitleStyle),
          backgroundColor: AppColors.appBar,
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
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  "You are not assigned to manage a specific cemetery. Please contact the system administrator.",
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyText1,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    // AuthGate will navigate to login
                  },
                  child: const Text("Logout"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    String appBarTitle =
        _navItems.isNotEmpty &&
                _selectedIndex < _navItems.length &&
                _adminPages.isNotEmpty
            ? _navItems[_selectedIndex].label ?? "Admin"
            : "Admin Portal";

    if (widget.userProfile.role == 'cemetery_manager' &&
        _managedCemeteryName != null) {
      appBarTitle = "$_managedCemeteryName - $appBarTitle";
    } else if (widget.userProfile.role == 'system_super_admin' &&
        _managedCemeteryName != null) {
      // Super admin might be viewing a specific cemetery if they selected one
      appBarTitle = "$_managedCemeteryName - $appBarTitle";
    } else if (widget.userProfile.role == 'system_super_admin') {
      appBarTitle = "Super Admin - $appBarTitle";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: AppStyles.appBarTitleStyle),
        backgroundColor: AppColors.appBar,
        actions: [
          // TODO: Add a cemetery selector for system_super_admin if _managedCemeteryId is null
          // and _allCemeteriesForPicker is populated.
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
              ? const Center(
                child: Text(
                  "No management modules available for your role or selection.",
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
                selectedItemColor: AppColors.activeTab,
                unselectedItemColor: AppColors.inactiveTab,
                selectedLabelStyle: AppStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppStyles.caption,
              )
              : null,
    );
  }
}
