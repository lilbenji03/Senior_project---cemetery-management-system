// // lib/screens/admin/admin_overview_screen.dart
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase client
// import '../../models/user_profile_model.dart';
// import '../../constants/app_colors.dart';
// import '../../constants/app_styles.dart';
// import 'widgets/admin_info_card.dart'; // Ensure this widget exists
// import 'widgets/admin_stat_card.dart'; // Ensure this widget exists and has 'onTap'

// // Helper (can be moved to a common utils file later)
// String _getRoleDescription(String? role) {
//   switch (role) {
//     case 'cemetery_manager':
//       return 'Cemetery Manager';
//     case 'system_super_admin':
//       return 'System Super Admin';
//     default:
//       return role
//               ?.replaceAll('_', ' ')
//               .split(' ')
//               .map((word) => word.isNotEmpty
//                   ? word[0].toUpperCase() + word.substring(1)
//                   : '')
//               .join(' ') ??
//           'Unknown Role';
//   }
// }

// class AdminOverviewScreen extends StatefulWidget {
//   final UserProfile userProfile;
//   final String?
//       cemeteryId; // ID of the cemetery the manager is assigned to, or null for super admin (all)
//   final String? cemeteryName; // Name of the assigned cemetery

//   const AdminOverviewScreen({
//     super.key,
//     required this.userProfile,
//     this.cemeteryId,
//     this.cemeteryName,
//   });

//   @override
//   State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
// }

// class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
//   // State variables for statistics
//   int _pendingReservationsCount = 0;
//   int _occupiedSpacesCount = 0;
//   int _openReportsCount = 0;
//   int _totalUsersCount = 0; // For super admin

//   bool _isLoadingStats = true;
//   String? _statsErrorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _fetchDashboardStats();
//   }

//   @override
//   void didUpdateWidget(covariant AdminOverviewScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.cemeteryId != oldWidget.cemeteryId ||
//         widget.userProfile.id != oldWidget.userProfile.id) {
//       _fetchDashboardStats();
//     }
//   }

//   Future<void> _fetchDashboardStats() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoadingStats = true;
//       _statsErrorMessage = null;
//     });

//     try {
//       final client = Supabase.instance.client;

//       // Fetch pending reservations count
//       var queryReservations =
//           client.from('reservations').select('id'); // Select a minimal column
//       if (widget.cemeteryId != null) {
//         queryReservations =
//             queryReservations.eq('cemetery_id', widget.cemeteryId!);
//       }
//       final pendingReservationsResponse = await queryReservations
//           .eq('status',
//               'pendingApproval') // Ensure 'pendingApproval' matches your DB status string
//           .count(CountOption.exact);
//       _pendingReservationsCount = pendingReservationsResponse.count ?? 0;

//       // Fetch occupied spaces count
//       var querySpaces = client
//           .from('cemetery_spaces') // Ensure this is your spaces table name
//           .select('id');
//       if (widget.cemeteryId != null) {
//         querySpaces = querySpaces.eq('cemetery_id', widget.cemeteryId!);
//       }
//       final occupiedSpacesResponse = await querySpaces
//           .eq('status',
//               'used') // Ensure 'used' matches your DB status string for occupied spaces
//           .count(CountOption.exact);
//       _occupiedSpacesCount = occupiedSpacesResponse.count ?? 0;

//       // Fetch open reports count
//       var queryReports = client
//           .from('reports') // Ensure this is your reports table name
//           .select('id');
//       // if (widget.cemeteryId != null) { // Uncomment if reports are also scoped by cemetery
//       //   queryReports = queryReports.eq('cemetery_id', widget.cemeteryId!);
//       // }
//       final openReportsResponse = await queryReports
//           .eq('status',
//               'newReport') // Ensure 'newReport' or 'open' matches your DB status for open reports
//           .count(CountOption.exact);
//       _openReportsCount = openReportsResponse.count ?? 0;

//       // Fetch total users count (only for super admin)
//       if (widget.userProfile.role == 'system_super_admin') {
//         final totalUsersResponse = await client
//             .from('profiles') // Ensure this is your user profiles table
//             .select('id')
//             .count(CountOption.exact);
//         _totalUsersCount = totalUsersResponse.count ?? 0;
//       }

//       if (mounted) {
//         setState(() => _isLoadingStats = false);
//       }
//     } catch (e, s) {
//       // Added stacktrace for more debug info
//       print("Error fetching dashboard stats: $e");
//       print("Stacktrace: $s");
//       if (mounted) {
//         setState(() {
//           _statsErrorMessage = "Failed to load statistics. Please try again.";
//           _isLoadingStats = false;
//         });
//       }
//     }
//   }

//   Widget _buildStatsSection() {
//     if (_isLoadingStats) {
//       return const Center(
//           child: CircularProgressIndicator(color: AppColors.appBar));
//     }
//     if (_statsErrorMessage != null) {
//       return Center(
//         child: Padding(
//           // Added padding for the error message section
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.error_outline, color: AppColors.errorColor, size: 48),
//               const SizedBox(height: 16),
//               Text(_statsErrorMessage!,
//                   textAlign: TextAlign.center,
//                   style: AppStyles.bodyText1
//                       .copyWith(color: AppColors.errorColor)),
//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.refresh),
//                 label: const Text("Retry"),
//                 onPressed: _fetchDashboardStats,
//                 style:
//                     ElevatedButton.styleFrom(backgroundColor: AppColors.appBar),
//               )
//             ],
//           ),
//         ),
//       );
//     }

