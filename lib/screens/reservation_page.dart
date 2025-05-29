import 'dart:async';
import 'package:cmc/screens/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/reservation_model.dart'; // Ensure this model is defined
import '../models/cemetery_service_model.dart'; // Ensure this model is defined

// Make sure PaymentMethod enum is defined (e.g., in reservation_model.dart or here)
// enum PaymentMethod { mpesa, card, bank }

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  // Ensure sampleReservations is defined and accessible
  // (e.g., in reservation_model.dart or fetched from a service)
  List<Reservation> _allReservations = sampleReservations;
  List<Reservation> _filteredReservations = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode =
      FocusNode(); // For managing search field focus
  Timer? _countdownTimer;

  // State for the expanded booking completion section
  String? _completingReservationId;
  DateTime? _selectedBurialDate;
  List<CemeteryService> _availableServices = [];
  List<CemeteryService> _selectedServices = [];
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.mpesa;

  @override
  void initState() {
    super.initState();
    _fetchReservations(); // Initial fetch
    _availableServices = getSampleCemeteryServices(); // Load available services
    _searchController.addListener(
      _onSearchChanged,
    ); // Use a dedicated listener method
    _filteredReservations = _allReservations; // Initialize filtered list

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted &&
          _filteredReservations.any(
            (res) =>
                res.status == ReservationStatus.approved &&
                res.expiresAt != null &&
                DateTime.now().isBefore(res.expiresAt!),
          )) {
        setState(() {}); // Rebuild to update countdowns
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _fetchReservations() {
    // In a real app, this would fetch from a service or database
    // For now, we're using sample data
    setState(() {
      _allReservations = List.from(sampleReservations);
      _allReservations.sort(
        (a, b) => b.requestedAt.compareTo(a.requestedAt),
      ); // Sort by newest first
      // _filterReservations(); // Call filter after fetching/updating allReservations
    });
  }

  void _onSearchChanged() {
    _filterReservations();
    // Needed to update the clear button visibility based on text field content
    if (mounted) {
      setState(() {});
    }
  }

  void _filterReservations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredReservations =
          query.isEmpty
              ? _allReservations
              : _allReservations
                  .where(
                    (r) =>
                        r.id.toLowerCase().contains(query) ||
                        r.cemeteryName.toLowerCase().contains(query) ||
                        r.spotId.toLowerCase().contains(query) ||
                        (r.burialPermitNumber?.toLowerCase().contains(query) ??
                            false),
                  )
                  .toList();
    });
  }

  void _clearSearch() {
    if (!_searchFocusNode.hasFocus && mounted) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    }
    _searchController.clear();
    // The listener _onSearchChanged -> _filterReservations will update the list and UI.
  }

  // --- Other methods (_formatDateTime, _buildStatusChip, booking completion logic) remain the same ---
  // ... (Keep your existing methods for _formatDateTime, _buildStatusChip, _startBookingCompletion,
  //      _pickBurialDate, _toggleService, _calculateTotalCost, _finalizePayment,
  //      _buildBookingCompletionSection, _buildDetailRow, _getExpiryCountdown) ...
  String _formatDateTime(DateTime? dt) =>
      dt == null ? 'N/A' : DateFormat('MMM dd, yyyy - hh:mm a').format(dt);

  Widget _buildStatusChip(ReservationStatus status) {
    String text;
    Color backgroundColor;
    Color textColor = Colors.white;
    switch (status) {
      case ReservationStatus.pendingApproval:
        text = 'Pending Approval';
        backgroundColor = Colors.orange.shade700;
        break;
      case ReservationStatus.approved:
        text = 'Approved';
        backgroundColor = AppColors.spotsAvailable;
        break;
      case ReservationStatus.rejected:
        text = 'Rejected';
        backgroundColor = Colors.red.shade700;
        break;
      case ReservationStatus.expired:
        text = 'Expired';
        backgroundColor = Colors.grey.shade600;
        break;
      case ReservationStatus.paymentPending:
        text = 'Payment Pending';
        backgroundColor = Colors.blue.shade700;
        break;
      case ReservationStatus.completed:
        text = 'Completed';
        backgroundColor = AppColors.appBar;
        break;
    }
    return Chip(
      label: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
    );
  }

  void _startBookingCompletion(Reservation reservation) {
    setState(() {
      _completingReservationId = reservation.id;
      _selectedBurialDate = null;
      _selectedServices = [];
      for (var service in _availableServices) {
        service.isSelected = false;
      }
      _selectedPaymentMethod = PaymentMethod.mpesa;
    });
  }

  Future<void> _pickBurialDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBurialDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.appBar,
                onPrimary: AppColors.appBarTitle,
                onSurface: AppColors.cardTitle,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: AppColors.appBar),
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null && picked != _selectedBurialDate) {
      setState(() => _selectedBurialDate = picked);
    }
  }

  void _toggleService(CemeteryService service) {
    setState(() {
      service.isSelected = !service.isSelected;
      if (service.isSelected) {
        _selectedServices.add(service);
      } else {
        _selectedServices.removeWhere((s) => s.id == service.id);
      }
    });
  }

  double _calculateTotalCost(Reservation reservation) {
    double servicesCost = _selectedServices.fold(
      0,
      (sum, item) => sum + item.cost,
    );
    return reservation.estimatedCost + servicesCost;
  }

  void _finalizePayment(Reservation reservation) {
    if (_selectedBurialDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a burial date.')),
      );
      return;
    }
    final totalCost = _calculateTotalCost(reservation);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Simulating payment of KES ${totalCost.toStringAsFixed(2)} via ${_selectedPaymentMethod.toString().split('.').last} for ${reservation.id}',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    final index = _allReservations.indexWhere((r) => r.id == reservation.id);
    if (index != -1) {
      final updatedReservation = Reservation(
        id: reservation.id,
        cemeteryName: reservation.cemeteryName,
        spotId: reservation.spotId,
        plotType: reservation.plotType,
        estimatedCost: reservation.estimatedCost,
        requestedAt: reservation.requestedAt,
        approvedAt: reservation.approvedAt,
        burialPermitNumber: reservation.burialPermitNumber,
        status: ReservationStatus.completed,
      );
      setState(() {
        _allReservations[index] = updatedReservation;
        _completingReservationId = null;
        _filterReservations();
      });
    }
  }

  Widget _buildBookingCompletionSection(Reservation reservation) {
    if (_completingReservationId != reservation.id) {
      return const SizedBox.shrink();
    }
    double totalCost = _calculateTotalCost(reservation);
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(top: 10.0),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: AppColors.appBar.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Your Booking for Spot ${reservation.spotId}',
            style: AppStyles.cardTitleStyle.copyWith(fontSize: 15),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.appBar),
            title: Text(
              _selectedBurialDate == null
                  ? 'Select Burial Date'
                  : 'Burial Date: ${DateFormat('EEE, MMM dd, yyyy').format(_selectedBurialDate!)}',
            ),
            trailing: const Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.appBar,
            ),
            onTap: () => _pickBurialDate(context),
          ),
          const SizedBox(height: 10),
          Text(
            'Additional Services (Optional):',
            style: AppStyles.regularText.copyWith(fontWeight: FontWeight.bold),
          ),
          ..._availableServices.map(
            (service) => CheckboxListTile(
              title: Text(
                '${service.name} (KES ${service.cost.toStringAsFixed(2)})',
              ),
              value: service.isSelected,
              onChanged: (bool? value) => _toggleService(service),
              activeColor: AppColors.appBar,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cost Summary:',
            style: AppStyles.regularText.copyWith(fontWeight: FontWeight.bold),
          ),
          _buildDetailRow(
            'Plot Cost:',
            'KES ${reservation.estimatedCost.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            'Services Cost:',
            'KES ${_selectedServices.fold<double>(0, (sum, item) => sum + item.cost).toStringAsFixed(2)}',
          ),
          const Divider(thickness: 1),
          _buildDetailRow(
            'Total Amount:',
            'KES ${totalCost.toStringAsFixed(2)}',
            isBold: true,
            color: AppColors.spotsAvailable,
          ),
          const SizedBox(height: 16),
          Text(
            'Select Payment Method:',
            style: AppStyles.regularText.copyWith(fontWeight: FontWeight.bold),
          ),
          RadioListTile<PaymentMethod>(
            title: const Text('M-Pesa'),
            value: PaymentMethod.mpesa,
            groupValue: _selectedPaymentMethod,
            onChanged:
                (PaymentMethod? value) =>
                    setState(() => _selectedPaymentMethod = value),
            activeColor: AppColors.appBar,
            dense: true,
          ),
          RadioListTile<PaymentMethod>(
            title: const Text('Card (Visa, Mastercard)'),
            value: PaymentMethod.card,
            groupValue: _selectedPaymentMethod,
            onChanged:
                (PaymentMethod? value) =>
                    setState(() => _selectedPaymentMethod = value),
            activeColor: AppColors.appBar,
            dense: true,
          ),
          RadioListTile<PaymentMethod>(
            title: const Text('Bank Transfer'),
            value: PaymentMethod.bank,
            groupValue: _selectedPaymentMethod,
            onChanged:
                (PaymentMethod? value) =>
                    setState(() => _selectedPaymentMethod = value),
            activeColor: AppColors.appBar,
            dense: true,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    () => setState(() => _completingReservationId = null),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Confirm & Pay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  foregroundColor: AppColors.buttonText,
                ),
                onPressed: () => _finalizePayment(reservation),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: AppStyles.regularText.copyWith(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.regularText.copyWith(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getExpiryCountdown(DateTime expiresAt) {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 'Expired';
    final difference = expiresAt.difference(now);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(difference.inHours);
    final minutes = twoDigits(difference.inMinutes.remainder(60));
    final seconds = twoDigits(difference.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold or AppBar here. This page is the body for MainScreen's "Reservations" tab.
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Enhanced Search Bar
          Padding(
            padding: AppStyles.pagePadding.copyWith(top: 16.0, bottom: 12.0),
            child: Material(
              // Optional: for elevation/shadow
              elevation: AppStyles.elevationLow / 2,
              borderRadius: AppStyles.cardBorderRadius,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: AppStyles.bodyText1.copyWith(
                  color: AppColors.primaryText,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by ID, Cemetery, Spot...',
                  hintStyle: AppStyles.bodyText2.copyWith(
                    color: AppColors.secondaryText.withOpacity(0.7),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.secondaryText,
                    size: 22,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.secondaryText,
                              size: 20,
                            ),
                            onPressed: _clearSearch,
                            splashRadius: 20,
                            tooltip: 'Clear search',
                          )
                          : null,
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 16.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: BorderSide.none, // If using Material elevation
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: const BorderSide(
                      color: AppColors.appBar,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  // To update suffixIcon visibility
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          // List of Reservations
          Expanded(
            child:
                _filteredReservations.isEmpty
                    ? Center(
                      child:
                          _searchController.text.isNotEmpty &&
                                  _allReservations.isNotEmpty
                              ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No reservations found matching "${_searchController.text}".',
                                  style: AppStyles.bodyText2.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'You have no reservations yet.',
                                    style: AppStyles.bodyText1.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Find and book a spot from the Home page.',
                                    style: AppStyles.caption.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                    )
                    : ListView.builder(
                      padding: AppStyles.pagePadding.copyWith(
                        top: 0,
                        left: 8.0,
                        right: 8.0,
                      ),
                      itemCount: _filteredReservations.length,
                      itemBuilder: (context, index) {
                        final reservation = _filteredReservations[index];
                        bool isActuallyExpired =
                            reservation.expiresAt != null &&
                            DateTime.now().isAfter(reservation.expiresAt!);
                        final displayStatus =
                            (reservation.status == ReservationStatus.approved &&
                                    isActuallyExpired)
                                ? ReservationStatus.expired
                                : reservation.status;

                        return Card(
                          // Your existing Card structure for displaying reservation details
                          // No changes needed inside the Card itself for this search bar update
                          elevation: AppStyles.elevationLow,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppStyles.cardBorderRadius,
                          ),
                          child: Padding(
                            padding: AppStyles.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Reservation #${reservation.id}',
                                        style: AppStyles.cardTitleStyle
                                            .copyWith(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildStatusChip(displayStatus),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Cemetery:',
                                  reservation.cemeteryName,
                                ),
                                _buildDetailRow('Spot ID:', reservation.spotId),
                                _buildDetailRow(
                                  'Plot Type:',
                                  reservation.plotType,
                                ),
                                _buildDetailRow(
                                  'Est. Plot Cost:',
                                  'KES ${reservation.estimatedCost.toStringAsFixed(2)}',
                                ),
                                if (reservation.burialPermitNumber != null &&
                                    reservation.burialPermitNumber!.isNotEmpty)
                                  _buildDetailRow(
                                    'Burial Permit:',
                                    reservation.burialPermitNumber!,
                                  ),
                                _buildDetailRow(
                                  'Requested:',
                                  _formatDateTime(reservation.requestedAt),
                                ),
                                if (displayStatus ==
                                        ReservationStatus.approved ||
                                    displayStatus ==
                                        ReservationStatus.paymentPending ||
                                    displayStatus ==
                                        ReservationStatus.completed)
                                  _buildDetailRow(
                                    'Approved:',
                                    _formatDateTime(reservation.approvedAt),
                                  ),
                                if (displayStatus ==
                                        ReservationStatus.approved &&
                                    reservation.expiresAt != null &&
                                    !isActuallyExpired)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Expires In: ${_getExpiryCountdown(reservation.expiresAt!)}',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                // ... (Your conditional action buttons/text for different statuses)
                                if (displayStatus ==
                                        ReservationStatus.approved &&
                                    !isActuallyExpired)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.edit_calendar_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        _completingReservationId ==
                                                reservation.id
                                            ? 'Finalizing...'
                                            : 'Complete Booking',
                                      ),
                                      onPressed:
                                          _completingReservationId ==
                                                  reservation.id
                                              ? null
                                              : () => _startBookingCompletion(
                                                reservation,
                                              ),
                                    ),
                                  )
                                else if (displayStatus ==
                                    ReservationStatus.paymentPending)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        /* Navigate to payment details */
                                      },
                                      child: const Text('View Payment Details'),
                                    ),
                                  )
                                // ... other status UI ...
                                else if (displayStatus ==
                                    ReservationStatus.completed)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'This booking is completed.',
                                      style: AppStyles.bodyText1.copyWith(
                                        color: AppColors.spotsAvailable,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                _buildBookingCompletionSection(reservation),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
