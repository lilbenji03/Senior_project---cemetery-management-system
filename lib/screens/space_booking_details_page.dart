// lib/screens/space_booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cemetery_model.dart';
import '../models/space_model.dart';
import '../models/reservation_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class SpaceBookingDetailsPage extends StatefulWidget {
  final Cemetery cemetery;
  final CemeterySpace selectedSpace;

  const SpaceBookingDetailsPage({
    super.key,
    required this.cemetery,
    required this.selectedSpace,
  });

  @override
  State<SpaceBookingDetailsPage> createState() =>
      _SpaceBookingDetailsPageState();
}

class _SpaceBookingDetailsPageState extends State<SpaceBookingDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlotType;
  bool _hasMedicalCertificate = false;
  bool _hasDeceasedId = false;
  bool _hasDeathRegistrationForm = false;
  final TextEditingController _burialPermitNumberController =
      TextEditingController();
  final TextEditingController _deceasedNameController = TextEditingController();
  DateTime? _selectedBurialDate;

  double _estimatedPlotCost = 0.0;
  bool _isSubmitting = false;

  // This hardcoded data should be moved to a configuration service or fetched from the DB
  final double langataPermanentAdultCost = 30500.00;
  final double langataTemporaryAdultCost = 7000.00;
  final double genericPermanentCost = 25000.00;
  final double genericTemporaryCost = 5000.00;

  @override
  void initState() {
    super.initState();
    if (widget.selectedSpace.plotType != null &&
        widget.selectedSpace.plotType!.isNotEmpty &&
        widget.selectedSpace.plotType != 'Generic') {
      // Allow re-selection for generic types
      _selectedPlotType = widget.selectedSpace.plotType;
      _updateEstimatedCost();
    }
  }

  @override
  void dispose() {
    _burialPermitNumberController.dispose();
    _deceasedNameController.dispose();
    super.dispose();
  }

  void _updateEstimatedCost() {
    if (!mounted || _selectedPlotType == null) {
      setState(() => _estimatedPlotCost = 0.0);
      return;
    }
    double cost;
    bool isLangata = widget.cemetery.name.toLowerCase().contains('langata');
    double adultPermanent =
        isLangata ? langataPermanentAdultCost : genericPermanentCost;
    double adultTemporary =
        isLangata ? langataTemporaryAdultCost : genericTemporaryCost;

    switch (_selectedPlotType) {
      case 'Permanent Adult':
        cost = adultPermanent;
        break;
      case 'Temporary Adult':
        cost = adultTemporary;
        break;
      case 'Permanent Child':
        cost = adultPermanent * 0.75; // 75% of adult price
        break;
      case 'Temporary Child':
        cost = adultTemporary * 0.75; // 75% of adult price
        break;
      default:
        cost = genericPermanentCost; // Fallback
    }
    setState(() => _estimatedPlotCost = cost);
  }

  Future<void> _showPlotTypeSelectionDialog() async {
    bool isLangata = widget.cemetery.name.toLowerCase().contains('langata');
    double adultPermanent =
        isLangata ? langataPermanentAdultCost : genericPermanentCost;
    double adultTemporary =
        isLangata ? langataTemporaryAdultCost : genericTemporaryCost;

    Map<String, double> plotTypesWithCosts = {
      'Permanent Adult': adultPermanent,
      'Temporary Adult': adultTemporary,
      'Permanent Child': adultPermanent * 0.75, // 75% of adult price
      'Temporary Child': adultTemporary * 0.75, // 75% of adult price
    };

    String? dialogSelectedPlotType = _selectedPlotType;

    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: AppStyles.cardBorderRadius),
              title: Text(
                  'Select Plot Type for ${widget.selectedSpace.spaceIdentifier}',
                  style: AppStyles.titleStyle.copyWith(fontSize: 18)),
              contentPadding: const EdgeInsets.only(top: 12.0),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  shrinkWrap: true,
                  children: plotTypesWithCosts.entries.map((entry) {
                    return RadioListTile<String>(
                      title: Text(entry.key, style: AppStyles.bodyText1),
                      subtitle: Text(
                        'Approx. KES ${entry.value.toStringAsFixed(2)}\n${_getPlotTypeDescription(entry.key)}',
                        style: AppStyles.caption.copyWith(fontSize: 12.5),
                      ),
                      value: entry.key,
                      groupValue: dialogSelectedPlotType,
                      onChanged: (String? value) =>
                          setDialogState(() => dialogSelectedPlotType = value),
                      activeColor: AppColors.appBar,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                    child: Text('Cancel',
                        style: TextStyle(color: AppColors.secondaryText)),
                    onPressed: () => Navigator.of(dialogContext).pop(null)),
                TextButton(
                  onPressed: dialogSelectedPlotType == null
                      ? null
                      : () => Navigator.of(dialogContext)
                          .pop(dialogSelectedPlotType),
                  child: Text('Confirm',
                      style: TextStyle(
                          color: AppColors.appBar,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedPlotType = result;
        _updateEstimatedCost();
      });
    }
  }

  String _getPlotTypeDescription(String plotType) {
    if (plotType.contains('Permanent'))
      return 'Perpetual use, allows headstones.';
    if (plotType.contains('Temporary'))
      return 'Short-term, may be reused after a period.';
    if (plotType.contains('Child')) return 'Sized for children/infants.';
    return 'Standard plot.';
  }

  Future<void> _selectBurialDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBurialDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.appBar,
              onPrimary: AppColors.buttonText, // White text on app bar color
              onSurface: AppColors.primaryText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.appBar),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBurialDate && mounted) {
      setState(() => _selectedBurialDate = picked);
    }
  }

  Future<void> _requestApprovalAndProceed() async {
    if (_selectedPlotType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a plot type first.')));
      await _showPlotTypeSelectionDialog();
      if (_selectedPlotType == null || !mounted) return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_hasMedicalCertificate ||
        !_hasDeceasedId ||
        !_hasDeathRegistrationForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please confirm all required preliminary documents.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      await Supabase.instance.client.rpc(
        'create_reservation_and_update_space',
        params: {
          'user_id_input': Supabase.instance.client.auth.currentUser!.id,
          'cemetery_id_input': widget.cemetery.id,
          'space_id_input': widget.selectedSpace.id,
          'deceased_name_input': _deceasedNameController.text.trim(),
          'burial_permit_input': _burialPermitNumberController.text.trim(),
          'burial_date_input': _selectedBurialDate?.toIso8601String(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            content: Text(
                'Request for space ${widget.selectedSpace.spaceIdentifier} submitted.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Booking Failed: ${e.message}'),
              backgroundColor: AppColors.errorColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred: ${e.toString()}'),
              backgroundColor: AppColors.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildDocumentCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: AppColors.cardBackground,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: AppStyles.buttonBorderRadius),
      child: CheckboxListTile(
        title: Text(title, style: AppStyles.bodyText1.copyWith(fontSize: 15)),
        subtitle: Text(subtitle, style: AppStyles.caption),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.appBar,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      ),
    );
  }

  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppStyles.bodyText2,
      prefixIcon: Icon(icon, color: AppColors.secondaryText.withOpacity(0.7)),
      filled: true,
      fillColor: AppColors.background.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: AppStyles.buttonBorderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppStyles.buttonBorderRadius,
        borderSide: BorderSide(color: AppColors.secondaryText.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppStyles.buttonBorderRadius,
        borderSide: const BorderSide(color: AppColors.appBar, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Book: ${widget.selectedSpace.spaceIdentifier}',
          style: AppStyles.appBarTitleStyle
              .copyWith(fontSize: 22), // Adjusted font size
        ),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.appBarTitle,
        elevation: AppStyles.elevationLow,
      ),
      body: SingleChildScrollView(
        padding:
            AppStyles.pagePadding.copyWith(bottom: 40.0), // More bottom padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Booking Details for Spot in ${widget.cemetery.name}',
                style: AppStyles.titleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Plot Type Selection Card
              Card(
                elevation: AppStyles.elevationLow,
                color: AppColors.cardBackground,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: AppStyles.cardBorderRadius),
                child: Padding(
                  padding: AppStyles.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plot Type & Cost', style: AppStyles.cardTitleStyle),
                      const Divider(height: 20),
                      _selectedPlotType == null
                          ? Center(
                              child: ElevatedButton.icon(
                              icon: const Icon(Icons.category_outlined),
                              label: const Text('Select Plot Type'),
                              onPressed: _showPlotTypeSelectionDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.appBar,
                                foregroundColor: AppColors.buttonText,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppStyles.buttonBorderRadius),
                              ),
                            ))
                          : ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.category_rounded,
                                  color: AppColors.appBar),
                              title: Text(_selectedPlotType!,
                                  style: AppStyles.bodyText1.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              subtitle: Text(
                                  'Estimated Cost: KES ${_estimatedPlotCost.toStringAsFixed(2)}',
                                  style: AppStyles.bodyText1.copyWith(
                                      color: AppColors.statusApproved,
                                      fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.secondaryText),
                                onPressed: _showPlotTypeSelectionDialog,
                                tooltip: 'Change Plot Type',
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Deceased and Burial Date Section
              Text('Deceased & Burial Information',
                  style: AppStyles.titleStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deceasedNameController,
                decoration: _customInputDecoration(
                    'Full Name of Deceased', Icons.person_outline_rounded),
                style: AppStyles.bodyText1,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Deceased name is required.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _customInputDecoration(
                        'Selected Burial Date (Optional)',
                        Icons.calendar_today_rounded)
                    .copyWith(
                  hintText: _selectedBurialDate == null
                      ? 'Tap to select date'
                      : DateFormat('EEE, MMM dd, yyyy')
                          .format(_selectedBurialDate!),
                ),
                style: AppStyles.bodyText1,
                readOnly: true,
                onTap: () => _selectBurialDate(context),
              ),
              const SizedBox(height: 24),

              Text('Required Documents Checklist',
                  style: AppStyles.titleStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text('Confirm you have these documents ready for verification.',
                  style: AppStyles.caption.copyWith(fontSize: 13)),
              const SizedBox(height: 12),
              _buildDocumentCheckbox(
                title: 'Medical Certificate of Cause of Death',
                subtitle: 'Official document from a medical practitioner.',
                value: _hasMedicalCertificate,
                onChanged: (v) =>
                    setState(() => _hasMedicalCertificate = v ?? false),
              ),
              _buildDocumentCheckbox(
                title: 'Deceased\'s National ID / Passport',
                subtitle: 'Copy of identification document.',
                value: _hasDeceasedId,
                onChanged: (v) => setState(() => _hasDeceasedId = v ?? false),
              ),
              _buildDocumentCheckbox(
                title: 'Death Registration Form (D1/D2)',
                subtitle: 'Completed form for death registration.',
                value: _hasDeathRegistrationForm,
                onChanged: (v) =>
                    setState(() => _hasDeathRegistrationForm = v ?? false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _burialPermitNumberController,
                decoration: _customInputDecoration(
                    'Burial Permit Number', Icons.article_outlined),
                style: AppStyles.bodyText1,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Burial Permit number is required.'
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                child: Text('Obtain from Civil Registration / Huduma Centre.',
                    style: AppStyles.caption),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  foregroundColor: AppColors.buttonText,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppStyles.buttonBorderRadius),
                  textStyle: AppStyles.buttonTextStyle,
                ),
                onPressed: (_selectedPlotType == null ||
                        !_hasMedicalCertificate ||
                        !_hasDeceasedId ||
                        !_hasDeathRegistrationForm ||
                        _isSubmitting)
                    ? null
                    : _requestApprovalAndProceed,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : const Text('Request Space Approval'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
