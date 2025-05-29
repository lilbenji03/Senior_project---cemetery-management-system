// lib/screens/spot_booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cemetery_model.dart';
import '../models/spot_model.dart'; // Uses CemeterySpot and SpotStatus
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class SpotBookingDetailsPage extends StatefulWidget {
  // Renamed class
  final Cemetery cemetery;
  final CemeterySpot selectedSpot; // Parameter is CemeterySpot

  const SpotBookingDetailsPage({
    // Renamed class
    super.key,
    required this.cemetery,
    required this.selectedSpot, // Parameter is CemeterySpot
  });

  @override
  State<SpotBookingDetailsPage> createState() => _SpotBookingDetailsPageState(); // Renamed class
}

class _SpotBookingDetailsPageState extends State<SpotBookingDetailsPage> {
  // Renamed class
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlotType;

  bool _hasMedicalCertificate = false;
  bool _hasDeceasedId = false;
  bool _hasDeathRegistrationForm = false;
  final TextEditingController _burialPermitNumberController =
      TextEditingController();
  double _estimatedPlotCost = 0.0;

  final double langataPermanentAdultCost = 30500.00;
  final double langataTemporaryAdultCost = 7000.00;
  final double genericPermanentCost = 25000.00;
  final double genericTemporaryCost = 5000.00;

  @override
  void initState() {
    super.initState();
    if (widget.selectedSpot.plotType != null) {
      // Use selectedSpot
      _selectedPlotType = widget.selectedSpot.plotType;
      _updateEstimatedCost();
    }
  }

  void _updateEstimatedCost() {
    if (_selectedPlotType == null) {
      _estimatedPlotCost = 0.0;
      return;
    }
    if (widget.cemetery.id == '1') {
      _estimatedPlotCost =
          (_selectedPlotType == 'Permanent')
              ? langataPermanentAdultCost
              : langataTemporaryAdultCost;
    } else {
      _estimatedPlotCost =
          (_selectedPlotType == 'Permanent')
              ? genericPermanentCost
              : genericTemporaryCost;
    }
  }

