// lib/screens/admin/manage_reports_admin_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../constants/app_styles.dart';
import '../../constants/app_colors.dart';

class ManageReportsAdminScreen extends StatefulWidget {
  final String? cemeteryId;
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
  List<Report> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _reportsSubscription;

  ReportStatus? _selectedStatusFilter;
  ReportType? _selectedTypeFilter;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _subscribeToReportChanges();
  }

  @override
  void didUpdateWidget(covariant ManageReportsAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cemeteryId != oldWidget.cemeteryId) {
      _reportsSubscription?.cancel(); // Cancel old subscription
      _fetchReports();
      _subscribeToReportChanges(); // Re-subscribe with new context
    }
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var query = _supabase.from('reports').select('''
            id, created_at, report_type, description, status, reported_by_user_id,
            cemetery_id, cemetery_space_id, admin_notes, resolved_at,
            profiles ( full_name, email ),
            cemeteries ( name ),
            cemetery_spaces ( space_identifier )
          ''');

      if (!widget.isSuperAdmin && widget.cemeteryId != null) {
        query = query.eq('cemetery_id', widget.cemeteryId!);
      }
      if (_selectedStatusFilter != null) {
        query = query.eq('status', _selectedStatusFilter!.toJson());
      }
      if (_selectedTypeFilter != null) {
        query = query.eq('report_type', _selectedTypeFilter!.toJson());
      }

      final response = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _reports = response.map((data) => Report.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e, s) {
      print("Error fetching reports: $e");
      print("Stacktrace for fetching reports: $s");
      if (mounted) {
        setState(() {
          _errorMessage = "Error fetching reports: ${e.toString()}";
          _isLoading = false;
          _reports = []; // Clear reports on error
        });
      }
    }
  }

  void _subscribeToReportChanges() {
    _reportsSubscription?.cancel();

    // Get the PostgrestQueryBuilder first
    PostgrestQueryBuilder queryBuilder = _supabase.from('reports');

    // Apply filters to the queryBuilder if they are meant for the stream
    // This is where the confusion often lies with streams.
    // For Supabase Realtime v2, the filters in stream() are more direct.
    // Let's try constructing the stream with filters directly.

    // The .stream() method itself on PostgrestQueryBuilder returns PostgrestStreamBuilder.
    // Filters are typically applied *before* calling .stream() if they are part of the
    // initial data snapshot query, or directly on the stream builder if the API allows.

    // Correct approach for filtering streams:
    // You build the query for the *initial fetch* and then apply basic filters to the stream.
    // The Postgrest Stream API allows for some filters.

    // Let's try a more direct approach for stream filtering as per supabase-dart docs:
    // .stream() is called on the PostgrestQueryBuilder.
    // Filters for the stream are applied to the object returned by .stream() which is PostgrestStreamBuilder.

    SupabaseStreamFilterBuilder? streamFilterBuilder = _supabase
        .from('reports')
        .stream(primaryKey: [
      'id'
    ]); // This is a PostgrestStreamBuilder, which is a type of PostgrestFilterBuilder

    if (!widget.isSuperAdmin && widget.cemeteryId != null) {
      streamFilterBuilder = streamFilterBuilder.eq(
          'cemetery_id', widget.cemeteryId!) as SupabaseStreamFilterBuilder?;
    }
    // Note: Adding _selectedStatusFilter or _selectedTypeFilter here might make the stream too specific
    // and you might miss updates if an item changes *into* that status.
    // It's often better to have a broader stream and filter client-side or refetch.
    // For this example, we'll keep the cemeteryId filter on the stream.

    _reportsSubscription = streamFilterBuilder!
        // .order('created_at', ascending: false) // Order on stream might not always apply to incoming individual changes
        .listen(
      (List<Map<String, dynamic>> data) {
        print(
            "ManageReportsAdminScreen: Stream received ${data.length} updates. Refetching for consistency with filters.");
        if (mounted) {
          _fetchReports(); // Refetch to apply all current server-side filters
        }
      },
      onError: (error, s) {
        if (mounted) {
          print("Reports stream error: $error");
          print("Stacktrace for stream error: $s");
        }
      },
    );
  }
  // ... (ICON, COLOR, DIALOG, UPDATE, FILTER CHIP methods from previous correct version) ...

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
      case ReportType.unknown:
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
      case ReportStatus.unknown:
      default:
        return AppColors.secondaryText;
    }
  }

  Widget _detailDialogRow(String label, String value) {
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

  void _showReportDetails(Report report) {
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
              if (report.reportedByUserFullName != null)
                _detailDialogRow('By:',
                    '${report.reportedByUserFullName} (${report.reportedByUserEmail ?? 'No email'})')
              else if (report.reportedByUserEmail != null)
                _detailDialogRow('By Email:', report.reportedByUserEmail!),
              if (report.cemeteryName != null)
                _detailDialogRow('Cemetery:', report.cemeteryName!),
              if (report.spaceIdentifier != null)
                _detailDialogRow('Space:', report.spaceIdentifier!),
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
      Report report, ReportStatus newStatus) async {
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
    } catch (e, s) {
      print("Error updating report status: $e");
      print("Stacktrace for report update: $s");
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

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(
              height: 1, thickness: 1, color: AppColors.progressBarTrack),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.activeTab))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
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
                                    foregroundColor: AppColors
                                        .appBarTitle // Assuming appBarTitle is contrast color
                                    ),
                              )
                            ],
                          ),
                        ),
                      )
                    : _reports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 60,
                                    color: AppColors.secondaryText
                                        .withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedStatusFilter != null ||
                                          _selectedTypeFilter != null
                                      ? "No reports match your filters."
                                      : "No reports found.",
                                  textAlign:
                                      TextAlign.center, // Added textAlign
                                  style: AppStyles.titleStyle.copyWith(
                                      color: AppColors.secondaryText,
                                      fontSize: 18),
                                ),
                                if (widget.cemeteryId != null &&
                                    !widget.isSuperAdmin &&
                                    _selectedStatusFilter == null &&
                                    _selectedTypeFilter == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                        "For ${widget.cemeteryName ?? 'this cemetery'}.",
                                        style: AppStyles.bodyText2.copyWith(
                                            color: AppColors.secondaryText)),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchReports,
                            color: AppColors.appBar,
                            child: ListView.builder(
                              padding: AppStyles.pagePadding
                                  .copyWith(top: 8, bottom: 16),
                              itemCount: _reports.length,
                              itemBuilder: (context, index) {
                                final report = _reports[index];
                                return Card(
                                  elevation: 1.5,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5.0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppStyles.cardBorderRadius.topLeft.x -
                                              2)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _getStatusColor(report.status)
                                              .withOpacity(0.15),
                                      child: Icon(_getReportIcon(report.type),
                                          color: _getStatusColor(report.status),
                                          size: 24),
                                    ),
                                    title: Text(
                                      report.type.displayName,
                                      style: AppStyles.cardTitleStyle.copyWith(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 2.0, bottom: 4.0),
                                          child: Text(
                                            report.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppStyles.bodyText2
                                                .copyWith(fontSize: 13.5),
                                          ),
                                        ),
                                        Text(
                                          'Status: ${report.status.displayName}',
                                          style: AppStyles.caption.copyWith(
                                              fontSize: 12,
                                              color: _getStatusColor(
                                                  report.status),
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Reported: ${DateFormat('MMM d, yyyy').format(report.createdAt.toLocal())}',
                                          style: AppStyles.caption
                                              .copyWith(fontSize: 11.5),
                                        ),
                                        if (report.reportedByUserFullName !=
                                            null)
                                          Text(
                                            'By: ${report.reportedByUserFullName}',
                                            style: AppStyles.caption.copyWith(
                                                fontSize: 11.5,
                                                fontStyle: FontStyle.italic),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: AppColors.secondaryText),
                                    onTap: () => _showReportDetails(report),
                                    isThreeLine: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
