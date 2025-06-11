// lib/screens/admin/manage_reports_admin_screen.dart
import 'package:flutter/material.dart';
import '../../constants/app_styles.dart';
import '../../constants/app_colors.dart';
// TODO: Import your Supabase client and any models if you start fetching data

class ManageReportsAdminScreen extends StatefulWidget {
  final String?
  cemeteryId; // Optional: If reports are filtered by cemetery for managers
  final String? cemeteryName;
  final bool isSuperAdmin;

  const ManageReportsAdminScreen({
    super.key,
    this.cemeteryId,
    this.cemeteryName,
    required this.isSuperAdmin,
  });

  @override
  State<ManageReportsAdminScreen> createState() =>
      _ManageReportsAdminScreenState();
}

class _ManageReportsAdminScreenState extends State<ManageReportsAdminScreen> {
  // TODO: Add state variables for reports list, loading, filters, etc.
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = []; // Placeholder for report data

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    // TODO: Implement actual Supabase call to fetch reports
    // Consider filtering by widget.cemeteryId if !widget.isSuperAdmin and cemeteryId is relevant
    // Example (very basic):
    // try {
    //   final supabase = Supabase.instance.client;
    //   var query = supabase.from('user_reports').select().order('created_at', ascending: false);
    //   if (!widget.isSuperAdmin && widget.cemeteryId != null) {
    //     query = query.eq('cemetery_id', widget.cemeteryId!);
    //   }
    //   final response = await query;
    //   if (mounted) {
    //     setState(() {
    //       _reports = List<Map<String, dynamic>>.from(response as List);
    //       _isLoading = false;
    //     });
    //   }
    // } catch (e) {
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Error fetching reports: $e'), backgroundColor: AppColors.errorColor),
    //     );
    //     setState(() => _isLoading = false);
    //   }
    // }
    await Future.delayed(const Duration(seconds: 1)); // Simulate network call
    if (mounted) {
      setState(() {
        // Add some dummy data for now
        _reports = [
          {
            'id': '1',
            'description': 'User reported an issue with spot A1.',
            'report_type': 'Spot Incorrect',
            'status': 'new',
            'created_at': DateTime.now().toIso8601String(),
            'reported_by_user_id': 'user_abc',
          },
          {
            'id': '2',
            'description': 'Payment failed for reservation XYZ.',
            'report_type': 'Payment Issue',
            'status': 'under_review',
            'created_at':
                DateTime.now()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
            'reported_by_user_id': 'user_def',
          },
        ];
        _isLoading = false;
      });
    }
  }

  Widget _buildReportListItem(Map<String, dynamic> report) {
    // Basic list item, can be expanded into a more detailed card
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          _getReportIcon(report['report_type'] as String?),
          color: _getStatusColor(report['status'] as String?),
        ),
        title: Text(
          report['description'] as String? ?? 'No description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Type: ${report['report_type'] ?? 'N/A'} - Status: ${report['status'] ?? 'N/A'}\nReported: ${report['created_at'] != null ? (DateTime.tryParse(report['created_at'])?.toLocal().toString().substring(0, 16) ?? 'Unknown time') : 'Unknown time'}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Navigate to a report detail screen or show a dialog to manage the report
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on report: ${report['id']}')),
          );
        },
      ),
    );
  }

  IconData _getReportIcon(String? reportType) {
    switch (reportType) {
      case 'Bug':
        return Icons.bug_report_outlined;
      case 'Content Issue':
        return Icons.description_outlined;
      case 'User Misconduct':
        return Icons.gavel_outlined;
      case 'Spot Incorrect':
        return Icons.wrong_location_outlined;
      case 'Payment Issue':
        return Icons.payment_outlined;
      default:
        return Icons.report_problem_outlined;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'new':
        return AppColors.statusPending; // Orange
      case 'under_review':
        return Colors.blueAccent;
      case 'resolved':
        return AppColors.statusApproved; // Green
      case 'closed_wont_fix':
        return AppColors.secondaryText; // Grey
      default:
        return AppColors.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = "Manage Reports";
    if (!widget.isSuperAdmin && widget.cemeteryName != null) {
      // For cemetery manager, title is already handled by AdminDashboardScreen's AppBar
      // This screen doesn't need its own AppBar if it's part of IndexedStack
    } else if (widget.isSuperAdmin) {
      // Super admin might see this without specific cemetery context in tab title
    }

    return Scaffold(
      // Keep Scaffold for background color and potential future local AppBar actions
      backgroundColor: AppColors.background,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.activeTab),
              )
              : _reports.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: AppColors.secondaryText.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No reports found.",
                      style: AppStyles.titleStyle.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (widget.cemeteryId != null && !widget.isSuperAdmin)
                      Text(
                        "For ${widget.cemeteryName ?? 'this cemetery'}.",
                        style: AppStyles.bodyText2.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              )
              : ListView.builder(
                padding: AppStyles.pagePadding,
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  return _buildReportListItem(_reports[index]);
                },
              ),
      // TODO: Add FloatingActionButton for filtering or other actions if needed
    );
  }
}
