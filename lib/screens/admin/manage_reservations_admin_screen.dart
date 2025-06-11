// lib/screens/admin/manage_reservations_admin_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/reservation_model.dart'; // Uses the main app's Reservation model
import '../../models/spot_model.dart'; // For SpotStatus enum
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';

final supabase = Supabase.instance.client;

class ManageReservationsAdminScreen extends StatefulWidget {
  final String? cemeteryId; // Nullable for system_super_admin to view all
  final String? cemeteryName;

  const ManageReservationsAdminScreen({
    super.key,
    this.cemeteryId,
    this.cemeteryName,
  });

  @override
  State<ManageReservationsAdminScreen> createState() =>
      _ManageReservationsAdminScreenState();
}

class _ManageReservationsAdminScreenState
    extends State<ManageReservationsAdminScreen> {
  List<Reservation> _reservations = []; // Uses the main Reservation model
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'pendingApproval';

  final List<Map<String, String>> _statusFilterOptions = [
    {'value': 'all', 'display': 'All Statuses'},
    {'value': 'pendingApproval', 'display': 'Pending Approval'},
    {'value': 'approved', 'display': 'Approved'},
    {'value': 'paymentPending', 'display': 'Payment Pending'},
    {'value': 'completed', 'display': 'Completed'},
    {'value': 'rejected', 'display': 'Rejected'},
    {'value': 'expired', 'display': 'Expired'},
    {'value': 'cancelled', 'display': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    print(
      "ManageReservationsAdminScreen: initState - Cemetery ID: ${widget.cemeteryId ?? "ALL"}, Name: ${widget.cemeteryName ?? "N/A"}",
    );
    _fetchAdminReservations();
  }

  @override
  void didUpdateWidget(ManageReservationsAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cemeteryId != oldWidget.cemeteryId ||
        _filterStatus != _filterStatus) {
      print(
        "ManageReservationsAdminScreen: didUpdateWidget - Context changed. Fetching reservations...",
      );
      _fetchAdminReservations();
    }
  }

  Future<void> _fetchAdminReservations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print(
      "ManageReservationsAdminScreen: Fetching reservations. Cemetery ID: ${widget.cemeteryId}, Filter Status: $_filterStatus",
    );

    try {
      var query = supabase.from('reservations').select('''
            id, user_id, cemetery_id, cemetery_spot_id, spot_identifier, cemetery_name, 
            plot_type, status, requested_at, approved_at, expires_at, 
            estimated_plot_cost, final_total_cost, payment_method, 
            burial_permit_number, selected_burial_date, deceased_name,
            profiles (id, full_name, email) 
          ''');

      if (widget.cemeteryId != null) {
        query = query.eq(
          'cemetery_id',
          widget.cemeteryId!,
        ); // query is now PostgrestFilterBuilder
      }

      if (_filterStatus != 'all') {
        query = query.eq(
          'status',
          _filterStatus,
        ); // query is still PostgrestFilterBuilder
      }

      // Now, when you call .order(), you are not assigning back to 'query' before awaiting.
      // Instead, the result of the whole chain (which is awaitable) is directly used.
      final response = await query.order('requested_at', ascending: true);

      print(
        "ManageReservationsAdminScreen: Supabase response. Records: ${(response as List).length}",
      );

      if (mounted) {
        setState(() {
          _reservations =
              (response as List)
                  .map((data) => Reservation.fromJson(data))
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("ManageReservationsAdminScreen: ERROR fetching: $e");
      if (mounted) {
        setState(() {
          _errorMessage =
              "Failed to load: ${e.toString().substring(0, min(e.toString().length, 100))}";
          _isLoading = false;
          _reservations = [];
        });
      }
    }
  }

  Future<void> _updateReservationAndAssociatedSpot(
    String reservationId,
    ReservationStatus newReservationStatus,
    String cemeterySpotPk,
    SpotStatus newSpotEnumStatus, // Use SpotStatus enum
  ) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> reservationUpdateData = {
        'status':
            newReservationStatus.name, // enum.name gives "pendingApproval"
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newReservationStatus == ReservationStatus.approved) {
        reservationUpdateData['approved_at'] = DateTime.now().toIso8601String();
        reservationUpdateData['expires_at'] =
            DateTime.now().add(const Duration(days: 7)).toIso8601String();
      } else {
        reservationUpdateData['approved_at'] = null;
        reservationUpdateData['expires_at'] = null;
      }
      await supabase
          .from('reservations')
          .update(reservationUpdateData)
          .eq('id', reservationId);
      await supabase
          .from('cemetery_spots')
          .update({'status': newSpotEnumStatus.name})
          .eq('id', cemeterySpotPk);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reservation ${newReservationStatus.name.capitalizeFirst()}!',
            ),
            backgroundColor: AppColors.spotsAvailable,
          ),
        );
        _fetchAdminReservations();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime? dt) =>
      dt == null ? 'N/A' : DateFormat('MMM d, yyyy hh:mm a').format(dt);

  Widget _buildStatusChip(ReservationStatus status) {
    // ... (Your existing _buildStatusChip is fine, ensure AppColors.status... are defined) ...
    String text;
    Color chipColor;
    Color textColor = Colors.white;
    switch (status) {
      case ReservationStatus.pendingApproval:
        text = 'PENDING';
        chipColor = AppColors.statusPending;
        break;
      case ReservationStatus.approved:
        text = 'APPROVED';
        chipColor = AppColors.statusApproved;
        break;
      case ReservationStatus.rejected:
        text = 'REJECTED';
        chipColor = AppColors.statusRejected;
        break;
      case ReservationStatus.completed:
        text = 'COMPLETED';
        chipColor = AppColors.statusCompleted;
        break;
      case ReservationStatus.expired:
        text = 'EXPIRED';
        chipColor = AppColors.statusExpired;
        break;
      case ReservationStatus.paymentPending:
        text = 'PAYMENT DUE';
        chipColor = Colors.blueAccent;
        break;
      case ReservationStatus.cancelled:
        text = 'CANCELLED';
        chipColor = Colors.grey.shade600;
        break;
    }
    return Chip(
      label: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showReservationDetailsDialog(Reservation reservation) {
    // Uses main Reservation model
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Reservation: #${reservation.id.substring(0, 8)}"),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.cardBorderRadius,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _detailDialogRow("Spot ID:", reservation.spotIdentifier),
                _detailDialogRow("Plot Type:", reservation.plotType),
                _detailDialogRow("Cemetery:", reservation.cemeteryName),
                _detailDialogRow(
                  "User:",
                  reservation.userFullName ?? reservation.userEmail ?? "N/A",
                ),
                _detailDialogRow(
                  "Requested On:",
                  _formatDateTime(reservation.requestedAt),
                ),
                if (reservation.approvedAt != null)
                  _detailDialogRow(
                    "Approved On:",
                    _formatDateTime(reservation.approvedAt),
                  ),
                if (reservation.expiresAt != null &&
                    reservation.status == ReservationStatus.approved)
                  _detailDialogRow(
                    "Payment Expires:",
                    _formatDateTime(reservation.expiresAt),
                  ),
                _detailDialogRow(
                  "Current Status:",
                  reservation.status.name.capitalizeFirst(),
                ),
                _detailDialogRow(
                  "Plot Cost:",
                  "KES ${reservation.estimatedCost.toStringAsFixed(2)}",
                ),
                if (reservation.burialPermitNumber != null &&
                    reservation.burialPermitNumber!.isNotEmpty)
                  _detailDialogRow(
                    "Permit #:",
                    reservation.burialPermitNumber!,
                  ),
                if (reservation.selectedBurialDate != null)
                  _detailDialogRow(
                    "Selected Burial Date:",
                    DateFormat(
                      'MMM dd, yyyy',
                    ).format(reservation.selectedBurialDate!),
                  ),
                if (reservation.deceasedName != null &&
                    reservation.deceasedName!.isNotEmpty)
                  _detailDialogRow("Deceased Name:", reservation.deceasedName!),
              ],
            ),
          ),
          actions: <Widget>[
            if (reservation.status == ReservationStatus.pendingApproval) ...[
              TextButton(
                child: const Text(
                  "Approve",
                  style: TextStyle(color: AppColors.statusApproved),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _updateReservationAndAssociatedSpot(
                    reservation.id,
                    ReservationStatus.approved,
                    reservation.cemeterySpotId,
                    SpotStatus.booked,
                  ); // Pass SpotStatus enum
                },
              ),
              TextButton(
                child: const Text(
                  "Reject",
                  style: TextStyle(color: AppColors.statusRejected),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _updateReservationAndAssociatedSpot(
                    reservation.id,
                    ReservationStatus.rejected,
                    reservation.cemeterySpotId,
                    SpotStatus.available,
                  ); // Pass SpotStatus enum
                },
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: AppStyles.bodyText1.copyWith(fontSize: 14),
          children: [
            TextSpan(
              text: "$label ",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppColors.primaryText),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppStyles.pagePadding.copyWith(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Filter Status',
              border: OutlineInputBorder(
                borderRadius: AppStyles.buttonBorderRadius,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            value: _filterStatus,
            items:
                _statusFilterOptions.map((filter) {
                  return DropdownMenuItem<String>(
                    value: filter['value']!,
                    child: Text(filter['display']!, style: AppStyles.bodyText1),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _filterStatus = newValue);
                _fetchAdminReservations();
              }
            },
          ),
          const SizedBox(height: 12),
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
                    : _reservations.isEmpty
                    ? Center(
                      child: Text(
                        'No reservations found for "${_statusFilterOptions.firstWhere((f) => f['value'] == _filterStatus, orElse: () => {'display': 'this'})['display']}" status.',
                        style: AppStyles.cardTitleStyle.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchAdminReservations,
                      color: AppColors.appBar,
                      child: ListView.builder(
                        itemCount: _reservations.length,
                        itemBuilder: (context, index) {
                          final res = _reservations[index];
                          final userIdentifier =
                              res.userFullName ??
                              res.userEmail ??
                              res.userId.substring(0, 8);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            elevation: AppStyles.elevationLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppStyles.cardBorderRadius,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              title: Text(
                                'Spot: ${res.spotIdentifier} (Res#: ${res.id.substring(0, 6)}..)',
                                style: AppStyles.cardTitleStyle.copyWith(
                                  color: AppColors.primaryText,
                                ),
                              ),
                              subtitle: Text(
                                'User: $userIdentifier\nCemetery: ${res.cemeteryName}\nRequested: ${_formatDateTime(res.requestedAt)}',
                                style: AppStyles.bodyText2.copyWith(
                                  height: 1.3,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              isThreeLine: true,
                              trailing: _buildStatusChip(res.status),
                              onTap: () => _showReservationDetailsDialog(res),
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

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