  Future<void> _showPlotTypeSelectionDialog() async {
    double permanentCost =
        (widget.cemetery.id == '1')
            ? langataPermanentAdultCost
            : genericPermanentCost;
    double temporaryCost =
        (widget.cemetery.id == '1')
            ? langataTemporaryAdultCost
            : genericTemporaryCost;

    String? plotType = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String? tempDialogPlotType = _selectedPlotType;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Select Plot Type for ${widget.selectedSpot.id}',
              ), // Use selectedSpot
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RadioListTile<String>(
                    title: const Text('Permanent Grave'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Approx. KES ${permanentCost.toStringAsFixed(2)} (Adult)',
                        ),
                        const Text(
                          'Perpetual use, allows headstones.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    value: 'Permanent',
                    groupValue: tempDialogPlotType,
                    onChanged:
                        (String? value) =>
                            setDialogState(() => tempDialogPlotType = value),
                    activeColor: AppColors.appBar,
                  ),
                  RadioListTile<String>(
                    title: const Text('Temporary Grave'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Approx. KES ${temporaryCost.toStringAsFixed(2)} (Adult)',
                        ),
                        const Text(
                          'Short-term, reused after ~5 years, no permanent markers.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    value: 'Temporary',
                    groupValue: tempDialogPlotType,
                    onChanged:
                        (String? value) =>
                            setDialogState(() => tempDialogPlotType = value),
                    activeColor: AppColors.appBar,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                TextButton(
                  onPressed:
                      tempDialogPlotType == null
                          ? null
                          : () => Navigator.of(context).pop(tempDialogPlotType),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
    if (plotType != null) {
      setState(() {
        _selectedPlotType = plotType;
        _updateEstimatedCost();
      });
    }
  }

  void _requestApprovalAndProceed() {
    if (_selectedPlotType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plot type.')),
      );
      _showPlotTypeSelectionDialog();
      return;
    }
    if (!_hasMedicalCertificate ||
        !_hasDeceasedId ||
        !_hasDeathRegistrationForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm all required documents.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // TODO: Implement actual Supabase reservation creation
    // This would set the CemeterySpot status to pendingApproval in your DB
    // and create a Reservation entry.

    print(
      'Submitting Reservation for Spot: ${widget.selectedSpot.id}',
    ); // Use selectedSpot

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(
          'Request for spot ${widget.selectedSpot.id} (${_selectedPlotType!}) submitted. Cost: KES ${_estimatedPlotCost.toStringAsFixed(2)}. Check "My Reservations".',
        ),
      ),
    );
    int popCount = 0;
    Navigator.of(context).popUntil((_) => popCount++ >= 2); // Pop back twice
  }

  @override
  void dispose() {
    _burialPermitNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Book Spot: ${widget.selectedSpot.id} (${widget.cemetery.name})',
          style: AppStyles.appBarTitleStyle,
        ), // Title "Book Spot"
        backgroundColor: AppColors.appBar,
      ),
      body: SingleChildScrollView(
        padding: AppStyles.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirm Booking for Spot: ${widget.selectedSpot.id}',
                style: AppStyles.cardTitleStyle,
                textAlign: TextAlign.center,
              ), // Use selectedSpot
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plot Type Selection',
                        style: AppStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _selectedPlotType == null
                          ? Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Select Plot Type'),
                              onPressed: _showPlotTypeSelectionDialog,
                            ),
                          )
                          : ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Selected Plot Type: $_selectedPlotType',
                              style: AppStyles.bodyText1,
                            ),
                            subtitle:
                                _estimatedPlotCost > 0
                                    ? Text(
                                      'Estimated Cost: KES ${_estimatedPlotCost.toStringAsFixed(2)}',
                                      style: AppStyles.spotsAvailableStyle,
                                    )
                                    : null,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.appBar,
                              ),
                              onPressed: _showPlotTypeSelectionDialog,
                              tooltip: 'Change Plot Type',
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Required Documents Checklist',
                style: AppStyles.cardTitleStyle.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                'Please confirm you have the following documents ready for verification.',
                style: AppStyles.caption.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              _buildDocumentCheckbox(
                title: 'Medical Certificate of Cause of Death',
                value: _hasMedicalCertificate,
                onChanged:
                    (bool? value) =>
                        setState(() => _hasMedicalCertificate = value ?? false),
              ),
              _buildDocumentCheckbox(
                title: 'Deceased\'s National ID Card/Passport Copy',
                value: _hasDeceasedId,
                onChanged:
                    (bool? value) =>
                        setState(() => _hasDeceasedId = value ?? false),
              ),
              _buildDocumentCheckbox(
                title: 'Completed Death Registration Form (e.g., D1/D2)',
                value: _hasDeathRegistrationForm,
                onChanged:
                    (bool? value) => setState(
                      () => _hasDeathRegistrationForm = value ?? false,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _burialPermitNumberController,
                decoration: const InputDecoration(
                  labelText: 'Burial Permit Number',
                  hintText: 'Enter number (required)',
                  prefixIcon: Icon(Icons.article_outlined),
                ),
                style: AppStyles.bodyText1,
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? 'Burial Permit number is required.'
                            : null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                child: Text(
                  'Note: Obtain Burial Permit from Civil Registration/Huduma Centre.',
                  style: AppStyles.caption.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed:
                    (_selectedPlotType == null ||
                            !_hasMedicalCertificate ||
                            !_hasDeceasedId ||
                            !_hasDeathRegistrationForm)
                        ? null
                        : _requestApprovalAndProceed,
                child: const Text('Request Spot Approval'), // Renamed
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.cardBorderRadius.resolve(null) / 2,
      ),
      child: CheckboxListTile(
        title: Text(title, style: AppStyles.bodyText1.copyWith(fontSize: 14)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.appBar,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      ),
    );
  }
}
