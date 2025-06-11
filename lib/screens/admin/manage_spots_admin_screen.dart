import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/spot_model.dart'; // For CemeterySpot and SpotStatus
import '../../constants/app_colors.dart'; // Assuming using main app's constants
import '../../constants/app_styles.dart'; // Assuming using main app's constants

final supabase = Supabase.instance.client;

class ManageSpotsAdminScreen extends StatefulWidget {
  final String?
  cemeteryId; // Nullable if system_super_admin views all or selects
  final String? cemeteryName;

  const ManageSpotsAdminScreen({super.key, this.cemeteryId, this.cemeteryName});

  @override
  State<ManageSpotsAdminScreen> createState() => _ManageSpotsAdminScreenState();
}

class _ManageSpotsAdminScreenState extends State<ManageSpotsAdminScreen> {
  List<CemeterySpot> _spots = [];
  bool _isLoading = true;
  String? _errorMessage;
  SpotStatus? _filterStatus; // To filter spots by status

  // Define filter options
  final List<Map<String, dynamic>> _statusFilterOptions = [
    {'value': null, 'display': 'All Statuses'}, // null value for 'all'
    ...SpotStatus.values
        .map((s) => {'value': s, 'display': s.name.capitalizeFirst()})
        .toList(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchCemeterySpots();
  }

  @override
  void didUpdateWidget(ManageSpotsAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch if cemeteryId or filter changes
    if (widget.cemeteryId != oldWidget.cemeteryId ||
        _filterStatus != _filterStatus) {
      _fetchCemeterySpots();
    }
  }

  Future<void> _fetchCemeterySpots() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print(
      "ManageSpotsAdminScreen: Fetching spots. Cemetery ID: ${widget.cemeteryId}, Filter: ${_filterStatus?.name}",
    );

    try {
      PostgrestTransformBuilder<PostgrestList> query =
          supabase
              .from('cemetery_spots')
              .select(); // Select all columns needed by CemeterySpot.fromJson

      // In _fetchCemeterySpots (or _fetchAdminReservations)

      Future<void> _fetchCemeterySpots() async {
        // Or _fetchAdminReservations
        if (!mounted) return;
        setState(() {
          /* ... isLoading ... */
        });
        print(
          "ManageSpotsAdminScreen: Fetching spots. Cemetery ID: ${widget.cemeteryId}, Filter: ${_filterStatus?.name}",
        );

        try {
          // Start with the base query (PostgrestQueryBuilder)
          // The type of 'request' will be PostgrestQueryBuilder initially
          var request =
              supabase
                  .from('cemetery_spots') // Or 'reservations'
                  .select(); // Add your select string here for reservations: .select('''id, name, profiles (email)''')

          // Conditionally apply filters
          if (widget.cemeteryId != null) {
            // .eq() returns a PostgrestFilterBuilder. 'request' type updates.
            request = request.eq('cemetery_id', widget.cemeteryId!);
            print("Filtering by cemetery_id: ${widget.cemeteryId}");
          }

          if (_filterStatus != null) {
            // .eq() can be called on both PostgrestQueryBuilder and PostgrestFilterBuilder.
            // 'request' type remains or becomes PostgrestFilterBuilder.
            request = request.eq('status', _filterStatus!.name);
            print("Filtering by status: ${_filterStatus!.name}");
          }

          // Finally, apply order and execute
          // .order() returns a PostgrestTransformBuilder.
          // We await the result of this final chained operation.
          final response = await request.order(
            'spot_identifier',
            ascending: true,
          ); // Or 'requested_at' for reservations

          print(
            "Supabase response received. Length: ${(response as List).length}",
          );

          if (mounted) {
            setState(() {
              // Assuming CemeterySpot.fromJson or Reservation.fromJson
              _spots =
                  (response as List)
                      .map((data) => CemeterySpot.fromJson(data))
                      .toList();
              _isLoading = false;
            });
            print("Parsed ${_spots.length} spots.");
          }
        } catch (e) {
          print("ERROR fetching: ${e.toString()}");
          if (mounted) {
            setState(() {
              /* ... handle error ... */
            });
          }
        }
      }

      query = query.order(
        'spot_identifier',
        ascending: true,
      ); // Order by spot ID

      final response = await query;

      if (mounted) {
        setState(() {
          _spots =
              (response as List)
                  .map((data) => CemeterySpot.fromJson(data))
                  .toList();
          _isLoading = false;
        });
        print("ManageSpotsAdminScreen: Fetched ${_spots.length} spots.");
      }
    } catch (e) {
      print("ManageSpotsAdminScreen: ERROR fetching spots: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load spots: ${e.toString()}";
          _isLoading = false;
          _spots = [];
        });
      }
    }
  }

  Future<void> _updateSpotStatus(String spotDbId, SpotStatus newStatus) async {
    if (!mounted) return;
    // Show a quick loading indication on the specific spot or globally
    // For simplicity, global loading for now
    setState(() => _isLoading = true);
    print(
      "ManageSpotsAdminScreen: Updating spot $spotDbId to status ${newStatus.name}",
    );
    try {
      await supabase
          .from('cemetery_spots')
          .update({
            'status': newStatus.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', spotDbId); // 'id' should be the PK of cemetery_spots table

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Spot status updated to ${newStatus.name.capitalizeFirst()}!',
            ),
            backgroundColor: AppColors.spotsAvailable,
          ),
        );
        _fetchCemeterySpots(); // Refresh the list
      }
    } catch (e) {
      print("ManageSpotsAdminScreen: ERROR updating spot status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating spot status: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        setState(() => _isLoading = false); // Stop loading on error
      }
    }
    // No finally here, _fetchCemeterySpots will set _isLoading = false
  }

  Color _getSpotColor(SpotStatus status) {
    // Use your existing color logic from user app's CemeterySpotListPage
    switch (status) {
      case SpotStatus.available:
        return Colors.grey.shade300;
      case SpotStatus.booked:
        return Colors.orange.shade600;
      case SpotStatus.used:
        return Colors.red.shade700;
      case SpotStatus.pendingApproval:
        return Colors.yellow.shade700;
      case SpotStatus.maintenance:
        return Colors.blueGrey.shade400;
      case SpotStatus.unknown:
        return Colors.black26;
    }
  }

  Color _getSpotTextColor(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
      case SpotStatus.pendingApproval:
      case SpotStatus.maintenance:
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  void _showSpotActionsDialog(CemeterySpot spot) {
    // Allow admin to change status, e.g., mark for maintenance, or manually make available
    // For simplicity, let's just allow changing to 'available' or 'maintenance'
    List<SpotStatus> possibleNewStatuses = [
      SpotStatus.available,
      SpotStatus.maintenance,
    ];
    if (spot.status == SpotStatus.available) {
      possibleNewStatuses.remove(SpotStatus.available);
    } else if (spot.status == SpotStatus.maintenance) {
      possibleNewStatuses.remove(SpotStatus.maintenance);
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Manage Spot: ${spot.spotIdentifier}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Current Status: ${spot.status.name.capitalizeFirst()}",
                style: AppStyles.bodyText1,
              ),
              const SizedBox(height: 16),
              Text(
                "Change status to:",
                style: AppStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (possibleNewStatuses.isEmpty)
                const Text(
                  "No direct status changes available for this spot currently.",
                ),
              ...possibleNewStatuses
                  .map(
                    (newStatus) => ListTile(
                      title: Text(newStatus.name.capitalizeFirst()),
                      leading: Radio<SpotStatus>(
                        value: newStatus,
                        groupValue:
                            null, // No group needed for one-off selection
                        onChanged: (SpotStatus? selectedStatus) {
                          if (selectedStatus != null) {
                            Navigator.of(
                              dialogContext,
                            ).pop(); // Close this dialog
                            _updateSpotStatus(spot.dbId, selectedStatus);
                          }
                        },
                      ),
                      onTap: () {
                        // Make the whole ListTile tappable
                        Navigator.of(dialogContext).pop();
                        _updateSpotStatus(spot.dbId, newStatus);
                      },
                    ),
                  )
                  .toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget forms the body of a tab in AdminDashboardScreen.
    // No Scaffold or AppBar if it's embedded.
    return Padding(
      padding: AppStyles.pagePadding.copyWith(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Dropdown for Spot Status
          DropdownButtonFormField<SpotStatus>(
            // Changed type to SpotStatus?
            decoration: InputDecoration(
              labelText: 'Filter by Spot Status',
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
            hint: const Text('All Spot Statuses'),
            items:
                _statusFilterOptions.map((filter) {
                  return DropdownMenuItem<SpotStatus>(
                    value:
                        filter['value'] as SpotStatus?, // Cast to SpotStatus?
                    child: Text(
                      filter['display'] as String,
                      style: AppStyles.bodyText1,
                    ),
                  );
                }).toList(),
            onChanged: (SpotStatus? newValue) {
              setState(
                () => _filterStatus = newValue,
              ); // newValue can be null for 'All'
              _fetchCemeterySpots();
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
                    : _spots.isEmpty
                    ? Center(
                      child: Text(
                        _filterStatus == null
                            ? 'No spots found for ${widget.cemeteryName ?? "the selected cemetery"}.'
                            : 'No spots found with status "${_filterStatus!.name.capitalizeFirst()}" for ${widget.cemeteryName ?? "the selected cemetery"}.',
                        style: AppStyles.subtitleText,
                        textAlign: TextAlign.center,
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.only(top: 8.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 700
                                ? 8
                                : (MediaQuery.of(context).size.width > 500
                                    ? 6
                                    : 4),
                        childAspectRatio: 1.2, // Make items a bit taller
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: _spots.length,
                      itemBuilder: (context, index) {
                        final spot = _spots[index];
                        final spotColor = _getSpotColor(spot.status);
                        final textColor = _getSpotTextColor(spot.status);
                        return GestureDetector(
                          onTap: () => _showSpotActionsDialog(spot),
                          child: Card(
                            elevation: 0.5,
                            color: spotColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Tooltip(
                              message:
                                  "ID: ${spot.spotIdentifier}\nStatus: ${spot.status.name.capitalizeFirst()}\nType: ${spot.plotType ?? 'N/A'}",
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    spot.spotIdentifier,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    spot.status.name
                                            .capitalizeFirst()
                                            .substring(
                                              0,
                                              min(spot.status.name.length, 4),
                                            ) +
                                        (spot.status.name.length > 4
                                            ? "."
                                            : ""),
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.8),
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
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

// Helper from previous response (ensure it's accessible or defined in a utility file)
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}"; // Simple capitalize
  }
}