//     int crossAxisCount = 2;
//     double screenWidth = MediaQuery.of(context).size.width;
//     if (screenWidth > 1200)
//       crossAxisCount = 4;
//     else if (screenWidth > 800) crossAxisCount = 3;

//     double cardHeight = 140; // Desired card height
//     double childAspectRatio = (screenWidth / crossAxisCount) / cardHeight;
//     if (screenWidth < 600 && crossAxisCount == 2) {
//       childAspectRatio = (screenWidth / crossAxisCount) / 130;
//     }

//     List<Widget> statCards = [
//       AdminStatCard(
//         iconData: Icons.event_note_outlined,
//         label: 'Pending Reservations',
//         value: _pendingReservationsCount.toString(),
//         iconColor: AppColors.statusPending,
//         onTap: () {
//           // TODO: Implement navigation to filtered reservations list
//           // Example: Provider.of<AdminNavigationProvider>(context, listen: false).navigateToReservations(status: 'pendingApproval');
//           print("Tapped Pending Reservations");
//         },
//       ),
//       AdminStatCard(
//         iconData: Icons.event_seat_outlined, // Changed icon for spaces
//         label: 'Occupied Spaces',
//         value: _occupiedSpacesCount.toString(),
//         iconColor: AppColors.statusUsed ??
//             AppColors
//                 .statusCompleted, // Provide a fallback if statusUsed is not in AppColors
//         onTap: () {
//           // TODO: Implement navigation to filtered spaces list with status 'used'
//           print("Tapped Occupied Spaces");
//         },
//       ),
//       AdminStatCard(
//         iconData: Icons.report_problem_outlined,
//         label: 'Open Reports',
//         value: _openReportsCount.toString(),
//         iconColor: AppColors.errorColor, // Or a specific 'open report' color
//         onTap: () {
//           // TODO: Implement navigation to filtered reports list with status 'open' or 'newReport'
//           print("Tapped Open Reports");
//         },
//       ),
//       if (widget.userProfile.role == 'system_super_admin')
//         AdminStatCard(
//           iconData: Icons.people_alt_outlined,
//           label: 'Total Users',
//           value: _totalUsersCount.toString(),
//           iconColor: AppColors.primaryText,
//           onTap: () {
//             // TODO: Implement navigation to user management screen
//             print("Tapped Total Users");
//           },
//         ),
//     ];

//     // Ensure the number of items matches the grid's expectation or use GridView.builder
//     return GridView.count(
//       crossAxisCount: crossAxisCount,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       childAspectRatio: childAspectRatio,
//       children: statCards,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     String welcomeMessage =
//         'Welcome, ${widget.userProfile.fullName ?? widget.userProfile.email ?? 'Admin'}!';
//     String roleDescription = _getRoleDescription(widget.userProfile.role);
//     bool isSuperAdmin = widget.userProfile.role == 'system_super_admin';
//     String cemeteryFocusTitle = "Cemetery Management Focus";
//     Widget cemeteryFocusContent;

//     if (isSuperAdmin) {
//       if (widget.cemeteryId != null && widget.cemeteryName != null) {
//         cemeteryFocusContent = Text(
//           'Scope: Managing ${widget.cemeteryName}',
//           style: AppStyles.bodyText1.copyWith(color: AppColors.primaryText),
//         );
//       } else {
//         cemeteryFocusContent = Text(
//           'Scope: All Cemeteries (System Wide)',
//           style: AppStyles.bodyText1.copyWith(
//               fontStyle: FontStyle.italic, color: AppColors.secondaryText),
//         );
//       }
//     } else {
//       // Cemetery Manager
//       cemeteryFocusContent = Text(
//         'Currently Managing: ${widget.cemeteryName ?? 'N/A (Loading...)'}', // Added loading state indication
//         style: AppStyles.bodyText1.copyWith(color: AppColors.primaryText),
//       );
//     }

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: RefreshIndicator(
//         onRefresh: _fetchDashboardStats,
//         color: AppColors.appBar,
//         child: SingleChildScrollView(
//           physics:
//               const AlwaysScrollableScrollPhysics(), // Ensures RefreshIndicator works even if content is small
//           padding: AppStyles.pagePadding,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Dashboard Overview',
//                 style: AppStyles.titleStyle.copyWith(
//                   fontSize: 26,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primaryText,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               AdminInfoCard(
//                 iconData: Icons.admin_panel_settings_outlined,
//                 title: 'Admin Profile',
//                 children: [
//                   Text(welcomeMessage,
//                       style: AppStyles.bodyText1.copyWith(
//                           fontWeight: FontWeight.w500,
//                           color: AppColors.primaryText)),
//                   const SizedBox(height: 6),
//                   Text('Role: $roleDescription',
//                       style: AppStyles.bodyText2
//                           .copyWith(color: AppColors.secondaryText)),
//                 ],
//               ),
//               // Show cemetery focus card only if relevant
//               if (isSuperAdmin ||
//                   (widget.userProfile.role == 'cemetery_manager' &&
//                       widget.cemeteryName != null))
//                 Padding(
//                   // Added padding for better spacing if it appears
//                   padding: const EdgeInsets.only(top: 16.0),
//                   child: AdminInfoCard(
//                     iconData: Icons.account_balance_outlined,
//                     title: cemeteryFocusTitle,
//                     children: [cemeteryFocusContent],
//                   ),
//                 ),
//               const SizedBox(height: 28),
//               Text(
//                 'Quick Statistics',
//                 style: AppStyles.titleStyle.copyWith(
//                     fontSize: 22,
//                     color: AppColors.primaryText,
//                     fontWeight: FontWeight.w600),

//               const SizedBox(height: 16),
//               _buildStatsSection(),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
