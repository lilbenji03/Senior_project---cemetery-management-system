// lib/screens/map_booking_page.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/cemetery_model.dart';
import '../models/spot_model.dart'; // Import the Spot model

class MapBookingPage extends StatefulWidget {
  final Cemetery cemetery;

  const MapBookingPage({super.key, required this.cemetery});

  @override
  State<MapBookingPage> createState() => _MapBookingPageState();
}

class _MapBookingPageState extends State<MapBookingPage> {
  final _formKey = GlobalKey<FormState>();
  List<CemeterySpot> _spots = [];
  CemeterySpot? _selectedSpot;
  String? _selectedPlotType; // 'Permanent' or 'Temporary'

  // Document checklist states
  bool _hasMedicalCertificate = false;
  bool _hasDeceasedId = false;
  bool _hasDeathRegistrationForm = false;
  final TextEditingController _burialPermitNumberController =
      TextEditingController();

  double _estimatedPlotCost = 0.0;

  // Lang'ata specific costs (approximations based on provided info)
  // Assuming adult costs for now. The $ values are converted to KES assuming an exchange rate.
  // You should use up-to-date KES figures directly if available.
  // Let's assume KES 30,500 for permanent and KES 7,000 for temporary as per earlier info if USD conversion is tricky.
  final double langataPermanentAdultCost = 30500.00; // KES
  final double langataTemporaryAdultCost = 7000.00; // KES
  // If you have infant costs and a way to select age group:
  // final double langataPermanentInfantCost = 15000.00; // KES (example based on $147)

  @override
  void initState() {
    super.initState();
    _fetchCemeterySpots();
  }

  void _fetchCemeterySpots() {
    setState(() {
      _spots = getSampleSpotsForCemetery(widget.cemetery.id);
    });
  }

