// lib/screens/admin/manage_spaces_admin_screen.dart
// (Ensure you've renamed the file)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/space_model.dart'; // UPDATED: Import Space model
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';

// extension StringExtension on String { // Keep if used elsewhere, or remove
//   String capitalizeFirst() {
//     if (isEmpty) return this;
//     return "${this[0].toUpperCase()}${substring(1)}";
//   }
// }

class ManageSpacesAdminScreen extends StatefulWidget {
  // UPDATED Class Name
  final String? cemeteryId;
  final String? cemeteryName;

  const ManageSpacesAdminScreen({
    super.key,
    this.cemeteryId,
    this.cemeteryName,
  }); // UPDATED Constructor

  @override
  State<ManageSpacesAdminScreen> createState() =>
      _ManageSpacesAdminScreenState(); // UPDATED State Class Name
}

class _ManageSpacesAdminScreenState extends State<ManageSpacesAdminScreen> {
  // UPDATED State Class Name
  List<CemeterySpace> _spaces = []; // UPDATED to CemeterySpace
  bool _isLoading = true;
  String? _errorMessage;
  SpaceStatus? _filterStatus; // UPDATED to SpaceStatus
  StreamSubscription<List<Map<String, dynamic>>>? _spacesSubscription;

  // Generate filter options from the enum
  List<DropdownMenuItem<SpaceStatus?>> _buildFilterOptions() {
    List<DropdownMenuItem<SpaceStatus?>> items = [
      const DropdownMenuItem<SpaceStatus?>(
        value: null, // Represents "All Statuses"
        child: Text("All Statuses"),
      ),
    ];
    items.addAll(
      SpaceStatus.values
          .where((status) => status != SpaceStatus.unknown)
          .map(
            (status) => DropdownMenuItem<SpaceStatus?>(
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
      "ManageSpacesAdminScreen initState: Cemetery ID: ${widget.cemeteryId}",
    );
    if (widget.cemeteryId != null) {
      _fetchCemeterySpaces();
      _subscribeToSpaceChanges();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Please select a cemetery to manage spaces.";
        _spaces = [];
      });
      print(
        "ManageSpacesAdminScreen: No cemeteryId provided, not fetching spaces.",
      );
    }
  }

