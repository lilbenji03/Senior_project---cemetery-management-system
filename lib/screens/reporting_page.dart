// lib/screens/reporting_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cemetery_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/report_model.dart';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();
  ReportType? _selectedReportType;
  final TextEditingController _detailsController = TextEditingController();
  // --- REMOVED: _spaceIdentifierController is no longer needed ---

  bool _isSubmitting = false;

  // State for cemetery selection
  List<Cemetery> _cemeteries = [];
  Cemetery? _selectedCemetery;
  bool _isLoadingCemeteries = true;

  final List<ReportType> _userReportTypes =
      ReportType.values.where((type) => type != ReportType.unknown).toList();

  @override
  void initState() {
    super.initState();
    _fetchCemeteries();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    // --- REMOVED: No need to dispose _spaceIdentifierController ---
    super.dispose();
  }

  // Fetches all cemeteries for the mandatory dropdown
  Future<void> _fetchCemeteries() async {
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('cemeteries')
          .select('id, name')
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _cemeteries = data.map((e) => Cemetery.fromJson(e)).toList();
          _isLoadingCemeteries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCemeteries = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not load cemeteries.'),
              backgroundColor: AppColors.errorColor),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      // The validator already ensures _selectedCemetery is not null.
      final newReport = Report(
        id: '',
        createdAt: DateTime.now(),
        userId: Supabase.instance.client.auth.currentUser?.id,
        cemeteryId: _selectedCemetery!.id,
        // --- REMOVED: spaceIdentifier is no longer part of the report from this page ---
        type: _selectedReportType!,
        description: _detailsController.text.trim(),
        status: ReportStatus.submitted,
      );

      await Supabase.instance.client
          .from('reports')
          .insert(newReport.toJsonForCreate());

      if (mounted) {
        // Show success dialog and then pop the screen
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: AppStyles.cardBorderRadius),
              title: Row(children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.statusApproved, size: 28),
                const SizedBox(width: 12),
                Text('Report Submitted', style: AppStyles.cardTitleStyle),
              ]),
              content: const Text(
                  'Thank you for your feedback. Our team will review your report shortly.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK',
                      style: TextStyle(
                          color: AppColors.appBar,
                          fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e is PostgrestException
            ? 'Database Error: ${e.message}'
            : 'An unexpected error occurred. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _customInputDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppStyles.bodyText2,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.secondaryText.withOpacity(0.7))
          : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide:
              BorderSide(color: AppColors.secondaryText.withOpacity(0.2))),
      enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide:
              BorderSide(color: AppColors.secondaryText.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.appBar, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide:
              const BorderSide(color: AppColors.errorColor, width: 1.0)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppStyles.buttonBorderRadius,
          borderSide:
              const BorderSide(color: AppColors.errorColor, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppStyles.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Report an Issue or Suggestion',
                  style: AppStyles.titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Please select the cemetery and provide details about your concern.',
                  style: AppStyles.bodyText2,
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 32),

                // --- MANDATORY Cemetery Dropdown ---
                DropdownButtonFormField<Cemetery>(
                  decoration: _customInputDecoration('Select Cemetery *',
                      prefixIcon: Icons.location_city_rounded),
                  value: _selectedCemetery,
                  hint: _isLoadingCemeteries
                      ? const Text('Loading cemeteries...')
                      : const Text('Choose a cemetery'),
                  items: _cemeteries
                      .map<DropdownMenuItem<Cemetery>>((Cemetery cemetery) {
                    return DropdownMenuItem<Cemetery>(
                        value: cemetery,
                        child: Text(cemetery.name, style: AppStyles.bodyText1));
                  }).toList(),
                  onChanged: (Cemetery? newValue) {
                    setState(() => _selectedCemetery = newValue);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a cemetery' : null,
                ),
                const SizedBox(height: 16.0),

                // --- REMOVED: The optional Space Identifier TextFormField is gone ---

                // --- MANDATORY Report Type Dropdown ---
                DropdownButtonFormField<ReportType>(
                  decoration: _customInputDecoration('Type of Report *',
                      prefixIcon: Icons.category_outlined),
                  value: _selectedReportType,
                  hint: const Text('Select a category...'),
                  items: _userReportTypes
                      .map<DropdownMenuItem<ReportType>>((ReportType type) {
                    return DropdownMenuItem<ReportType>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon,
                                size: 20, color: AppColors.secondaryText),
                            const SizedBox(width: 12),
                            Text(type.displayName, style: AppStyles.bodyText1),
                          ],
                        ));
                  }).toList(),
                  onChanged: (ReportType? newValue) {
                    setState(() => _selectedReportType = newValue);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a report type' : null,
                ),
                const SizedBox(height: 16.0),

                Expanded(
                  child: TextFormField(
                    controller: _detailsController,
                    decoration: _customInputDecoration('Detailed Description *')
                        .copyWith(
                      hintText: 'Please provide as much detail as possible...',
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    validator: (value) =>
                        (value == null || value.trim().length < 20)
                            ? 'Please provide at least 20 characters.'
                            : null,
                  ),
                ),
                const SizedBox(height: 24.0),

                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label:
                      Text(_isSubmitting ? 'Submitting...' : 'Submit Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: AppColors.buttonText,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppStyles.buttonBorderRadius),
                    textStyle: AppStyles.buttonTextStyle,
                  ),
                  onPressed: _isSubmitting ? null : _submitReport,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
