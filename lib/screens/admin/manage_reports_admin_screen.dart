// lib/screens/admin/manage_reports_admin_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/admin_report_model.dart';
import '../../constants/app_styles.dart';
import '../../constants/app_colors.dart';

class ManageReportsAdminScreen extends StatefulWidget {
  // This screen now assumes it's always for a manager.
  final String? cemeteryId;
  final String? cemeteryName;

  const ManageReportsAdminScreen({
    super.key,
    this.cemeteryId,
    this.cemeteryName,
  });

  @override
  State<ManageReportsAdminScreen> createState() =>
      _ManageReportsAdminScreenState();
}

class _ManageReportsAdminScreenState extends State<ManageReportsAdminScreen> {
  List<AdminReportModel> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _reportsSubscription;

  ReportStatus? _selectedStatusFilter;
  ReportType? _selectedTypeFilter;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // This now correctly handles the case where no cemetery is selected.
    _handleCemeteryChange();
  }

  @override
  void didUpdateWidget(covariant ManageReportsAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cemeteryId != oldWidget.cemeteryId) {
      _handleCemeteryChange();
    }
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    _reportsSubscription = null;
    super.dispose();
  }

  void _handleCemeteryChange() {
    _reportsSubscription?.cancel();
    if (widget.cemeteryId != null) {
      _fetchReports();
    } else {
      // If no cemeteryId is provided, we show an instructional message.
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _reports = [];
      });
    }
  }

  Future<void> _fetchReports() async {
    // If for some reason this is called without a cemeteryId, do nothing.
    if (!mounted || widget.cemeteryId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // UPDATED QUERY: Joins related tables to fetch all model data.
      var query = _supabase.from('reports').select('''
          id, 
          created_at, 
          report_type, 
          description, 
          status, 
          reported_by_user_id,
          cemetery_id, 
          cemetery_space_id, 
          admin_notes, 
          resolved_at,
          updated_at,
          profiles ( full_name, email ),
          cemeteries ( name ),
          cemetery_spaces ( space_identifier )
        ''');

      // This part remains the same. It correctly filters by cemetery.
      query = query.eq('cemetery_id', widget.cemeteryId!);

      if (_selectedStatusFilter != null) {
        query = query.eq('status', _selectedStatusFilter!.toJson());
      }
      if (_selectedTypeFilter != null) {
        query = query.eq('report_type', _selectedTypeFilter!.toJson());
      }

      final response = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _reports =
              response.map((data) => AdminReportModel.fromJson(data)).toList();
          _isLoading = false;
        });
        _subscribeToReportChanges();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error fetching reports. Check RLS policies.";
          _isLoading = false;
          _reports = [];
        });
      }
    }
  }

  void _subscribeToReportChanges() {
    if (widget.cemeteryId == null) return;
    _reportsSubscription?.cancel();
    _reportsSubscription =
        _supabase.from('reports').stream(primaryKey: ['id']).listen((data) {
      if (mounted) {
        _fetchReports();
      }
    }, onError: (e) => print("Reports stream error: $e"));
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.bug:
        return Icons.bug_report_outlined;
      case ReportType.contentIssue:
        return Icons.description_outlined;
      case ReportType.userMisconduct:
        return Icons.gavel_outlined;
      case ReportType.spaceIncorrect:
        return Icons.wrong_location_outlined;
      case ReportType.paymentIssue:
        return Icons.payment_outlined;
      case ReportType.suggestion:
        return Icons.lightbulb_outline;
      case ReportType.other:
        return Icons.help_outline;
      default:
        return Icons.report_problem_outlined;
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.newReport:
        return AppColors.statusPending;
      case ReportStatus.underReview:
        return Colors.blueAccent;
      case ReportStatus.resolved:
        return AppColors.statusApproved;
      case ReportStatus.closedWontFix:
        return AppColors.secondaryText.withOpacity(0.7);
      case ReportStatus.escalated:
        return Colors.purpleAccent;
      default:
        return AppColors.secondaryText;
    }
  }

  Widget _detailDialogRow(String label, String value) {
    // This helper now checks for empty values to avoid showing empty rows.
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: AppStyles.bodyText2
              .copyWith(fontSize: 14, color: AppColors.primaryText),
          children: [
            TextSpan(
                text: '$label ',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryText)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _showReportDetails(AdminReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Report: ${report.type.displayName} (#${report.id.substring(0, 5)}...)'),
        shape: RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              _detailDialogRow('Description:', report.description),
              _detailDialogRow('Status:', report.status.displayName),
              _detailDialogRow('Reported:',
                  report.createdAt.toLocal().toString().substring(0, 16)),
              // Now we can display the joined data!
              _detailDialogRow('User:', report.reportedByUserFullName ?? 'N/A'),
              _detailDialogRow('Cemetery:', report.cemeteryName ?? 'N/A'),
              _detailDialogRow(
                  'Space:', report.spaceIdentifier ?? 'Not Specified'),
              if (report.adminNotes != null && report.adminNotes!.isNotEmpty)
                _detailDialogRow('Admin Notes:', report.adminNotes!),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          if (report.status == ReportStatus.newReport ||
              report.status == ReportStatus.escalated)
            TextButton(
              child: const Text('Mark as Under Review'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateReportStatus(report, ReportStatus.underReview);
              },
            ),
          if (report.status == ReportStatus.underReview)
            TextButton(
              child: const Text('Mark as Resolved'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateReportStatus(report, ReportStatus.resolved);
              },
            ),
          TextButton(
            child: const Text('Close',
                style: TextStyle(color: AppColors.secondaryText)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReportStatus(
      AdminReportModel report, ReportStatus newStatus) async {
    try {
      final updatePayload = {
        'status': newStatus.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newStatus == ReportStatus.resolved) {
        updatePayload['resolved_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('reports').update(updatePayload).eq('id', report.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to ${newStatus.displayName}.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating report status: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppStyles.pagePadding.left / 2,
        vertical: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Text("Filter by Status:",
                style:
                    AppStyles.bodyText2.copyWith(fontWeight: FontWeight.w500)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: ReportStatus.values
                  .where((s) => s != ReportStatus.unknown)
                  .map((status) {
                bool isSelected = _selectedStatusFilter == status;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(status.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatusFilter = selected ? status : null;
                        _fetchReports();
                      });
                    },
                    selectedColor: AppColors.activeTab.withOpacity(0.2),
                    backgroundColor: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppStyles.buttonBorderRadius.topLeft.x),
                        side: BorderSide(
                            color: isSelected
                                ? AppColors.activeTab
                                : Colors.grey.shade300)),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.activeTab
                          : AppColors.primaryText,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.cemeteryId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined,
                  size: 60, color: AppColors.secondaryText),
              const SizedBox(height: 16),
              Text('No Cemetery Assigned', style: AppStyles.titleStyle),
              const SizedBox(height: 8),
              Text(
                'This account is not assigned to manage a specific cemetery.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyText2,
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.activeTab));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyText1
                      .copyWith(color: AppColors.errorColor)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                onPressed: _fetchReports,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appBar,
                    foregroundColor: AppColors.buttonText),
              )
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 60, color: AppColors.secondaryText.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _selectedStatusFilter != null || _selectedTypeFilter != null
                  ? "No reports match your filters."
                  : "No reports found for ${widget.cemeteryName ?? 'this cemetery'}.",
              textAlign: TextAlign.center,
              style: AppStyles.titleStyle
                  .copyWith(color: AppColors.secondaryText, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReports,
      color: AppColors.appBar,
      child: ListView.builder(
        padding: AppStyles.pagePadding.copyWith(top: 8, bottom: 16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    AppStyles.cardBorderRadius.topLeft.x - 2)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    _getStatusColor(report.status).withOpacity(0.15),
                child: Icon(_getReportIcon(report.type),
                    color: _getStatusColor(report.status), size: 24),
              ),
              title: Text(
                report.type.displayName,
                style: AppStyles.cardTitleStyle
                    .copyWith(fontSize: 15.5, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                    child: Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodyText2.copyWith(fontSize: 13.5),
                    ),
                  ),
                  Text(
                    'Status: ${report.status.displayName}',
                    style: AppStyles.caption.copyWith(
                        fontSize: 12,
                        color: _getStatusColor(report.status),
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.secondaryText),
              onTap: () => _showReportDetails(report),
              isThreeLine: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterChips(),
        const Divider(
            height: 1, thickness: 1, color: AppColors.progressBarTrack),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }
}
