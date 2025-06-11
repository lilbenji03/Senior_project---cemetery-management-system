import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/spot_model.dart'; // For CemeterySpot and SpotStatus
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';

// final supabase = Supabase.instance.client; // Already available globally via Supabase.instance.client

extension StringExtension on String {
  // Keep this helper or move to a utils file
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class ManageSpotsAdminScreen extends StatefulWidget {
  final String? cemeteryId;
  final String? cemeteryName;

  const ManageSpotsAdminScreen({super.key, this.cemeteryId, this.cemeteryName});

  @override
  State<ManageSpotsAdminScreen> createState() => _ManageSpotsAdminScreenState();
}

class _ManageSpotsAdminScreenState extends State<ManageSpotsAdminScreen> {
  List<CemeterySpot> _spots = [];
  bool _isLoading = true;
  String? _errorMessage;
  SpotStatus? _filterStatus;

  late final List<Map<String, dynamic>> _statusFilterOptions;

  @override
  void initState() {
    super.initState();
    // Initialize filter options here because SpotStatus.values might not be const if SpotStatus itself is complex
    _statusFilterOptions = [
      {'value': null, 'display': 'All Statuses'},
      ...SpotStatus.values
          .where(
            (s) => s != SpotStatus.unknown,
          ) // Exclude 'unknown' from filter options
          .map((s) => {'value': s, 'display': s.displayName}) // Use displayName
          .toList(),
    ];
    print(
      "ManageSpotsAdminScreen initState: Cemetery ID: ${widget.cemeteryId}",
    );
    if (widget.cemeteryId != null) {
      _fetchCemeterySpots();
    } else {
      // Handle case for super admin where no cemetery is initially selected for spot management
      setState(() {
        _isLoading = false;
        _errorMessage =
            "Please select a cemetery to view spots."; // Or just show an empty state
        _spots = [];
      });
      print(
        "ManageSpotsAdminScreen: No cemeteryId provided, not fetching spots.",
      );
    }
  }

  @override
  void didUpdateWidget(ManageSpotsAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cemeteryId != oldWidget.cemeteryId) {
      print(
        "ManageSpotsAdminScreen didUpdateWidget: cemeteryId changed from ${oldWidget.cemeteryId} to ${widget.cemeteryId}. Refetching.",
      );
      // Reset filter when cemetery changes, or decide if filter should persist
      // setState(() {
      //   _filterStatus = null;
      // });
      if (widget.cemeteryId != null) {
        _fetchCemeterySpots();
      } else {
        setState(() {
          _isLoading = false;
          _spots = [];
          _errorMessage = "No cemetery selected.";
        });
      }
    }
    // Note: _filterStatus changes are handled by its onChanged callback calling _fetchCemeterySpots
  }

