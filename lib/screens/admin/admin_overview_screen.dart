// lib/screens/admin/admin_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/admin_payment_report_model.dart';
import '../../models/report_model.dart';
import '../../models/reservation_model.dart';
import '../../models/space_model.dart';
import '../../models/user_profile_model.dart';
import 'widgets/admin_info_card.dart';
import 'widgets/admin_stat_card.dart';

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
  int _pendingReservationsCount = 0;
  int _occupiedSpacesCount = 0;
  int _openReportsCount = 0;
  bool _isLoadingStats = true;
  String? _statsErrorMessage;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _fetchDashboardStats);
  }

  @override
  void didUpdateWidget(covariant AdminOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cemeteryId != oldWidget.cemeteryId) {
      _fetchDashboardStats();
    }
  }

  Future<void> _fetchDashboardStats() async {
    if (!mounted) return;

    if (widget.cemeteryId == null) {
      setState(() {
        _isLoadingStats = false;
        _statsErrorMessage = "No cemetery assigned to fetch statistics.";
        _openReportsCount = 0;
        _pendingReservationsCount = 0;
        _occupiedSpacesCount = 0;
      });
      return;
    }

    setState(() {
      _isLoadingStats = true;
      _statsErrorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final cemeteryFilter = widget.cemeteryId!;

      // ✅ API FIX: Using the correct syntax for count queries and filters for your Supabase version.
      final futures = <Future<PostgrestResponse>>[
        client
            .from('reservations')
            .select('id')
            .eq('cemetery_id', cemeteryFilter)
            .eq('status', ReservationStatus.pendingApproval.toJson())
            .count(CountOption.exact), // .count() at the end
        client
            .from('cemetery_spaces')
            .select('id')
            .eq('cemetery_id', cemeteryFilter)
            .eq('status', SpaceStatus.used.toJson())
            .count(CountOption.exact), // .count() at the end
        client
            .from('reports')
            .select('id')
            .eq('cemetery_id', cemeteryFilter)
            .inFilter('status', [
          // .inFilter() instead of .in_()
          ReportStatus.submitted.toJson(),
          ReportStatus.assigned.toJson()
        ]).count(CountOption.exact), // .count() at the end
      ];

      final responses = await Future.wait(futures);

      if (!mounted) return;

      // ✅ API FIX: Removed the incorrect '.error' check. try/catch handles this version's errors.
      setState(() {
        _pendingReservationsCount = responses[0].count ?? 0;
        _occupiedSpacesCount = responses[1].count ?? 0;
        _openReportsCount = responses[2].count ?? 0;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error fetching dashboard stats: $e");
      setState(() {
        _statsErrorMessage =
            "Failed to load statistics. Check DB policies or column names.";
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _generateAndSharePdf(AdminPaymentReport report) async {
    final doc = pw.Document();

    pw.Widget buildHeader(String text) {
      return pw.Container(
        alignment: pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.all(5),
        child:
            pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Payment Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Cemetery: ${report.cemeteryName}'),
              pw.Text('Period: ${report.formattedDateRange}'),
              pw.Divider(height: 20, thickness: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text('Total Revenue',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(report.formattedTotalRevenue,
                        style: const pw.TextStyle(fontSize: 18)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Total Transactions',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(report.totalTransactions.toString(),
                        style: const pw.TextStyle(fontSize: 18)),
                  ]),
                ],
              ),
              pw.Divider(height: 20, thickness: 2),
              pw.Text('Transaction Details',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(children: [
                    buildHeader('Date'),
                    buildHeader('Customer Name'),
                    buildHeader('Amount'),
                  ]),
                  ...report.payments
                      .map((p) => pw.TableRow(children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(p.formattedDate)),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(p.customerName)),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(p.formattedAmount)),
                          ]))
                      .toList(),
                ],
              ),
            ],
          ),
        ],
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                  'Report generated on: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}'),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await doc.save(),
        filename:
            'Payment_Report_${report.startDate.toIso8601String().substring(0, 10)}.pdf');
  }

  Future<void> _showGenerateReportDialog() async {
    // This check is important before showing a dialog
    if (!mounted) return;

    DateTime? startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime? endDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Generate Payment Report'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select a date range for the report.',
                      style: AppStyles.bodyText2),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat.yMMMd().format(startDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: startDate!,
                          firstDate: DateTime(2020),
                          lastDate: endDate!);
                      if (pickedDate != null) {
                        setDialogState(() => startDate = pickedDate);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(DateFormat.yMMMd().format(endDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: endDate!,
                          firstDate: startDate!,
                          lastDate: DateTime.now());
                      if (pickedDate != null) {
                        setDialogState(() => endDate = pickedDate);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.secondaryText))),
                ElevatedButton(
                  onPressed: () {
                    // We don't need a mounted check here because this is synchronous.
                    Navigator.of(context).pop();
                    _fetchAndDisplayPaymentReport(startDate!, endDate!);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground),
                  child: const Text('Generate',
                      style: TextStyle(color: AppColors.buttonText)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchAndDisplayPaymentReport(
      DateTime startDate, DateTime endDate) async {
    // This check is important before showing a dialog
    if (!mounted) return;

    if (widget.cemeteryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot generate report without a selected cemetery.'),
          backgroundColor: AppColors.errorColor));
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.appBar)));
    try {
      final client = Supabase.instance.client;
      final endOfDay =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      // ✅ FINAL FIX: Call the RPC function 'get_payment_report_for_manager'.
      // This function on the database must perform the join to auth.users
      // and return the user's full name aliased as 'user_full_name'.
      final responseData = await client.rpc(
        'get_payment_report_for_manager',
        params: {
          'p_cemetery_id': widget.cemeteryId!,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endOfDay.toIso8601String(),
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop(); // Pop the loading dialog

      // AdminPaymentReport.fromResponse now expects 'responseData' to be a List of maps,
      // where each map contains 'final_total_cost', 'created_at', and 'user_full_name'
      final AdminPaymentReport report = AdminPaymentReport.fromResponse(
        responseData: responseData as List<dynamic>, // Cast RPC result
        startDate: startDate,
        endDate: endDate,
        cemeteryName: widget.cemeteryName ?? 'N/A',
      );

      if (!mounted) return;

      // The rest of the dialog logic is correct and remains the same.
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Report'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.formattedDateRange, style: AppStyles.bodyText2),
                const Divider(height: 20),
                Text('Total Revenue: ${report.formattedTotalRevenue}',
                    style: AppStyles.titleStyle.copyWith(fontSize: 18)),
                Text('${report.totalTransactions} successful payments',
                    style: AppStyles.bodyText2),
                const SizedBox(height: 16),
                Expanded(
                  child: report.payments.isEmpty
                      ? const Center(
                          child: Text('No payments found in this period.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: report.payments.length,
                          itemBuilder: (context, index) {
                            final paymentDetail = report.payments[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(paymentDetail.formattedAmount),
                              subtitle: Text(
                                  'By: ${paymentDetail.customerName} on ${paymentDetail.formattedDate}'),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close',
                    style: TextStyle(color: AppColors.secondaryText))),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.buttonText),
              label: const Text('Download PDF',
                  style: TextStyle(color: AppColors.buttonText)),
              onPressed: () => _generateAndSharePdf(report),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Pop the loading dialog
      debugPrint("Error fetching payment report via RPC: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('An error occurred. The database function may have failed.'),
        backgroundColor: AppColors.errorColor,
      ));
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
                      .copyWith(color: AppColors.secondaryText)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                onPressed: _fetchDashboardStats,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appBar,
                    foregroundColor: Colors.white),
              )
            ],
          ),
        ),
      );
    }
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      childAspectRatio: 1.3,
      children: [
        AdminStatCard(
            iconData: Icons.event_note_outlined,
            label: 'Pending Reservations',
            value: _pendingReservationsCount.toString(),
            iconColor: AppColors.statusPending,
            onTap: () => widget.onNavigateToTab(1)),
        AdminStatCard(
            iconData: Icons.bookmark_added_outlined,
            label: 'Occupied Spaces',
            value: _occupiedSpacesCount.toString(),
            iconColor: AppColors.statusUsed,
            onTap: () => widget.onNavigateToTab(2)),
        AdminStatCard(
            iconData: Icons.report_problem_outlined,
            label: 'Open Reports',
            value: _openReportsCount.toString(),
            iconColor: AppColors.errorColor,
            onTap: () => widget.onNavigateToTab(3)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String welcomeMessage =
        'Welcome, ${widget.userProfile.fullName ?? widget.userProfile.email ?? 'Manager'}!';
    String roleDescription = _getRoleDescription(widget.userProfile.role);

    Widget cemeteryFocusContent = widget.cemeteryName != null
        ? Text('Managing: ${widget.cemeteryName}',
            style: AppStyles.bodyText2.copyWith(color: AppColors.secondaryText))
        : Text('No cemetery selected',
            style: AppStyles.bodyText2.copyWith(color: AppColors.errorColor));

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
              Text('Cemetery Statistics',
                  style: AppStyles.titleStyle.copyWith(
                      fontSize: 22,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _buildStatsSection(),
              const SizedBox(height: 28),
              Text('Reporting Tools',
                  style: AppStyles.titleStyle.copyWith(
                      fontSize: 22,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              AdminInfoCard(
                iconData: Icons.receipt_long_outlined,
                title: 'Financial Reports',
                children: [
                  Text('Generate a summary of payments for a specific period.',
                      style: AppStyles.bodyText2),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.summarize_outlined,
                          color: AppColors.buttonText),
                      label: const Text('Generate Report',
                          style: TextStyle(color: AppColors.buttonText)),
                      onPressed: _showGenerateReportDialog,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
