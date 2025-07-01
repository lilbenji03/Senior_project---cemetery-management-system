// lib/screens/admin/admin_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import 'widgets/admin_info_card.dart';
import 'widgets/admin_stat_card.dart';

// This helper is still useful for displaying the role name nicely.
String _getRoleDescription(String? role) {
  if (role == 'cemetery_manager') {
    return 'Cemetery Manager';
  }
  return 'Admin'; // Fallback
}

class AdminOverviewScreen extends StatefulWidget {
  final UserProfile userProfile;
  final String? cemeteryId;
  final String? cemeteryName;
  final void Function(int) onNavigateToTab;

  const AdminOverviewScreen({
    super.key,
    required this.userProfile,
    this.cemeteryId,
    this.cemeteryName,
    required this.onNavigateToTab,
  });

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  // SIMPLIFIED: Removed _totalUsersCount as it's not for managers.
  int _pendingReservationsCount = 0;
  int _occupiedSpacesCount = 0;
  int _openReportsCount = 0;

  bool _isLoadingStats = true;
  String? _statsErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  @override
  void didUpdateWidget(covariant AdminOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cemeteryId != oldWidget.cemeteryId ||
        widget.userProfile.id != oldWidget.userProfile.id) {
      _fetchDashboardStats();
    }
  }

  // SIMPLIFIED: This method now only fetches stats relevant to the manager's cemetery.
  Future<void> _fetchDashboardStats() async {
    if (!mounted || widget.cemeteryId == null) {
      // Don't fetch if there's no cemetery context.
      setState(() {
        _isLoadingStats = false;
        _statsErrorMessage = "No cemetery assigned to fetch statistics.";
      });
      return;
    }

    setState(() {
      _isLoadingStats = true;
      _statsErrorMessage = null;
    });

    try {
      final client = Supabase.instance.client;

      // All queries are now filtered by the manager's cemeteryId.
      final cemeteryFilter = widget.cemeteryId!;

      final futures = <Future<PostgrestResponse>>[
        client
            .from('reservations')
            .select()
            .eq('cemetery_id', cemeteryFilter)
            .eq('status', 'pending_approval')
            .count(CountOption.exact),
        client
            .from('cemetery_spaces')
            .select()
            .eq('cemetery_id', cemeteryFilter)
            .eq('status', 'used')
            .count(CountOption.exact),
        client
            .from('reports')
            .select()
            .eq('cemetery_id', cemeteryFilter)
            .eq('status', 'new_report')
            .count(CountOption.exact),
      ];

      final responses = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _pendingReservationsCount = responses[0].count ?? 0;
          _occupiedSpacesCount = responses[1].count ?? 0;
          _openReportsCount = responses[2].count ?? 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsErrorMessage = "Failed to load statistics.";
          _isLoadingStats = false;
        });
      }
    }
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.appBar));
    }
    if (_statsErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(_statsErrorMessage!,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyText1
                      .copyWith(color: AppColors.errorColor)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                onPressed: _fetchDashboardStats,
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.appBar),
              )
            ],
          ),
        ),
      );
    }

    // SIMPLIFIED: The 'Total Users' card is removed.
    List<Widget> statCards = [
      AdminStatCard(
        iconData: Icons.event_note_outlined,
        label: 'Pending Reservations',
        value: _pendingReservationsCount.toString(),
        iconColor: AppColors.statusPending,
        onTap: () => widget.onNavigateToTab(1),
      ),
      AdminStatCard(
        iconData: Icons.event_seat_outlined,
        label: 'Occupied Spaces',
        value: _occupiedSpacesCount.toString(),
        iconColor:
            AppColors.statusUsed ?? AppColors.primaryText, // Fallback color
        onTap: () => widget.onNavigateToTab(2),
      ),
      AdminStatCard(
        iconData: Icons.report_problem_outlined,
        label: 'Open Reports',
        value: _openReportsCount.toString(),
        iconColor: AppColors.errorColor,
        onTap: () => widget.onNavigateToTab(3),
      ),
    ];

    // Responsive grid layout
    int crossAxisCount = MediaQuery.of(context).size.width < 600 ? 2 : 3;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: statCards.length,
      itemBuilder: (context, index) => statCards[index],
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    String welcomeMessage =
        'Welcome, ${widget.userProfile.fullName ?? widget.userProfile.email ?? 'Manager'}!';
    String roleDescription = _getRoleDescription(widget.userProfile.role);

    // SIMPLIFIED: No more 'isSuperAdmin' checks.
    Widget cemeteryFocusContent = Text(
      'Managing: ${widget.cemeteryName ?? 'N/A'}',
      style: AppStyles.bodyText2.copyWith(color: AppColors.secondaryText),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchDashboardStats,
        color: AppColors.appBar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminInfoCard(
                iconData: Icons.admin_panel_settings_outlined,
                title: 'Manager Details',
                children: [
                  Text(welcomeMessage,
                      style: AppStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryText)),
                  const SizedBox(height: 6),
                  Text('Role: $roleDescription',
                      style: AppStyles.bodyText2
                          .copyWith(color: AppColors.secondaryText)),
                  const SizedBox(height: 6),
                  cemeteryFocusContent,
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Cemetery Statistics',
                style: AppStyles.titleStyle.copyWith(
                    fontSize: 22,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildStatsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
