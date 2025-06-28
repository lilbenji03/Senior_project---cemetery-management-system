// lib/screens/admin/manage_reservations_admin_screen.dart
import 'dart:async'; // For StreamSubscription if you add realtime later
import 'dart:math';
import 'package:cmc/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/reservation_model.dart';
import '../../models/space_model.dart'; // UPDATED: For SpaceStatus enum
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';

// final supabase = Supabase.instance.client; // Already globally available or use Supabase.instance.client directly

class ManageReservationsAdminScreen extends StatefulWidget {
  final String? cemeteryId;
  final String? cemeteryName;

  const ManageReservationsAdminScreen({
    super.key,
    this.cemeteryId,
    this.cemeteryName,
    required UserProfile userProfile,
  });

  @override
  State<ManageReservationsAdminScreen> createState() =>
      _ManageReservationsAdminScreenState();
}

class _ManageReservationsAdminScreenState
    extends State<ManageReservationsAdminScreen> {
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _reservationsSubscription;

  // Use ReservationStatus enum for filter state
  ReservationStatus? _selectedFilterStatus =
      ReservationStatus.pendingApproval; // Default filter

  // Generate filter options from the enum
  List<DropdownMenuItem<ReservationStatus?>> _buildFilterOptions() {
    List<DropdownMenuItem<ReservationStatus?>> items = [
      const DropdownMenuItem<ReservationStatus?>(
        value: null, // Represents "All Statuses"
        child: Text("All Statuses"),
      ),
    ];
    items.addAll(
      ReservationStatus.values
          .where(
            (status) => status != ReservationStatus.unknown,
          ) // Exclude unknown from filter
          .map(
            (status) => DropdownMenuItem<ReservationStatus?>(
              value: status,
              child: Text(status.displayName),
            ),
          )
          .toList(),
    );
    return items;
  }

  @override
  void initState() {
    super.initState();
    print(
      "ManageReservationsAdminScreen: initState - Cemetery ID: ${widget.cemeteryId ?? "ALL"}, Name: ${widget.cemeteryName ?? "N/A"}",
    );
    _fetchAdminReservations();
    _subscribeToReservationChanges();
  }

  @override
  void didUpdateWidget(ManageReservationsAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch if the cemetery context changes. Filter changes trigger fetch directly.
    if (widget.cemeteryId != oldWidget.cemeteryId) {
      print(
        "ManageReservationsAdminScreen: didUpdateWidget - Cemetery context changed. Fetching reservations...",
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
      "ManageReservationsAdminScreen: Fetching reservations. Cemetery ID: ${widget.cemeteryId}, Filter Status: ${_selectedFilterStatus?.name ?? 'all'}",
    );

    try {
      var query = Supabase.instance.client.from('reservations').select('''
            id, user_id, cemetery_id, cemetery_space_id, space_identifier, cemetery_name, 
            plot_type, status, requested_at, approved_at, expires_at, 
            estimated_cost, amount_paid, payment_method, payment_reference, payment_date,
            burial_permit_number, selected_burial_date, deceased_name,
            created_at, updated_at,
            profiles ( id, full_name, email, phone_number ),
            cemeteries ( name ), 
            cemetery_spaces ( id, space_identifier, plot_type, status ) 
          '''); // Updated select, ensure fields match Reservation.fromJson

      if (widget.cemeteryId != null) {
        query = query.eq('cemetery_id', widget.cemeteryId!);
      }

      if (_selectedFilterStatus != null) {
        query = query.eq(
          'status',
          _selectedFilterStatus!.toJson(),
        ); // Use enum's toJson
      }

      final response = await query.order('requested_at', ascending: true);
      print(
        "ManageReservationsAdminScreen: Supabase response. Records: ${(response).length}",
      );

      if (mounted) {
        setState(() {
          _reservations =
              (response).map((data) => Reservation.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("ManageReservationsAdminScreen: ERROR fetching: $e");
      if (mounted) {
        setState(() {
          _errorMessage =
              "Failed to load: ${e.toString().substring(0, min(e.toString().length, 150))}";
          _isLoading = false;
          _reservations = [];
        });
      }
    }
  }

// In class _ManageReservationsAdminScreenState

  void _subscribeToReservationChanges() {
    _reservationsSubscription?.cancel(); // Cancel any existing subscription

    // Start with the base stream builder from .stream()
    // This returns a PostgrestStreamBuilder which IS a PostgrestFilterBuilder
    SupabaseStreamFilterBuilder? streamQuery = Supabase.instance.client
        .from('reservations')
        .stream(primaryKey: ['id']);

    // Conditionally apply filters by reassigning the streamQuery variable
    if (widget.cemeteryId != null) {
      // .eq() is available on PostgrestFilterBuilder (which PostgrestStreamBuilder is)
      // and returns PostgrestFilterBuilder, so this chaining is correct.
      streamQuery = streamQuery.eq('cemetery_id', widget.cemeteryId!)
          as SupabaseStreamFilterBuilder?;
    }

    // Add other stream filters similarly if needed:
    // if (_someOtherStreamFilterCondition) {
    //   streamQuery = streamQuery.lt('some_column', someValue); // Reassign again
    // }

    // Finally, listen to the configured streamQuery.
    // Ordering on the stream for individual change events is not as reliable as ordering a full query.
    // It's better to rely on _fetchAdminReservations for ordered data.
    _reservationsSubscription = streamQuery!
        // .order('requested_at', ascending: true) // Generally omit order on the stream itself for individual events
        .listen(
      (List<Map<String, dynamic>> data) {
        print(
            "ManageReservationsAdminScreen: Stream received ${data.length} updates. Refetching for consistency with filters.");
        if (mounted) {
          // Refetch to apply all current server-side filters and ordering
          _fetchAdminReservations();
        }
      },
      onError: (error, s) {
        // Added stacktrace
        if (mounted) {
          print("Reservations stream error: $error");
          print("Stacktrace for reservations stream error: $s");
        }
      },
    );
  }

  Future<void> _updateReservationAndAssociatedSpace(
    String reservationId,
    ReservationStatus newReservationStatus,
    String cemeterySpacePk, // This is the PK (id) of the cemetery_spaces record
    SpaceStatus newSpaceEnumStatus, // Use SpaceStatus enum
  ) async {
    if (!mounted) return;
    // Consider showing a confirmation dialog before critical actions like reject/approve
    setState(
      () => _isLoading = true,
    ); // Indicate loading for this specific operation
    try {
      final Map<String, dynamic> reservationUpdateData = {
        'status': newReservationStatus.toJson(),
        'updated_at':
            DateTime.now().toIso8601String(), // If DB doesn't auto-update
      };

      if (newReservationStatus == ReservationStatus.approved) {
        reservationUpdateData['approved_at'] = DateTime.now().toIso8601String();
        // Expiry logic might be more complex (e.g., based on cemetery settings)
        reservationUpdateData['expires_at'] =
            DateTime.now().add(const Duration(days: 7)).toIso8601String();
      } else if (newReservationStatus == ReservationStatus.rejected ||
          newReservationStatus == ReservationStatus.cancelledByAdmin) {
        reservationUpdateData['approved_at'] = null; // Clear approval info
        reservationUpdateData['expires_at'] = null; // Clear expiry
      }

      // Use a transaction if your backend supports it for atomicity,
      // or handle potential partial failures carefully.
      // For Supabase, you can use an RPC function to do this atomically.
      // Here, we do sequential updates:

      // 1. Update Reservation
      await Supabase.instance.client
          .from('reservations')
          .update(reservationUpdateData)
          .eq('id', reservationId);

      // 2. Update Cemetery Space status
      await Supabase.instance.client
          .from('cemetery_spaces') // UPDATED table name
          .update({
        'status': newSpaceEnumStatus.toJson(),
      }) // UPDATED to use enum.toJson()
          .eq('id', cemeterySpacePk);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reservation ${newReservationStatus.displayName.toLowerCase()}!',
            ), // Use displayName
            backgroundColor:
                AppColors.statusApproved, // Or a color based on success/failure
          ),
        );
        // Data will be refreshed by the stream listener calling _fetchAdminReservations()
        // Or call explicitly if stream is not setup for this detail:
        // _fetchAdminReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted)
        setState(() => _isLoading = false); // Stop loading for this operation
    }
  }

  String _formatDateTime(DateTime? dt) => dt == null
      ? 'N/A'
      : DateFormat(
          'MMM d, yyyy, hh:mm a',
        ).format(dt.toLocal()); // Use toLocal()

  Widget _buildStatusChip(ReservationStatus status) {
    Color chipColor;
    Color textColor = Colors.white; // Default for darker chips

    switch (status) {
      case ReservationStatus.pendingApproval:
        chipColor = AppColors.statusPending; // Orange
        textColor = Colors.black87; // Darker text for lighter orange
        break;
      case ReservationStatus.approved:
        chipColor = AppColors.statusApproved; // Green
        break;
      case ReservationStatus.rejected:
        chipColor = AppColors.statusRejected; // Red
        break;
      case ReservationStatus.completed:
        chipColor = AppColors.statusCompleted; // Blue
        break;
      case ReservationStatus.expired:
        chipColor = AppColors.statusExpired; // Grey
        textColor = Colors.black87;
        break;
      case ReservationStatus.paymentPending:
        chipColor = Colors.blueAccent; // Example
        break;
      case ReservationStatus.cancelledByUser:
      case ReservationStatus.cancelledByAdmin:
        chipColor = Colors.grey.shade600;
        break;
      case ReservationStatus.unknown:
      default:
        chipColor = Colors.grey.shade400;
        textColor = Colors.black87;
        break;
    }
    return Chip(
      label: Text(
        status.displayName
            .toUpperCase(), // Use displayName, make it uppercase for chip style
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(
        horizontal: 4.0,
      ), // Adjust padding within chip
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showReservationDetailsDialog(Reservation reservation) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Reservation Details (#${reservation.id.substring(0, 8)})",
          ), // More context
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.cardBorderRadius,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _detailDialogRow("Cemetery:", reservation.cemeteryName),
                _detailDialogRow(
                  "Space ID:",
                  reservation.spaceIdentifier,
                ), // UPDATED
                _detailDialogRow("Plot Type:", reservation.plotType),
                _detailDialogRow(
                  "User:",
                  reservation.userFullName ?? reservation.userEmail ?? "N/A",
                ),
                if (reservation.userPhoneNumber != null)
                  _detailDialogRow("User Phone:", reservation.userPhoneNumber!),
                _detailDialogRow(
                  "Requested:",
                  _formatDateTime(reservation.requestedAt),
                ),
                if (reservation.approvedAt != null)
                  _detailDialogRow(
                    "Approved:",
                    _formatDateTime(reservation.approvedAt),
                  ),
                if (reservation.expiresAt != null &&
                    (reservation.status == ReservationStatus.approved ||
                        reservation.status == ReservationStatus.paymentPending))
                  _detailDialogRow(
                    "Expires/Payment Due:",
                    _formatDateTime(reservation.expiresAt),
                  ),
                _detailDialogRow(
                  "Status:",
                  reservation.status.displayName,
                ), // Use displayName
                _detailDialogRow(
                  "Est. Cost:",
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
                    "Burial Date:",
                    DateFormat(
                      'MMM dd, yyyy',
                    ).format(reservation.selectedBurialDate!),
                  ),
                if (reservation.deceasedName != null &&
                    reservation.deceasedName!.isNotEmpty)
                  _detailDialogRow("Deceased:", reservation.deceasedName!),
                if (reservation.amountPaid != null)
                  _detailDialogRow(
                    "Amount Paid:",
                    "KES ${reservation.amountPaid!.toStringAsFixed(2)}",
                  ),
                if (reservation.paymentMethodUsed != null &&
                    reservation.paymentMethodUsed != PaymentMethod.unknown)
                  _detailDialogRow(
                    "Payment Method:",
                    reservation.paymentMethodUsed!.displayName,
                  ),
                if (reservation.paymentReference != null)
                  _detailDialogRow(
                    "Payment Ref:",
                    reservation.paymentReference!,
                  ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            if (reservation.status == ReservationStatus.pendingApproval ||
                reservation.status == ReservationStatus.paymentPending) ...[
              TextButton(
                child: const Text(
                  "Approve",
                  style: TextStyle(color: AppColors.statusApproved),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _updateReservationAndAssociatedSpace(
                    reservation.id,
                    ReservationStatus.approved,
                    reservation.cemeterySpaceId, // Pass the actual space PK
                    SpaceStatus.booked, // Set space to booked
                  );
                },
              ),
              TextButton(
                child: const Text(
                  "Reject",
                  style: TextStyle(color: AppColors.statusRejected),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _updateReservationAndAssociatedSpace(
                    reservation.id,
                    ReservationStatus.rejected,
                    reservation.cemeterySpaceId, // Pass the actual space PK
                    SpaceStatus.available, // Make space available again
                  );
                },
              ),
            ],
            // Add more actions like "Mark as Paid", "Cancel Reservation (Admin)"
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                "Close",
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0), // Increased padding
      child: Row(
        // Use Row for better alignment
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2, // Adjust flex for label width
            child: Text(
              "$label ",
              style: AppStyles.bodyText2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            flex: 3, // Adjust flex for value width
            child: Text(
              value,
              style: AppStyles.bodyText1.copyWith(color: AppColors.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reservationsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppStyles.pagePadding.copyWith(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<ReservationStatus?>(
            decoration: InputDecoration(
              labelText: 'Filter by Status',
              border: OutlineInputBorder(
                borderRadius: AppStyles.buttonBorderRadius,
              ),
              isDense: true,
              prefixIcon: const Icon(Icons.filter_list_alt, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            value: _selectedFilterStatus,
            items: _buildFilterOptions(),
            onChanged: (ReservationStatus? newValue) {
              setState(() => _selectedFilterStatus = newValue);
              _fetchAdminReservations(); // Refetch with the new filter
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.appBar),
                  )
                : _errorMessage != null
                    ? Center(/* ... error message ... */)
                    : _reservations.isEmpty
                        ? Center(/* ... no reservations found message ... */)
                        : RefreshIndicator(
                            onRefresh: _fetchAdminReservations,
                            color: AppColors.appBar,
                            child: ListView.builder(
                              itemCount: _reservations.length,
                              itemBuilder: (context, index) {
                                final res = _reservations[index];
                                final userIdentifier = res.userFullName ??
                                    res.userEmail ??
                                    res.userId.substring(0, 8);
                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: 10.0,
                                  ), // Increased bottom margin
                                  elevation: AppStyles.elevationLow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppStyles.cardBorderRadius,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppColors.appBar.withOpacity(
                                        0.1,
                                      ),
                                      child: Text(
                                        (index + 1).toString(),
                                        style: TextStyle(
                                          color: AppColors.appBar,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      'Space: ${res.spaceIdentifier} (Ref: ${res.id.substring(0, 6)})', // UPDATED
                                      style: AppStyles.cardTitleStyle.copyWith(
                                        color: AppColors.primaryText,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'User: $userIdentifier',
                                            style: AppStyles.bodyText2,
                                          ),
                                          Text(
                                            'Cemetery: ${res.cemeteryName}',
                                            style: AppStyles.bodyText2,
                                          ),
                                          Text(
                                            'Requested: ${_formatDateTime(res.requestedAt)}',
                                            style: AppStyles.caption.copyWith(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    isThreeLine:
                                        true, // Auto adjusts based on content
                                    trailing: _buildStatusChip(res.status),
                                    onTap: () =>
                                        _showReservationDetailsDialog(res),
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

// Keep StringExtension if used elsewhere, or remove if only for this file and not needed
// extension StringExtension on String {
//   String capitalizeFirst() {
//     if (isEmpty) return this;
//     return "${this[0].toUpperCase()}${substring(1)}";
//   }
// }
