import 'dart:async';
import 'package:cmc/models/admin_reservation_model.dart';
import 'package:cmc/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/reservation_model.dart'; // Still needed for Enums
import '../../models/space_model.dart'; // Still needed for Enums
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';

class ManageReservationsAdminScreen extends StatefulWidget {
  final String? cemeteryId;
  final String? cemeteryName;
  final UserProfile userProfile;

  const ManageReservationsAdminScreen({
    super.key,
    this.cemeteryId,
    this.cemeteryName,
    required this.userProfile,
  });

  @override
  State<ManageReservationsAdminScreen> createState() =>
      _ManageReservationsAdminScreenState();
}

class _ManageReservationsAdminScreenState
    extends State<ManageReservationsAdminScreen> {
  List<AdminReservationModel> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _reservationsSubscription;

  ReservationStatus? _selectedFilterStatus = ReservationStatus.pendingApproval;

  List<DropdownMenuItem<ReservationStatus?>> _buildFilterOptions() {
    List<DropdownMenuItem<ReservationStatus?>> items = [
      const DropdownMenuItem<ReservationStatus?>(
        value: null,
        child: Text("All Statuses"),
      ),
    ];
    items.addAll(
      ReservationStatus.values
          .where((status) => status != ReservationStatus.unknown)
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
    _handleCemeteryChange();
  }

  @override
  void didUpdateWidget(ManageReservationsAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cemeteryId != oldWidget.cemeteryId) {
      _handleCemeteryChange();
    }
  }

  @override
  void dispose() {
    _reservationsSubscription?.cancel();
    _reservationsSubscription = null;
    super.dispose();
  }

  /// Handles logic when the cemetery ID changes, acting as the main coordinator.
  void _handleCemeteryChange() {
    _reservationsSubscription?.cancel();
    _reservationsSubscription = null;

    if (widget.cemeteryId != null) {
      // Perform the initial data load and then subscribe to future changes.
      _fetchAndSubscribe();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "No cemetery assigned to this manager account.";
        _reservations = [];
      });
    }
  }

  /// Helper to coordinate the initial fetch (with a loader) and then subscribe to real-time updates.
  Future<void> _fetchAndSubscribe() async {
    // Fetch with a loading indicator.
    await _fetchAdminReservations(showLoadingIndicator: true);

    // After the initial fetch, subscribe to real-time updates if we're still on the screen
    // and the fetch was successful.
    if (mounted && _errorMessage == null) {
      _subscribeToReservationChanges();
    }
  }

  /// --- THIS IS THE CORRECTED METHOD ---
  /// Fetches reservation data from the database.
  /// The [showLoadingIndicator] flag prevents the UI from flashing a loading
  /// spinner during background refreshes triggered by real-time events.
  Future<void> _fetchAdminReservations(
      {bool showLoadingIndicator = true}) async {
    if (!mounted || widget.cemeteryId == null) return;

    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      var query = Supabase.instance.client
          .from('detailed_reservations')
          .select('*')
          // FIX: Removed the erroneous space between 'widget.c' and 'cemeteryId'
          .eq('cemetery_id', widget.cemeteryId!);

      if (_selectedFilterStatus != null) {
        query = query.eq('status', _selectedFilterStatus!.name);
      }

      final response = await query.order('requested_at', ascending: true);

      if (mounted) {
        setState(() {
          _reservations = (response as List)
              .map((data) => AdminReservationModel.fromJson(data))
              .toList();
          // Always set isLoading to false after a fetch completes.
          _isLoading = false;
          // Clear any previous error on a successful fetch.
          if (showLoadingIndicator) _errorMessage = null;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Database Error: ${e.message}.";
          _isLoading = false;
          _reservations = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "An error occurred: ${e.toString()}";
          _isLoading = false;
          _reservations = [];
        });
      }
    }
  }

  /// Subscribes to changes in the 'reservations' table for the current cemetery.
  void _subscribeToReservationChanges() {
    // Ensure we don't have duplicate subscriptions.
    _reservationsSubscription?.cancel();
    if (!mounted || widget.cemeteryId == null) return;

    _reservationsSubscription = Supabase.instance.client
        .from('reservations')
        .stream(primaryKey: ['id'])
        // Filter the stream to only get updates for the relevant cemetery.
        .eq('cemetery_id', widget.cemeteryId!)
        .listen(
          (data) {
            if (mounted) {
              // When a change happens, refetch silently from the VIEW.
              // This updates the list without showing a disruptive loading spinner.
              _fetchAdminReservations(showLoadingIndicator: false);
            }
          },
          onError: (e) {
            if (mounted) {
              print("Reservations Realtime Error: $e");
              // Optionally show a non-blocking error, e.g., a SnackBar.
            }
          },
        );
  }

  void _showConfirmationDialog({
    required BuildContext parentContext,
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
          title: Text(title, style: AppStyles.titleStyle),
          content: Text(content, style: AppStyles.bodyText1),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: AppStyles.bodyText2),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppStyles.buttonBorderRadius)),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateReservationAndAssociatedSpace({
    required String reservationId,
    required ReservationStatus newReservationStatus,
    required SpaceStatus newSpaceStatus,
  }) async {
    if (!mounted) return;
    try {
      await Supabase.instance.client.rpc('manage_reservation_status', params: {
        'p_reservation_id': reservationId,
        'p_new_reservation_status': newReservationStatus.name,
        'p_new_space_status': newSpaceStatus.name
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reservation ${newReservationStatus.displayName.toLowerCase()} successfully!',
            ),
            backgroundColor: AppColors.statusApproved,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime? dt) => dt == null
      ? 'N/A'
      : DateFormat('MMM d, yyyy, hh:mm a').format(dt.toLocal());

  Widget _buildStatusChip(ReservationStatus status) {
    Color chipColor;
    Color textColor = Colors.white;
    switch (status) {
      case ReservationStatus.pendingApproval:
        chipColor = AppColors.statusPending;
        textColor = Colors.black87;
        break;
      case ReservationStatus.approved:
        chipColor = AppColors.statusApproved;
        break;
      case ReservationStatus.rejected:
      case ReservationStatus.cancelledByAdmin:
        chipColor = AppColors.statusRejected;
        break;
      case ReservationStatus.completed:
        chipColor = AppColors.statusCompleted;
        break;
      case ReservationStatus.expired:
        chipColor = AppColors.statusExpired;
        textColor = Colors.black87;
        break;
      case ReservationStatus.paymentPending:
        chipColor = Colors.blueAccent;
        break;
      case ReservationStatus.cancelledByUser:
        chipColor = Colors.grey.shade600;
        break;
      default:
        chipColor = Colors.grey.shade400;
        textColor = Colors.black87;
        break;
    }
    return Chip(
      label: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
            color: textColor, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showReservationDetailsDialog(AdminReservationModel reservation) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Details for #${reservation.id.substring(0, 8)}"),
          shape:
              RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _detailDialogRow("Cemetery:", reservation.cemeteryName),
                _detailDialogRow("Space ID:", reservation.spaceIdentifier),
                _detailDialogRow("Plot Type:", reservation.plotType),
                _detailDialogRow("User:",
                    reservation.userFullName ?? reservation.userEmail ?? "N/A"),
                if (reservation.userPhoneNumber != null)
                  _detailDialogRow("User Phone:", reservation.userPhoneNumber!),
                _detailDialogRow(
                    "Requested:", _formatDateTime(reservation.requestedAt)),
                _detailDialogRow("Status:", reservation.status.displayName),
                if (reservation.approvedAt != null)
                  _detailDialogRow(
                      "Approved:", _formatDateTime(reservation.approvedAt)),
                if (reservation.expiresAt != null &&
                    (reservation.status == ReservationStatus.approved ||
                        reservation.status == ReservationStatus.paymentPending))
                  _detailDialogRow(
                      "Expires:", _formatDateTime(reservation.expiresAt)),
                _detailDialogRow("Est. Cost:",
                    "KES ${reservation.estimatedCost.toStringAsFixed(2)}"),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            if (reservation.status == ReservationStatus.pendingApproval) ...[
              TextButton(
                child: const Text("Approve",
                    style: TextStyle(color: AppColors.statusApproved)),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _showConfirmationDialog(
                    parentContext: context,
                    title: 'Approve Reservation?',
                    content:
                        'This will approve the reservation and mark the space as booked. Continue?',
                    confirmText: 'Approve',
                    confirmColor: AppColors.statusApproved,
                    onConfirm: () => _updateReservationAndAssociatedSpace(
                      reservationId: reservation.id,
                      newReservationStatus: ReservationStatus.approved,
                      newSpaceStatus: SpaceStatus.booked,
                    ),
                  );
                },
              ),
              TextButton(
                child: const Text("Reject",
                    style: TextStyle(color: AppColors.statusRejected)),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _showConfirmationDialog(
                    parentContext: context,
                    title: 'Reject Reservation?',
                    content:
                        'This will reject the reservation and make the space available again. Continue?',
                    confirmText: 'Reject',
                    confirmColor: AppColors.statusRejected,
                    onConfirm: () => _updateReservationAndAssociatedSpace(
                      reservationId: reservation.id,
                      newReservationStatus: ReservationStatus.rejected,
                      newSpaceStatus: SpaceStatus.available,
                    ),
                  );
                },
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Close",
                  style: TextStyle(color: AppColors.secondaryText)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text("$label ",
                style:
                    AppStyles.bodyText2.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: AppStyles.bodyText1),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.appBar));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppStyles.titleStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                // On retry, re-fetch and re-subscribe
                onPressed: _fetchAndSubscribe,
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.appBar),
              )
            ],
          ),
        ),
      );
    }
    if (_reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined,
                color: AppColors.secondaryText, size: 60),
            const SizedBox(height: 16),
            Text('No Reservations Found', style: AppStyles.titleStyle),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'There are no reservations for ${widget.cemeteryName ?? 'this cemetery'} matching the "${_selectedFilterStatus?.displayName ?? 'All Statuses'}" filter.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyText2,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      // On pull-to-refresh, fetch without the main spinner, as the indicator is sufficient.
      onRefresh: () => _fetchAdminReservations(showLoadingIndicator: false),
      color: AppColors.appBar,
      child: ListView.builder(
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          final res = _reservations[index];
          final userIdentifier = res.userFullName ??
              res.userEmail ??
              'ID: ${res.userId.substring(0, 8)}...';
          return Card(
            margin: const EdgeInsets.only(bottom: 10.0),
            elevation: AppStyles.elevationLow,
            shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: AppColors.appBar.withOpacity(0.1),
                child: Text((index + 1).toString(),
                    style: const TextStyle(
                        color: AppColors.appBar, fontWeight: FontWeight.bold)),
              ),
              title: Text('Space: ${res.spaceIdentifier}',
                  style: AppStyles.cardTitleStyle),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User: $userIdentifier', style: AppStyles.bodyText2),
                    Text('Requested: ${_formatDateTime(res.requestedAt)}',
                        style: AppStyles.caption.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              isThreeLine: true,
              trailing: _buildStatusChip(res.status),
              onTap: () => _showReservationDetailsDialog(res),
            ),
          );
        },
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
          DropdownButtonFormField<ReservationStatus?>(
            decoration: InputDecoration(
              labelText: 'Filter by Status',
              border: OutlineInputBorder(
                  borderRadius: AppStyles.buttonBorderRadius),
              isDense: true,
              prefixIcon: const Icon(Icons.filter_list_alt, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            value: _selectedFilterStatus,
            items: _buildFilterOptions(),
            onChanged: (ReservationStatus? newValue) {
              setState(() => _selectedFilterStatus = newValue);
              // Changing the filter requires a full reload with a loading indicator.
              _fetchAdminReservations(showLoadingIndicator: true);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
}
