// lib/screens/spot_booking_details_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cemetery_model.dart';
import '../models/spot_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
// import '../screens/main_screen.dart'; // Only if needed for specific navigation like to reservations tab

final supabase = Supabase.instance.client;

class SpotBookingDetailsPage extends StatefulWidget {
  final Cemetery cemetery;
  final CemeterySpot selectedSpot;

  const SpotBookingDetailsPage({
    super.key,
    required this.cemetery,
    required this.selectedSpot,
  });

  @override
  State<SpotBookingDetailsPage> createState() => _SpotBookingDetailsPageState();
}

class _SpotBookingDetailsPageState extends State<SpotBookingDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlotType;
  bool _hasMedicalCertificate = false;
  bool _hasDeceasedId = false;
  bool _hasDeathRegistrationForm = false;
  final TextEditingController _burialPermitNumberController =
      TextEditingController();
  double _estimatedPlotCost = 0.0;
  bool _isSubmitting = false;

  // Costs - these should ideally be more dynamic or part of Cemetery model in a real app
  final double langataPermanentAdultCost = 30500.00;
  final double langataTemporaryAdultCost = 7000.00;
  final double genericPermanentCost = 25000.00;
  final double genericTemporaryCost = 5000.00;

  @override
  void initState() {
    super.initState();
    if (widget.selectedSpot.plotType != null &&
        widget.selectedSpot.plotType!.isNotEmpty) {
      _selectedPlotType = widget.selectedSpot.plotType;
      _updateEstimatedCost();
    }
  }

  @override
  void dispose() {
    _burialPermitNumberController.dispose();
    super.dispose();
  }

  void _updateEstimatedCost() {
    if (!mounted) return;
    if (_selectedPlotType == null) {
      setState(() => _estimatedPlotCost = 0.0);
      return;
    }
    double cost;
    if (widget.cemetery.id == '1') {
      // Lang'ata example ID
      cost =
          (_selectedPlotType == 'Permanent')
              ? langataPermanentAdultCost
              : langataTemporaryAdultCost;
    } else {
      cost =
          (_selectedPlotType == 'Permanent')
              ? genericPermanentCost
              : genericTemporaryCost;
    }
    setState(() => _estimatedPlotCost = cost);
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
    String? dialogSelectedPlotType = _selectedPlotType;

    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Select Plot Type for ${widget.selectedSpot.id}'),
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius,
              ),
              contentPadding: const EdgeInsets.only(
                top: 20.0,
                left: 24.0,
                right: 24.0,
                bottom: 0,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RadioListTile<String>(
                      title: const Text('Permanent Grave'),
                      subtitle: Text(
                        'Approx. KES ${permanentCost.toStringAsFixed(2)} (Adult)\nPerpetual use, allows headstones.',
                        style: AppStyles.caption.copyWith(fontSize: 12),
                      ),
                      value: 'Permanent',
                      groupValue: dialogSelectedPlotType,
                      onChanged:
                          (String? value) => setDialogState(
                            () => dialogSelectedPlotType = value,
                          ),
                      activeColor: AppColors.appBar,
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('Temporary Grave'),
                      subtitle: Text(
                        'Approx. KES ${temporaryCost.toStringAsFixed(2)} (Adult)\nShort-term, reused after ~5 years.',
                        style: AppStyles.caption.copyWith(fontSize: 12),
                      ),
                      value: 'Temporary',
                      groupValue: dialogSelectedPlotType,
                      onChanged:
                          (String? value) => setDialogState(
                            () => dialogSelectedPlotType = value,
                          ),
                      activeColor: AppColors.appBar,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                ),
                TextButton(
                  onPressed:
                      dialogSelectedPlotType == null
                          ? null
                          : () => Navigator.of(
                            dialogContext,
                          ).pop(dialogSelectedPlotType),
                  child: const Text('Confirm'),
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

  Future<void> _requestApprovalAndProceed() async {
    if (_selectedPlotType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plot type.')),
      );
      await _showPlotTypeSelectionDialog();
      if (_selectedPlotType == null || !mounted) return; // Recheck after dialog
    }
    if (!_hasMedicalCertificate ||
        !_hasDeceasedId ||
        !_hasDeathRegistrationForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm all required preliminary documents.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please log in again.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        setState(() => _isSubmitting = false);
      }
      return;
    }

    final Map<String, dynamic> newReservationData = {
      'user_id': userId,
      'cemetery_id': widget.cemetery.id,
      'cemetery_spot_id': widget.selectedSpot.dbId,
      'spot_identifier': widget.selectedSpot.id,
      'cemetery_name': widget.cemetery.name,
      'plot_type': _selectedPlotType!,
      'status': 'pendingApproval',
      'requested_at': DateTime.now().toIso8601String(),
      'estimated_plot_cost': _estimatedPlotCost,
      'burial_permit_number': _burialPermitNumberController.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('reservations').insert(newReservationData);
      await supabase
          .from('cemetery_spots')
          .update({
            'status': 'pendingApproval',
            'plot_type': _selectedPlotType,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.selectedSpot.dbId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Text(
              'Request for spot ${widget.selectedSpot.id} (${_selectedPlotType!}) submitted. Check "My Reservations".',
            ),
            backgroundColor: AppColors.spotsAvailable,
          ),
        );
        // Pop this page and return true to CemeterySpotListPage to trigger refresh
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Corrected: Added SnackBar widget
          SnackBar(
            content: Text('Failed to submit request: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // --- DEFINE HELPER METHODS BEFORE build() ---
  Widget _buildDocumentCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.cardBorderRadius / 2,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Book: ${widget.selectedSpot.id} (${widget.cemetery.name})',
          style: AppStyles.appBarTitleStyle,
        ),
        backgroundColor: AppColors.appBar,
        elevation: AppStyles.elevationLow,
      ),
      body: SingleChildScrollView(
        padding: AppStyles.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirm Booking Details for Spot: ${widget.selectedSpot.id}',
                style: AppStyles.cardTitleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: AppStyles.elevationLow,
                shape: RoundedRectangleBorder(
                  borderRadius: AppStyles.cardBorderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plot Type Selection',
                        style: AppStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _selectedPlotType == null
                          ? Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.category_outlined),
                              label: const Text('Select Plot Type'),
                              onPressed: _showPlotTypeSelectionDialog,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          )
                          : ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Selected Plot Type:',
                              style: AppStyles.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            subtitle: Text(
                              _selectedPlotType!,
                              style: AppStyles.bodyText1.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.appBar,
                              ),
                              onPressed: _showPlotTypeSelectionDialog,
                              tooltip: 'Change Plot Type',
                            ),
                          ),
                      if (_selectedPlotType != null &&
                          _estimatedPlotCost > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Estimated Plot Cost: KES ${_estimatedPlotCost.toStringAsFixed(2)}',
                          style: AppStyles.spotsAvailableStyle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ],
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
                    (v) => setState(() => _hasMedicalCertificate = v ?? false),
              ),
              _buildDocumentCheckbox(
                title: 'Deceased\'s National ID Card/Passport Copy',
                value: _hasDeceasedId,
                onChanged: (v) => setState(() => _hasDeceasedId = v ?? false),
              ),
              _buildDocumentCheckbox(
                title: 'Completed Death Registration Form (e.g., D1/D2)',
                value: _hasDeathRegistrationForm,
                onChanged:
                    (v) =>
                        setState(() => _hasDeathRegistrationForm = v ?? false),
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
                            !_hasDeathRegistrationForm ||
                            _isSubmitting)
                        ? null
                        : _requestApprovalAndProceed,
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Text('Request Spot Approval'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