  @override
  void didUpdateWidget(ManageSpacesAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cemeteryId != oldWidget.cemeteryId) {
      print(
        "ManageSpacesAdminScreen didUpdateWidget: cemeteryId changed. Refetching.",
      );
      _spacesSubscription?.cancel(); // Cancel old subscription
      if (widget.cemeteryId != null) {
        _fetchCemeterySpaces();
        _subscribeToSpaceChanges(); // Subscribe for new cemeteryId
      } else {
        setState(() {
          _isLoading = false;
          _spaces = [];
          _errorMessage = "No cemetery selected.";
        });
      }
    }
  }

  Future<void> _fetchCemeterySpaces() async {
    if (!mounted || widget.cemeteryId == null) {
      if (widget.cemeteryId == null) {
        setState(() {
          _isLoading = false;
          _spaces = [];
          _errorMessage = "No cemetery selected to fetch spaces.";
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print(
      "ManageSpacesAdminScreen: Fetching spaces. Cemetery ID: ${widget.cemeteryId}, Filter: ${_filterStatus?.name}",
    );

    try {
      var query = Supabase.instance.client
          .from('cemetery_spaces') // UPDATED table name
          .select('''
            id, 
            space_identifier, 
            status, 
            plot_type, 
            dimensions,
            notes,
            cemetery_id, 
            created_at, 
            updated_at
            
          ''');
      // Add joins if CemeterySpace.fromJson expects them, e.g., for section name
      // plots ( section_id, sections ( name ) ) - if you have such structure

      query = query.eq('cemetery_id', widget.cemeteryId!);

      if (_filterStatus != null) {
        query = query.eq(
          'status',
          _filterStatus!.toJson(),
        ); // UPDATED to use enum.toJson()
      }

      final response = await query.order(
        'space_identifier',
        ascending: true,
      ); // UPDATED to space_identifier

      if (mounted) {
        setState(() {
          _spaces =
              response.map((data) => CemeterySpace.fromJson(data)).toList();
          _isLoading = false;
        });
        print(
          "Parsed ${_spaces.length} spaces for cemetery ${widget.cemeteryId}.",
        );
      }
    } catch (e, s) {
      print(
        "ManageSpacesAdminScreen: ERROR fetching spaces: $e\nStacktrace: $s",
      );
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load spaces: ${e.toString()}";
          _isLoading = false;
          _spaces = [];
        });
      }
    }
  }

  void _subscribeToSpaceChanges() {
    if (widget.cemeteryId == null) return;

    _spacesSubscription?.cancel(); // Cancel any existing subscription first
    _spacesSubscription = Supabase.instance.client
        .from('cemetery_spaces') // UPDATED table name
        .stream(primaryKey: ['id'])
        .eq('cemetery_id', widget.cemeteryId!) // Filter stream by cemetery
        // Note: Further filtering by status on stream is complex.
        // Usually, you get all for the cemetery and then re-apply client filter or refetch.
        .listen(
          (List<Map<String, dynamic>> data) {
            print(
              "ManageSpacesAdminScreen: Stream received ${data.length} records.",
            );
            if (mounted) {
              // Simple approach: refetch to ensure server-side filters are applied.
              // More advanced: merge data client-side if performance is critical and filters are simple.
              _fetchCemeterySpaces();
            }
          },
          onError: (error) {
            if (mounted) {
              print("Spaces stream error: $error");
            }
          },
        );
  }

  Future<void> _updateSpaceStatus(String spaceId, SpaceStatus newStatus) async {
    // UPDATED params
    if (!mounted) return;
    // Potentially show a quick loading indicator on the specific card being updated
    // For now, global isLoading for simplicity during update
    // setState(() => _isLoading = true);
    print(
      "ManageSpacesAdminScreen: Updating space $spaceId to status ${newStatus.name}",
    );
    try {
      await Supabase.instance.client
          .from('cemetery_spaces') // UPDATED table name
          .update({
            'status': newStatus.toJson(), // UPDATED to use enum.toJson()
            'updated_at':
                DateTime.now().toIso8601String(), // If DB doesn't auto-update
          })
          .eq('id', spaceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Space status updated to ${newStatus.displayName}!'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
        // Data will be refreshed by the stream or explicit _fetchCemeterySpaces if stream not detailed enough
        // _fetchCemeterySpaces(); // Usually handled by stream now
      }
    } catch (e) {
      print("ManageSpacesAdminScreen: ERROR updating space status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating space status: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      // if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getSpaceColor(SpaceStatus status) {
    // UPDATED param type
    switch (status) {
      case SpaceStatus.available:
        return Colors.green.shade100;
      case SpaceStatus.booked:
        return Colors.orange.shade100;
      case SpaceStatus.used:
        return Colors.red.shade100;
      case SpaceStatus.pendingApproval:
        return Colors.yellow.shade100;
      case SpaceStatus.maintenance:
        return Colors.blueGrey.shade100;
      case SpaceStatus.unknown:
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getSpaceTextColor(SpaceStatus status) {
    // UPDATED param type
    return Colors.black87; // Generally good for light backgrounds
  }

  void _showSpaceActionsDialog(CemeterySpace space) {
    // UPDATED param type
    List<SpaceStatus> possibleNewStatuses =
        SpaceStatus.values
            .where((s) => s != space.status && s != SpaceStatus.unknown)
            .toList();

    SpaceStatus? selectedStatusForDialog = space.status;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Manage Space: ${space.spaceIdentifier}"), // UPDATED
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Status: ${space.status.displayName}",
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
                      (newStatus) => RadioListTile<SpaceStatus>(
                        title: Text(newStatus.displayName),
                        value: newStatus,
                        groupValue: selectedStatusForDialog,
                        onChanged: (SpaceStatus? value) {
                          setDialogState(() => selectedStatusForDialog = value);
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
                              selectedStatusForDialog != space.status)
                          ? () {
                            Navigator.of(dialogContext).pop();
                            _updateSpaceStatus(
                              space.id,
                              selectedStatusForDialog!,
                            ); // Use space.id (PK)
                          }
                          : null,
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
  void dispose() {
    _spacesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cemeteryId == null && !_isLoading) {
      return Center(/* ... "Please select a cemetery..." message ... */);
    }

    return Padding(
      padding: AppStyles.pagePadding.copyWith(top: 8.0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<SpaceStatus?>(
            decoration: InputDecoration(
              labelText: 'Filter by Status',
              border: OutlineInputBorder(
                borderRadius: AppStyles.buttonBorderRadius,
              ),
              isDense: true,
              filled: true,
              fillColor: AppColors.cardBackground,
              prefixIcon: const Icon(Icons.filter_list_alt, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            value: _filterStatus,
            hint: const Text('All Statuses'), // Displayed when value is null
            items: _buildFilterOptions(), // Use the dynamic builder
            onChanged: (SpaceStatus? newValue) {
              setState(() => _filterStatus = newValue);
              _fetchCemeterySpaces();
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
                    )
                    : _errorMessage != null
                    ? Center(/* ... error message with retry ... */)
                    : _spaces.isEmpty
                    ? Center(/* ... "No spaces found..." message ... */)
                    : RefreshIndicator(
                      // Added RefreshIndicator
                      onRefresh: _fetchCemeterySpaces,
                      color: AppColors.appBar,
                      child: GridView.builder(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 70),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 700
                                  ? 6
                                  : (MediaQuery.of(context).size.width > 500
                                      ? 4
                                      : 3),
                          childAspectRatio: 1.1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount:
                            _spaces
                                .length, // Display all fetched & filtered spaces
                        itemBuilder: (context, index) {
                          final space = _spaces[index];
                          final spaceColor = _getSpaceColor(space.status);
                          final textColor = _getSpaceTextColor(space.status);
                          return GestureDetector(
                            onTap: () => _showSpaceActionsDialog(space),
                            child: Card(
                              elevation: 1.5, // Slightly more elevation
                              color: spaceColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.black.withOpacity(0.1),
                                  width: 0.5,
                                ), // Subtle border
                              ),
                              child: Tooltip(
                                message:
                                    "ID: ${space.spaceIdentifier}\nStatus: ${space.status.displayName}\nType: ${space.plotType ?? 'N/A'}",
                                // Removed section name as it's not directly in CemeterySpace model unless joined
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    6.0,
                                  ), // Increased padding
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        space
                                            .spaceIdentifier, // Display spaceIdentifier
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ), // Increased size
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        space.status.displayName.length >
                                                12 // Adjusted length for display name
                                            ? "${space.status.displayName.substring(0, 10)}..."
                                            : space.status.displayName,
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.9),
                                          fontSize: 10,
                                        ), // Increased size
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
          ),
        ],
      ),
    );
  }
}