  Color _getColorForStatus(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return AppColors.progressBarFill;
      case SpotStatus.booked:
      case SpotStatus.pendingApproval:
        return Colors.orange;
      case SpotStatus.used:
        return Colors.redAccent;
      default:
        return AppColors.progressBarTrack;
    }
  }

  String _getTextForStatus(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return "Available";
      case SpotStatus.booked:
        return "Booked";
      case SpotStatus.pendingApproval:
        return "Pending Approval";
      case SpotStatus.used:
        return "Used";
      default:
        return "Unknown";
    }
  }

  void _onSpotSelected(CemeterySpot spot) {
    if (spot.status == SpotStatus.available) {
      setState(() {
        _selectedSpot = spot;
        _selectedPlotType = null;
        _estimatedPlotCost = 0.0;
      });
      _showPlotTypeSelectionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Spot ${spot.id} is ${_getTextForStatus(spot.status)} and cannot be selected.',
          ),
        ),
      );
    }
  }

  Future<void> _showPlotTypeSelectionDialog() async {
    if (_selectedSpot == null) return;

    double permanentCost =
        langataPermanentAdultCost; // Default to Lang'ata adult
    double temporaryCost =
        langataTemporaryAdultCost; // Default to Lang'ata adult

    // If not Lang'ata, use some generic defaults or fetch from cemetery model
    if (widget.cemetery.id != '1') {
      // Assuming '1' is Lang'ata ID
      permanentCost = 25000.00; // Generic default
      temporaryCost = 5000.00; // Generic default
    }

    String? plotType = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String? tempDialogPlotType = _selectedPlotType;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Plot Type for ${_selectedSpot!.id}'),
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
                    onChanged: (String? value) {
                      setDialogState(() {
                        tempDialogPlotType = value;
                      });
                    },
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
                    onChanged: (String? value) {
                      setDialogState(() {
                        tempDialogPlotType = value;
                      });
                    },
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
        _selectedSpot!.plotType = plotType; // Assign to the spot model instance
        _estimatedPlotCost =
            (plotType == 'Permanent') ? permanentCost : temporaryCost;
      });
    }
  }

  void _requestApprovalAndProceed() {
    if (_selectedSpot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available spot from the map.'),
        ),
      );
      return;
    }
    if (_selectedPlotType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a plot type (Permanent/Temporary).'),
        ),
      );
      _showPlotTypeSelectionDialog();
      return;
    }
    if (!_hasMedicalCertificate ||
        !_hasDeceasedId ||
        !_hasDeathRegistrationForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm all required preliminary documents by checking the boxes.',
          ),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Burial Permit number.')),
      );
      return;
    }

    setState(() {
      int spotIndex = _spots.indexWhere((s) => s.id == _selectedSpot!.id);
      if (spotIndex != -1) {
        _spots[spotIndex] = CemeterySpot(
          id: _spots[spotIndex].id,
          status: SpotStatus.pendingApproval,
          cemeteryId: _spots[spotIndex].cemeteryId,
          plotType: _selectedPlotType,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(
          'Request for spot ${_selectedSpot!.id} (${_selectedPlotType!}) submitted for approval. Cost: KES ${_estimatedPlotCost.toStringAsFixed(2)}. Burial Permit: ${_burialPermitNumberController.text}. Check Reservations page.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Book Spot: ${widget.cemetery.name}',
          style: AppStyles.appBarTitleStyle,
        ),
        backgroundColor: AppColors.appBar,
        iconTheme: const IconThemeData(color: AppColors.appBarTitle),
      ),
      body: SingleChildScrollView(
        padding: AppStyles.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Wrap(
                  spacing: 16.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children:
                      SpotStatus.values.map((status) {
                        if (status == SpotStatus.available ||
                            status == SpotStatus.booked ||
                            status == SpotStatus.used ||
                            status == SpotStatus.pendingApproval) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: _getColorForStatus(status),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getTextForStatus(status),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                ),
              ),
              Container(
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.progressBarTrack),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey[200],
                ),
                child:
                    _spots.isEmpty
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.appBar,
                          ),
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    (widget.cemetery.id == '1') ? 12 : 8,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 4.0,
                                mainAxisSpacing: 4.0,
                              ),
                          itemCount: _spots.length > 60 ? 60 : _spots.length,
                          itemBuilder: (context, index) {
                            final spot = _spots[index];
                            bool isCurrentlySelected =
                                _selectedSpot?.id == spot.id;
                            return GestureDetector(
                              onTap: () => _onSpotSelected(spot),
                              child: Tooltip(
                                message:
                                    '${spot.id}\nStatus: ${_getTextForStatus(spot.status)}'
                                    '\n${spot.plotType != null ? "Type: ${spot.plotType}" : ""}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getColorForStatus(spot.status),
                                    border: Border.all(
                                      color:
                                          isCurrentlySelected
                                              ? Colors.blueAccent.shade700
                                              : Colors.black45,
                                      width: isCurrentlySelected ? 2.5 : 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Center(
                                    child: Text(
                                      spot.id.length > 5
                                          ? spot.id.substring(
                                            spot.id.length - 3,
                                          )
                                          : spot.id,
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            spot.status ==
                                                        SpotStatus.available ||
                                                    spot.status ==
                                                        SpotStatus
                                                            .pendingApproval
                                                ? Colors.white
                                                : Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
              const SizedBox(height: 16),
              if (_selectedSpot != null)
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Spot: ${_selectedSpot!.id}',
                          style: AppStyles.cardTitleStyle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Status: ${_getTextForStatus(_selectedSpot!.status)}',
                          style: TextStyle(
                            color: _getColorForStatus(_selectedSpot!.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedPlotType != null) ...[
                          Text(
                            'Plot Type: $_selectedPlotType',
                            style: AppStyles.regularText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_estimatedPlotCost > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Estimated Cost: KES ${_estimatedPlotCost.toStringAsFixed(2)}',
                                style: AppStyles.spotsAvailableStyle,
                              ),
                            ),
                          if (_selectedPlotType == 'Permanent')
                            const Text(
                              'Features: Perpetual use, allows headstones.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (_selectedPlotType == 'Temporary')
                            const Text(
                              'Features: Short-term, reused after ~5 years, no permanent markers.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ] else if (_selectedSpot!.status ==
                            SpotStatus.available)
                          Text(
                            'Please select a plot type (Permanent/Temporary).',
                            style: AppStyles.regularText.copyWith(
                              color: Colors.red.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (_selectedSpot != null &&
                  _selectedSpot!.status == SpotStatus.available &&
                  _selectedPlotType != null) ...[
                Text(
                  'Required Documents Checklist for Booking',
                  style: AppStyles.cardTitleStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildDocumentCheckbox(
                  title: 'Medical Certificate of Cause of Death',
                  value: _hasMedicalCertificate,
                  onChanged:
                      (bool? value) => setState(
                        () => _hasMedicalCertificate = value ?? false,
                      ),
                ),
                _buildDocumentCheckbox(
                  title: 'Deceased\'s National ID Card',
                  value: _hasDeceasedId,
                  onChanged:
                      (bool? value) =>
                          setState(() => _hasDeceasedId = value ?? false),
                ),
                _buildDocumentCheckbox(
                  title: 'Completed Death Registration Form (D1/D2 or D2/D3)',
                  value: _hasDeathRegistrationForm,
                  onChanged:
                      (bool? value) => setState(
                        () => _hasDeathRegistrationForm = value ?? false,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _burialPermitNumberController,
                  decoration: InputDecoration(
                    labelText: 'Burial Permit Number',
                    hintText: 'Enter number once obtained',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                  ),
                  validator: (value) {
                    if (_selectedSpot != null &&
                        _selectedSpot!.status == SpotStatus.available &&
                        _selectedPlotType != null) {
                      if (value == null || value.isEmpty) {
                        return 'Burial Permit number is required.';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    'Note: Burial Permit obtained from Civil Registration/Huduma Centre after submitting the above documents.',
                    style: AppStyles.regularText.copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  onPressed: _requestApprovalAndProceed,
                  child: const Text(
                    'Request Approval & Proceed',
                    style: AppStyles.buttonTextStyle,
                  ),
                ),
              ] else if (_selectedSpot != null &&
                  _selectedSpot!.status != SpotStatus.available)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'This spot is not available for booking.',
                    textAlign: TextAlign.center,
                    style: AppStyles.regularText.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (_selectedSpot == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Select an available spot from the map to proceed.',
                    textAlign: TextAlign.center,
                    style: AppStyles.regularText.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      child: CheckboxListTile(
        title: Text(title, style: AppStyles.regularText.copyWith(fontSize: 14)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.appBar,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
    );
  }
}
