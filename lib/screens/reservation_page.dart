// lib/screens/reservation_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/reservation_model.dart';
import '../models/cemetery_service_model.dart';

final supabase = Supabase.instance.client;

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  List<Reservation> _allReservations = [];
  List<Reservation> _filteredReservations = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _countdownTimer;
  bool _isLoading = true;
  String? _errorMessage;

  // State for booking completion
  String? _completingReservationId;
  DateTime? _selectedBurialDate;
  List<CemeteryService> _availableServices = [];
  List<CemeteryService> _selectedServices = [];
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.mpesa;
  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    _fetchReservationsFromSupabase();
    _fetchAvailableServices();
    _searchController.addListener(_onSearchChanged);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      bool needsUpdate = _filteredReservations.any((res) =>
          res.status == ReservationStatus.approved &&
          res.expiresAt != null &&
          DateTime.now().isBefore(res.expiresAt!));

      if (needsUpdate) {
        setState(() {});
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

  static ReservationStatus _parseReservationStatus(String? statusString) {
    if (statusString == null) return ReservationStatus.unknown;
    String normalizedStatus =
        statusString.toLowerCase().replaceAll('_', '').replaceAll(' ', '');

    switch (normalizedStatus) {
      case 'pending':
        return ReservationStatus.paymentPending;
      case 'pendingapproval':
        return ReservationStatus.pendingApproval;
      case 'approved':
        return ReservationStatus.approved;
      case 'rejected':
        return ReservationStatus.rejected;
      case 'expired':
        return ReservationStatus.expired;
      case 'paymentpending':
        return ReservationStatus.paymentPending;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'cancelledbyuser':
        return ReservationStatus.cancelledByUser;
      case 'cancelledbyadmin':
        return ReservationStatus.cancelledByAdmin;
      default:
        print(
            "ReservationPage (Parser): Unknown ReservationStatus string received from DB: '$statusString'");
        return ReservationStatus.unknown;
    }
  }

  Future<void> _fetchAvailableServices() async {
    try {
      final List<dynamic> data = await supabase
          .from('cemetery_services')
          .select()
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          // This now works because CemeteryService.fromJson is synchronous
          _availableServices =
              data.map((e) => CemeteryService.fromJson(e)).toList();
        });
      }
    } catch (e) {
      print("Error fetching grave care services: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load additional services.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _fetchReservationsFromSupabase() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw "User not authenticated. Please login again.";
      }

      final List<dynamic> response = await supabase
          .from('reservations')
          .select('*, cemetery_spaces (space_identifier)')
          .eq('user_id', userId)
          .order('requested_at', ascending: false);

      if (mounted) {
        setState(() {
          _allReservations = response.map((data) {
            data['status_enum_parsed_for_ui'] =
                _parseReservationStatus(data['status']);
            return Reservation.fromJson(data);
          }).toList();
          _filteredReservations = List.from(_allReservations);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print("Error fetching reservations: $e");
        setState(() {
          _errorMessage = "Failed to load reservations: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() => _filterReservations();

  void _filterReservations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredReservations = List.from(_allReservations);
      } else {
        _filteredReservations = _allReservations
            .where((r) =>
                r.id.toLowerCase().contains(query) ||
                r.cemeteryName.toLowerCase().contains(query) ||
                r.spaceIdentifier.toLowerCase().contains(query) ||
                (r.burialPermitNumber?.toLowerCase().contains(query) ?? false))
            .toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    if (!_searchFocusNode.hasFocus && mounted) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    }
  }

  String _formatDateTime(DateTime? dt) =>
      dt == null ? 'N/A' : DateFormat('MMM dd, yyyy - hh:mm a').format(dt);

  Widget _buildStatusChip(ReservationStatus status) {
    String text;
    Color backgroundColor;
    IconData? icon;
    Color textColor = Colors.white;

    switch (status) {
      case ReservationStatus.pendingApproval:
        text = 'Pending Approval';
        backgroundColor = Colors.orange.shade700;
        icon = Icons.hourglass_empty_rounded;
        break;
      case ReservationStatus.approved:
        text = 'Approved';
        backgroundColor = AppColors.spotsAvailable;
        icon = Icons.check_circle_outline_rounded;
        break;
      case ReservationStatus.rejected:
        text = 'Rejected';
        backgroundColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        break;
      case ReservationStatus.expired:
        text = 'Expired';
        backgroundColor = Colors.grey.shade600;
        icon = Icons.timer_off_outlined;
        break;
      case ReservationStatus.paymentPending:
        text = 'Payment Due';
        backgroundColor = Colors.blue.shade700;
        icon = Icons.payment_rounded;
        break;
      case ReservationStatus.completed:
        text = 'Completed';
        backgroundColor = AppColors.appBar;
        icon = Icons.task_alt_rounded;
        break;
      case ReservationStatus.cancelled:
        text = 'Cancelled';
        backgroundColor = Colors.grey.shade700;
        icon = Icons.do_not_disturb_on_outlined;
        break;
      case ReservationStatus.cancelledByUser:
        text = 'Cancelled (User)';
        backgroundColor = Colors.grey.shade700;
        icon = Icons.do_not_disturb_on_outlined;
        break;
      case ReservationStatus.cancelledByAdmin:
        text = 'Cancelled (Admin)';
        backgroundColor = Colors.grey.shade700;
        icon = Icons.admin_panel_settings_outlined;
        break;
      case ReservationStatus.unknown:
      default:
        text = status.toString().split('.').last.toUpperCase();
        backgroundColor = Colors.black54;
        icon = Icons.help_outline_rounded;
        break;
    }
    return Chip(
      avatar: icon != null ? Icon(icon, color: textColor, size: 14) : null,
      label: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
      labelPadding: EdgeInsets.only(left: icon != null ? 2.0 : 4.0, right: 4.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _startBookingCompletion(Reservation reservation) {
    if (!mounted) return;
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
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.appBar,
            onPrimary: Colors.white,
            onSurface: AppColors.primaryText,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.appBar),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedBurialDate) {
      if (mounted) setState(() => _selectedBurialDate = picked);
    }
  }

  void _toggleService(CemeteryService service) {
    if (!mounted) return;
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
    double servicesCost =
        _selectedServices.fold(0.0, (sum, item) => sum + item.cost);
    return reservation.estimatedCost + servicesCost;
  }

  // --- MODIFIED: This function now orchestrates the payment simulation flow ---
  Future<void> _finalizePayment(Reservation reservation) async {
    if (_selectedBurialDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a burial date.'),
              backgroundColor: AppColors.errorColor),
        );
      }
      return;
    }

    if (mounted) setState(() => _isFinalizing = true);

    // Show the payment simulation dialog and wait for its result
    final paymentSuccessful = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User can't dismiss by tapping outside
      builder: (context) => PaymentSimulationDialog(
        paymentMethod: _selectedPaymentMethod ?? PaymentMethod.mpesa,
        totalCost: _calculateTotalCost(reservation),
      ),
    );

    // Handle the result from the dialog
    if (paymentSuccessful == true) {
      // If payment was "successful", update the reservation in the database
      await _completeReservationInDatabase(reservation);
    } else {
      // If payment failed or was cancelled by the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was cancelled or failed. Please try again.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }

    if (mounted) setState(() => _isFinalizing = false);
  }

  // --- NEW: This function contains the database update logic ---
  Future<void> _completeReservationInDatabase(Reservation reservation) async {
    try {
      final totalCost = _calculateTotalCost(reservation);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) throw 'User is not authenticated.';

      final List<Map<String, dynamic>> servicesData =
          _selectedServices.map((s) {
        return {'id': s.id, 'name': s.name, 'cost': s.cost};
      }).toList();

      final updateData = {
        'status': ReservationStatus.completed.name,
        'selected_burial_date': _selectedBurialDate!.toIso8601String(),
        'final_total_cost': totalCost,
        'payment_method': _selectedPaymentMethod.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
        'selected_services': servicesData,
      };

      await supabase
          .from('reservations')
          .update(updateData)
          .eq('id', reservation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking details saved. Reservation is complete!'),
            backgroundColor: AppColors.spotsAvailable,
          ),
        );
        // Refresh the list and close the booking completion form
        _fetchReservationsFromSupabase();
        setState(() => _completingReservationId = null);
      }
    } catch (e) {
      print("Error finalizing booking in database: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving booking details: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildBookingCompletionSection(Reservation reservation) {
    if (_completingReservationId != reservation.id) {
      return const SizedBox.shrink();
    }
    double totalCost = _calculateTotalCost(reservation);

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 12.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.appBar.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Booking: Spot ${reservation.spaceIdentifier}',
            style: AppStyles.cardTitleStyle
                .copyWith(fontSize: 16, color: AppColors.appBar),
          ),
          const Divider(height: 20),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded,
                color: AppColors.appBar),
            title: Text(
              _selectedBurialDate == null
                  ? 'Select Burial Date *'
                  : 'Burial Date: ${DateFormat('EEE, MMM dd, yyyy').format(_selectedBurialDate!)}',
              style: _selectedBurialDate == null
                  ? const TextStyle(color: Colors.redAccent)
                  : null,
            ),
            trailing: const Icon(Icons.edit_calendar_outlined,
                color: AppColors.secondaryText),
            onTap: () => _pickBurialDate(context),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Text(
            'Additional Services (Optional):',
            style: AppStyles.regularText
                .copyWith(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          if (_availableServices.isEmpty && _isLoading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Loading services..."),
            )),
          ..._availableServices.map(
            (service) => CheckboxListTile(
              title: Text(service.name,
                  style: AppStyles.bodyText1.copyWith(fontSize: 14)),
              subtitle: Text('KES ${service.cost.toStringAsFixed(2)}',
                  style: AppStyles.caption),
              value: service.isSelected,
              onChanged: (bool? value) => _toggleService(service),
              activeColor: AppColors.appBar,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cost Summary:',
            style: AppStyles.regularText
                .copyWith(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          _buildDetailRow('Plot Cost:',
              'KES ${reservation.estimatedCost.toStringAsFixed(2)}'),
          _buildDetailRow('Services Cost:',
              'KES ${_selectedServices.fold<double>(0, (sum, item) => sum + item.cost).toStringAsFixed(2)}'),
          const Divider(thickness: 1, height: 12),
          _buildDetailRow(
            'Total Amount:',
            'KES ${totalCost.toStringAsFixed(2)}',
            isBold: true,
            color: AppColors.spotsAvailable,
            valueFontSize: 16,
          ),
          const SizedBox(height: 16),
          Text(
            'Select Payment Method *:',
            style: AppStyles.regularText
                .copyWith(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          RadioListTile<PaymentMethod>(
            title: const Text('M-Pesa (Simulate)', style: AppStyles.bodyText1),
            value: PaymentMethod.mpesa,
            groupValue: _selectedPaymentMethod,
            onChanged: (PaymentMethod? value) =>
                setState(() => _selectedPaymentMethod = value),
            activeColor: AppColors.appBar,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<PaymentMethod>(
            title: const Text('Card (Simulate)', style: AppStyles.bodyText1),
            value: PaymentMethod.card,
            groupValue: _selectedPaymentMethod,
            onChanged: (PaymentMethod? value) =>
                setState(() => _selectedPaymentMethod = value),
            activeColor: AppColors.appBar,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<PaymentMethod>(
            title: const Text('Bank Transfer (Simulate)',
                style: AppStyles.bodyText1),
            value: PaymentMethod.bank,
            groupValue: _selectedPaymentMethod,
            onChanged: (PaymentMethod? value) =>
                setState(() => _selectedPaymentMethod = value),
            activeColor: AppColors.appBar,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: _isFinalizing
                    ? null
                    : () => setState(() => _completingReservationId = null),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: _isFinalizing
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.verified_user_outlined, size: 20),
                  label:
                      Text(_isFinalizing ? 'PROCESSING...' : 'CONFIRM & PAY'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      foregroundColor: AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  onPressed: _isFinalizing
                      ? null
                      : () => _finalizePayment(reservation),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? color, double valueFontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: AppStyles.bodyText2.copyWith(fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppStyles.bodyText1.copyWith(
                fontSize: valueFontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? AppColors.primaryText,
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
    final days = difference.inDays;
    final hours = twoDigits(difference.inHours.remainder(24));
    final minutes = twoDigits(difference.inMinutes.remainder(60));
    final seconds = twoDigits(difference.inSeconds.remainder(60));
    if (days > 0) return '$days day(s) $hours:$minutes:$seconds';
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Padding(
            padding: AppStyles.pagePadding.copyWith(top: 16.0, bottom: 8.0),
            child: Material(
              elevation: 2.0,
              borderRadius: BorderRadius.circular(25.0),
              child: TextFormField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search by ID, Cemetery, Spot...',
                  hintStyle: AppStyles.bodyText2,
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.secondaryText),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.secondaryText),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                ),
                style: AppStyles.bodyText1,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.appBar))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: AppColors.errorColor, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: AppStyles.titleStyle.copyWith(
                                    color: AppColors.errorColor, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                                onPressed: _fetchReservationsFromSupabase,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.appBar,
                                    foregroundColor: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredReservations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_rounded,
                                    size: 60, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'You have no reservations yet.'
                                      : 'No reservations match your search.',
                                  style: AppStyles.titleStyle.copyWith(
                                      color: AppColors.secondaryText,
                                      fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                if (_searchController.text.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Go to the booking page to make a new reservation.',
                                      style: AppStyles.bodyText1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchReservationsFromSupabase,
                            color: AppColors.appBar,
                            child: ListView.builder(
                              padding: AppStyles.pagePadding.copyWith(
                                  top: 0,
                                  bottom: 16.0,
                                  left: 10.0,
                                  right: 10.0),
                              itemCount: _filteredReservations.length,
                              itemBuilder: (context, index) {
                                final reservation =
                                    _filteredReservations[index];
                                bool isActuallyExpired =
                                    reservation.expiresAt != null &&
                                        DateTime.now()
                                            .isAfter(reservation.expiresAt!);
                                final ReservationStatus displayStatus =
                                    (reservation.status ==
                                                ReservationStatus.approved &&
                                            isActuallyExpired)
                                        ? ReservationStatus.expired
                                        : reservation.status;
                                return Card(
                                  elevation: AppStyles.elevationLow,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: AppStyles.cardBorderRadius),
                                  child: Padding(
                                    padding: AppStyles.cardPadding
                                        .copyWith(bottom: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Reservation #${reservation.id.substring(0, 8)}',
                                                style: AppStyles.cardTitleStyle
                                                    .copyWith(fontSize: 17),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            _buildStatusChip(displayStatus),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _buildDetailRow('Cemetery:',
                                            reservation.cemeteryName),
                                        _buildDetailRow('Spot ID:',
                                            reservation.spaceIdentifier),
                                        _buildDetailRow(
                                            'Plot Type:', reservation.plotType),
                                        _buildDetailRow('Est. Plot Cost:',
                                            'KES ${reservation.estimatedCost.toStringAsFixed(2)}'),
                                        if (reservation.burialPermitNumber !=
                                                null &&
                                            reservation
                                                .burialPermitNumber!.isNotEmpty)
                                          _buildDetailRow('Burial Permit:',
                                              reservation.burialPermitNumber!),
                                        _buildDetailRow(
                                            'Requested:',
                                            _formatDateTime(
                                                reservation.requestedAt)),
                                        if (reservation.approvedAt != null &&
                                            (displayStatus ==
                                                    ReservationStatus
                                                        .approved ||
                                                displayStatus ==
                                                    ReservationStatus
                                                        .paymentPending ||
                                                displayStatus ==
                                                    ReservationStatus
                                                        .completed ||
                                                (displayStatus ==
                                                        ReservationStatus
                                                            .expired &&
                                                    reservation.status ==
                                                        ReservationStatus
                                                            .approved)))
                                          _buildDetailRow(
                                              'Approved/Processed:',
                                              _formatDateTime(
                                                  reservation.approvedAt)),
                                        if (displayStatus ==
                                                ReservationStatus.approved &&
                                            reservation.expiresAt != null &&
                                            !isActuallyExpired)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 6.0, bottom: 4.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.timer_outlined,
                                                    color: Colors.red.shade700,
                                                    size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Expires In: ${_getExpiryCountdown(reservation.expiresAt!)}',
                                                  style: TextStyle(
                                                      color:
                                                          Colors.red.shade700,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (displayStatus ==
                                                ReservationStatus.completed &&
                                            reservation.selectedBurialDate !=
                                                null)
                                          _buildDetailRow(
                                              'Burial Date:',
                                              DateFormat('EEE, MMM dd, yyyy')
                                                  .format(reservation
                                                      .selectedBurialDate!)),
                                        const SizedBox(height: 10),
                                        if (displayStatus ==
                                                ReservationStatus.approved &&
                                            !isActuallyExpired)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              icon: const Icon(
                                                  Icons.edit_calendar_outlined,
                                                  size: 18),
                                              label: Text(
                                                  _completingReservationId ==
                                                          reservation.id
                                                      ? 'Loading Form...'
                                                      : 'Complete Booking'),
                                              onPressed:
                                                  _completingReservationId ==
                                                          reservation.id
                                                      ? null
                                                      : () =>
                                                          _startBookingCompletion(
                                                              reservation),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.appBar,
                                                  foregroundColor:
                                                      Colors.white),
                                            ),
                                          )
                                        else if (displayStatus ==
                                            ReservationStatus.paymentPending)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              icon: const Icon(
                                                  Icons.payment_rounded,
                                                  size: 18),
                                              label: const Text('Make Payment'),
                                              onPressed: () {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Make Payment (Not Implemented)')));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue.shade700,
                                                  foregroundColor:
                                                      Colors.white),
                                            ),
                                          )
                                        else if (displayStatus ==
                                            ReservationStatus.completed)
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Icon(Icons.check_circle_rounded,
                                                    color: AppColors
                                                        .spotsAvailable,
                                                    size: 18),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Booking Completed',
                                                  style: AppStyles.bodyText1
                                                      .copyWith(
                                                          color: AppColors
                                                              .spotsAvailable,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        _buildBookingCompletionSection(
                                            reservation),
                                      ],
                                    ),
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

// --- NEW: Helper widget to simulate the payment process ---
enum _PaymentStatus { processing, success, failure, cancelled }

class PaymentSimulationDialog extends StatefulWidget {
  final PaymentMethod paymentMethod;
  final double totalCost;

  const PaymentSimulationDialog({
    super.key,
    required this.paymentMethod,
    required this.totalCost,
  });

  @override
  State<PaymentSimulationDialog> createState() =>
      _PaymentSimulationDialogState();
}

class _PaymentSimulationDialogState extends State<PaymentSimulationDialog> {
  _PaymentStatus _status = _PaymentStatus.processing;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    // Simulate network delay and processing time
    _simulationTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        // For this demo, we'll always simulate success.
        // You could use `Random().nextBool()` to simulate random failures.
        setState(() {
          _status = _PaymentStatus.success;
        });
      }
    });
  }

  String get _processingMessage {
    switch (widget.paymentMethod) {
      case PaymentMethod.mpesa:
        return 'An STK push has been sent to your phone. Please enter your M-Pesa PIN to authorize the payment of KES ${widget.totalCost.toStringAsFixed(2)}.';
      case PaymentMethod.card:
        return 'Redirecting to secure card payment gateway... Please wait.';
      case PaymentMethod.bank:
        return 'Finalizing bank transfer details. Please follow the instructions shown.';
    }
  }

  Widget _buildProcessingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      key: const ValueKey('processing'),
      children: [
        const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(color: AppColors.appBar)),
        const SizedBox(height: 24),
        Text(
          'Processing Payment...',
          style: AppStyles.titleStyle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          _processingMessage,
          textAlign: TextAlign.center,
          style: AppStyles.bodyText1,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            _simulationTimer?.cancel();
            Navigator.of(context).pop(false); // Pop with a "failure" result
          },
          child: const Text('Cancel Payment',
              style: TextStyle(color: AppColors.errorColor)),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      key: const ValueKey('success'),
      children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: AppColors.spotsAvailable, size: 60),
        const SizedBox(height: 20),
        Text(
          'Payment Successful!',
          style: AppStyles.titleStyle,
        ),
        const SizedBox(height: 12),
        Text(
          'Your booking is confirmed. Thank you for your payment of KES ${widget.totalCost.toStringAsFixed(2)}.',
          textAlign: TextAlign.center,
          style: AppStyles.bodyText1,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.appBar,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 40),
          ),
          onPressed: () =>
              Navigator.of(context).pop(true), // Pop with a "success" result
          child: const Text('Done'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: switch (_status) {
          _PaymentStatus.processing => _buildProcessingView(),
          _PaymentStatus.success => _buildSuccessView(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

enum PaymentMethod { mpesa, card, bank }