  Future<void> _fetchCemeterySpots() async {
    if (!mounted) return;
    // If cemeteryId is null, and this screen requires it, don't proceed.
    // This check is important if this function can be called from places other than initState/didUpdateWidget.
    if (widget.cemeteryId == null) {
      print(
        "ManageSpotsAdminScreen _fetchCemeterySpots: cemeteryId is null. Aborting fetch.",
      );
      setState(() {
        _isLoading = false;
        _spots = []; // Clear spots
        _errorMessage = "No cemetery selected to fetch spots.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print(
      "ManageSpotsAdminScreen: Fetching spots. Cemetery ID: ${widget.cemeteryId}, Filter: ${_filterStatus?.name}",
    );

    try {
      // Start with the base query (PostgrestQueryBuilder)
      var request = Supabase.instance.client
          .from(
            'cemetery_spots',
          ) // Use your actual table name, e.g., 'burial_spots'
          .select('''
            id, 
            spot_label, 
            spot_identifier, 
            status, 
            plot_type, 
            cemetery_id, 
            created_at, 
            updated_at,
            plots ( section_id, sections ( name ) ) 
          '''); // Adjust select to your CemeterySpot.fromJson needs

      // Conditionally apply filters
      // cemeteryId is already checked before calling this function, but this is a safeguard
      // The .eq for cemetery_id is the most important for your requirement
      request = request.eq('cemetery_id', widget.cemeteryId!);
      print("Filtering by cemetery_id: ${widget.cemeteryId}");

      if (_filterStatus != null) {
        request = request.eq(
          'status',
          _filterStatus!.name,
        ); // Use the string name of the enum
        print("Filtering by status: ${_filterStatus!.name}");
      }

      // Finally, apply order and execute
      final response = await request.order(
        'spot_identifier', // Or 'spot_label' - ensure this column exists
        ascending: true,
      );

      print("Supabase response received. Length: ${(response).length}");

      if (mounted) {
        setState(() {
          _spots =
              (response) // No need to cast to List here, it's already PostgrestList which is List<Map>
                  .map(
                    (data) =>
                        CemeterySpot.fromJson(data as Map<String, dynamic>),
                  )
                  .toList();
          _isLoading = false;
        });
        print(
          "Parsed ${_spots.length} spots for cemetery ${widget.cemeteryId}.",
        );
      }
    } catch (e, s) {
      // Catch stacktrace for more debug info
      print("ManageSpotsAdminScreen: ERROR fetching spots: $e");
      print("Stacktrace: $s");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load spots: ${e.toString()}";
          _isLoading = false;
          _spots = [];
        });
      }
    }
  }

  Future<void> _updateSpotStatus(
    String spotDatabaseId,
    SpotStatus newStatus,
  ) async {
    if (!mounted) return;
    setState(
      () => _isLoading = true,
    ); // Or use a more localized loading indicator
    print(
      "ManageSpotsAdminScreen: Updating spot $spotDatabaseId to status ${newStatus.name}",
    );
    try {
      await Supabase.instance.client
          .from('cemetery_spots') // Use your actual table name
          .update({
            'status': newStatus.name, // Send the string name of the enum
            'updated_at':
                DateTime.now()
                    .toIso8601String(), // If you manage this client-side
          })
          .eq(
            'id',
            spotDatabaseId,
          ); // 'id' should be the PK of your spots table

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Spot status updated to ${newStatus.displayName}!', // Use displayName
            ),
            backgroundColor:
                AppColors.statusApproved, // Or a generic success color
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
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getSpotColor(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return Colors.green.shade100; // Softer available
      case SpotStatus.booked:
        return Colors.orange.shade100; // Softer booked/reserved
      case SpotStatus.used:
        return Colors.red.shade100; // Softer used/occupied
      case SpotStatus.pendingApproval:
        return Colors.yellow.shade100;
      case SpotStatus.maintenance:
        return Colors.blueGrey.shade100;
      case SpotStatus.unknown:
        return Colors.grey.shade300;
    }
  }

  Color _getSpotTextColor(SpotStatus status) {
    // Generally darker text on lighter backgrounds
    return Colors.black87;
  }

  void _showSpotActionsDialog(CemeterySpot spot) {
    List<SpotStatus> possibleNewStatuses =
        SpotStatus.values
            .where((s) => s != spot.status && s != SpotStatus.unknown)
            .toList();

    SpotStatus? selectedStatusForDialog =
        spot.status; // Pre-select current status or null

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // Use StatefulBuilder if you need to update dialog state, e.g., for Radio
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Manage Spot: ${spot.spotIdentifier}"),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              content: SingleChildScrollView(
                // In case of many statuses
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Status: ${spot.status.displayName}",
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
                      const Text("No other statuses available."),
                    ...possibleNewStatuses.map(
                      (newStatus) => RadioListTile<SpotStatus>(
                        title: Text(newStatus.displayName),
                        value: newStatus,
                        groupValue:
                            selectedStatusForDialog, // This will be updated by setDialogState
                        onChanged: (SpotStatus? value) {
                          setDialogState(() {
                            // Update dialog's local state for radio button
                            selectedStatusForDialog = value;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed:
                      (selectedStatusForDialog != null &&
                              selectedStatusForDialog != spot.status)
                          ? () {
                            Navigator.of(dialogContext).pop();
                            _updateSpotStatus(
                              spot.databaseId,
                              selectedStatusForDialog!,
                            ); // Use databaseId
                          }
                          : null, // Disable if no change or no selection
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cemeteryId == null && !_isLoading) {
      // Show message if no cemetery ID and not loading
      return Center(
        child: Padding(
          padding: AppStyles.pagePadding,
          child: Text(
            _errorMessage ?? "Please select a cemetery to manage spots.",
            style: AppStyles.titleStyle.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: AppStyles.pagePadding.copyWith(
        top: 8.0,
        bottom: 0,
      ), // Adjust bottom padding if FAB overlaps
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<SpotStatus?>(
            // Allow SpotStatus? for 'All'
            decoration: InputDecoration(
              labelText: 'Filter by Status',
              border: OutlineInputBorder(
                borderRadius: AppStyles.buttonBorderRadius,
              ),
              isDense: true,
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            value: _filterStatus,
            hint: const Text('All Statuses'),
            items:
                _statusFilterOptions.map((filter) {
                  return DropdownMenuItem<SpotStatus?>(
                    // Allow SpotStatus?
                    value: filter['value'] as SpotStatus?,
                    child: Text(
                      filter['display'] as String,
                      style: AppStyles.bodyText1,
                    ),
                  );
                }).toList(),
            onChanged: (SpotStatus? newValue) {
              setState(() => _filterStatus = newValue);
              _fetchCemeterySpots();
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.activeTab,
                      ),
                    ) // Use activeTab color
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
                            ? 'No spots found for ${widget.cemeteryName ?? "this cemetery"}.'
                            : 'No spots found with status "${_filterStatus!.displayName}" for ${widget.cemeteryName ?? "this cemetery"}.',
                        style: AppStyles.subtitleText.copyWith(
                          color: AppColors.secondaryText,
                        ), // Ensure subtitleText is defined
                        textAlign: TextAlign.center,
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        bottom: 70,
                      ), // Add bottom padding for FAB
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 700
                                ? 6 // Adjusted cross axis count
                                : (MediaQuery.of(context).size.width > 500
                                    ? 4
                                    : 3),
                        childAspectRatio: 1.1, // Adjusted aspect ratio
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _spots.length,
                      itemBuilder: (context, index) {
                        final spot = _spots[index];
                        final spotColor = _getSpotColor(spot.status);
                        final textColor = _getSpotTextColor(spot.status);
                        return GestureDetector(
                          onTap: () => _showSpotActionsDialog(spot),
                          child: Card(
                            elevation: 1.0,
                            color: spotColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Tooltip(
                              message:
                                  "ID: ${spot.spotIdentifier}\nStatus: ${spot.status.displayName}\nType: ${spot.plotType ?? 'N/A'}\nSection: ${spot.sectionName ?? 'N/A'}",
                              child: Padding(
                                // Added padding inside card
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      spot.spotIdentifier,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 11, // Adjusted font
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      spot.status.displayName.length > 10
                                          ? spot.status.displayName.substring(
                                                0,
                                                8,
                                              ) +
                                              "..."
                                          : spot.status.displayName,
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.9),
                                        fontSize: 9, // Adjusted font
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
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
