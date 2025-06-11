import 'dart:async';
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

  String? _completingReservationId;
  DateTime? _selectedBurialDate;
  List<CemeteryService> _availableServices = [];
  List<CemeteryService> _selectedServices = [];
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.mpesa;

  @override
  void initState() {
    super.initState();
    _fetchReservationsFromSupabase();
    _availableServices = getSampleCemeteryServices();
    _searchController.addListener(_onSearchChanged);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted &&
          _filteredReservations.any(
            (res) =>
                res.status == ReservationStatus.approved &&
                res.expiresAt != null &&
                DateTime.now().isBefore(res.expiresAt!),
          )) {
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

  Future<void> _fetchReservationsFromSupabase() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _allReservations = [];
            _filteredReservations = [];
            _isLoading = false;
          });
        }
        return;
      }
      final List<dynamic> response = await supabase
          .from('reservations')
          .select(
            '*, cemetery_spots (spot_identifier)',
          ) // Assuming spot_identifier is in cemetery_spots
          .eq('user_id', userId)
          .order('requested_at', ascending: false);
      if (mounted) {
        setState(() {
          _allReservations =
              response.map((data) => Reservation.fromJson(data)).toList();
          _allReservations.sort(
            (a, b) => b.requestedAt.compareTo(a.requestedAt),
          );
          _filteredReservations = _allReservations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load your reservations: ${e.toString()}";
          _isLoading = false;
          _allReservations = [];
          _filteredReservations = [];
        });
      }
    }
  }

  void _onSearchChanged() {
    _filterReservations();
    if (mounted) setState(() {});
  }

  void _filterReservations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredReservations = _allReservations;
      } else {
        _filteredReservations =
            _allReservations.where((r) {
              return r.id.toLowerCase().contains(query) ||
                  r.cemeteryName.toLowerCase().contains(query) ||
                  r.spotIdentifier.toLowerCase().contains(
                    query,
                  ) || // <--- CORRECTED: Was spotId
                  (r.burialPermitNumber?.toLowerCase().contains(query) ??
                      false);
            }).toList();
      }
    });
  }

  void _clearSearch() {
    if (!_searchFocusNode.hasFocus && mounted) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    }
    _searchController.clear();
  }

  String _formatDateTime(DateTime? dt) =>
      dt == null ? 'N/A' : DateFormat('MMM dd, yyyy - hh:mm a').format(dt);

  Widget _buildStatusChip(ReservationStatus status) {
    String text;
    Color backgroundColor;
    Color textColor = Colors.white;
    switch (status) {
      case ReservationStatus.pendingApproval:
        text = 'Pending';
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
        text = 'Payment Due';
        backgroundColor = Colors.blue.shade700;
        break;
      case ReservationStatus.completed:
        text = 'Completed';
        backgroundColor = AppColors.appBar;
        break;
      case ReservationStatus.cancelled:
        text = 'Cancelled';
        backgroundColor = Colors.grey.shade700;
        break;
    }
    return Chip(
      label: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: 6.0,
        vertical: 1.0,
      ), // This padding is fine
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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

  Future<void> _finalizePayment(Reservation reservation) async {
    if (_selectedBurialDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a burial date.')),
        );
      }
      return;
    }
    final totalCost = _calculateTotalCost(reservation);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('reservations')
          .update({
            'status': 'completed',
            'selected_burial_date': _selectedBurialDate!.toIso8601String(),
            'final_total_cost': totalCost,
            'payment_method': _selectedPaymentMethod.toString().split('.').last,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reservation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking completed for KES ${totalCost.toStringAsFixed(2)} via ${_selectedPaymentMethod.toString().split('.').last} for reservation ${reservation.id.substring(0, 6)}...',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.spotsAvailable,
          ),
        );
        _fetchReservationsFromSupabase();
        setState(() => _completingReservationId = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finalizing booking: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBookingCompletionSection(Reservation reservation) {
    if (_completingReservationId != reservation.id) {
      return const SizedBox.shrink();
    }
    double totalCost = _calculateTotalCost(reservation);
    return Container(
      /* ... your existing UI ... */
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
            'Complete Your Booking for Spot ${reservation.spotIdentifier}',
            style: AppStyles.cardTitleStyle.copyWith(fontSize: 15),
          ),
          const Divider(), // <--- CORRECTED: spotIdentifier
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
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Padding(
            padding: AppStyles.pagePadding.copyWith(top: 16.0, bottom: 12.0),
            child: Material(/* ... Search Bar UI ... */),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: AppColors.appBar),
                    )
                    : _errorMessage != null
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: AppStyles.bodyText1.copyWith(
                            color: AppColors.errorColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : _filteredReservations.isEmpty
                    ? Center(/* ... No reservations UI ... */)
                    : RefreshIndicator(
                      onRefresh: _fetchReservationsFromSupabase,
                      color: AppColors.appBar,
                      child: ListView.builder(
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
                              (reservation.status ==
                                          ReservationStatus.approved &&
                                      isActuallyExpired)
                                  ? ReservationStatus.expired
                                  : reservation.status;
                          return Card(
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
                                          'Reservation #${reservation.id.substring(0, 8)}...',
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
                                  _buildDetailRow(
                                    'Spot ID:',
                                    reservation.spotIdentifier,
                                  ), // <--- CORRECTED: Was spotId
                                  _buildDetailRow(
                                    'Plot Type:',
                                    reservation.plotType,
                                  ),
                                  _buildDetailRow(
                                    'Est. Plot Cost:',
                                    'KES ${reservation.estimatedCost.toStringAsFixed(2)}',
                                  ),
                                  if (reservation.burialPermitNumber != null &&
                                      reservation
                                          .burialPermitNumber!
                                          .isNotEmpty)
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
                                        onPressed: () {},
                                        child: const Text(
                                          'View Payment Details',
                                        ),
                                      ),
                                    )
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
                                  // ... other status specific UI ...
                                  _buildBookingCompletionSection(reservation),
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
