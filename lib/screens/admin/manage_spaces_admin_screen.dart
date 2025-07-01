import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/space_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';

class ManageSpacesAdminScreen extends StatefulWidget {
  final String? cemeteryId;
  final String? cemeteryName;

  const ManageSpacesAdminScreen({
    super.key,
    this.cemeteryId,
    this.cemeteryName,
  });

  @override
  State<ManageSpacesAdminScreen> createState() =>
      _ManageSpacesAdminScreenState();
}

class _ManageSpacesAdminScreenState extends State<ManageSpacesAdminScreen> {
  List<CemeterySpace> _spaces = [];
  bool _isLoading = true;
  String? _errorMessage;
  SpaceStatus? _filterStatus;
  StreamSubscription? _spacesSubscription;

  List<DropdownMenuItem<SpaceStatus?>> _buildFilterOptions() {
    List<DropdownMenuItem<SpaceStatus?>> items = [
      const DropdownMenuItem<SpaceStatus?>(
        value: null,
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
    _handleCemeteryChange();
  }

  @override
  void didUpdateWidget(ManageSpacesAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cemeteryId != oldWidget.cemeteryId) {
      _handleCemeteryChange();
    }
  }

  @override
  void dispose() {
    _spacesSubscription?.cancel();
    _spacesSubscription = null;
    super.dispose();
  }

  void _handleCemeteryChange() {
    _spacesSubscription?.cancel();
    _spacesSubscription = null; // Explicitly nullify

    if (widget.cemeteryId != null) {
      _fetchAndSubscribe();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "No cemetery assigned to this manager account.";
        _spaces = [];
      });
    }
  }

  Future<void> _fetchAndSubscribe() async {
    // Fetch with a loading indicator for the initial load.
    await _fetchCemeterySpaces(showLoadingIndicator: true);

    // Subscribe to changes if the initial fetch was successful.
    if (mounted && _errorMessage == null) {
      _subscribeToSpaceChanges();
    }
  }

  // --- THIS IS THE CORRECTED METHOD ---
  Future<void> _fetchCemeterySpaces({bool showLoadingIndicator = true}) async {
    if (!mounted || widget.cemeteryId == null) return;

    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      var query = Supabase.instance.client
          .from('cemetery_spaces')
          .select()
          .eq('cemetery_id', widget.cemeteryId!);

      if (_filterStatus != null) {
        // Correctly use .name for enums matching PostgreSQL ENUM labels
        query = query.eq('status', _filterStatus!.name);
      }
      final response = await query.order('space_identifier', ascending: true);
      if (mounted) {
        setState(() {
          _spaces =
              response.map((data) => CemeterySpace.fromJson(data)).toList();
          _isLoading = false; // Always turn off loading after a fetch.
        });
      }
    } catch (e) {
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
    _spacesSubscription?.cancel(); // Ensure no duplicate listeners

    _spacesSubscription = Supabase.instance.client
        .from('cemetery_spaces')
        .stream(primaryKey: ['id'])
        // OPTIMIZATION: Only listen to changes for the current cemetery
        .eq('cemetery_id', widget.cemeteryId!)
        .listen(
          (data) {
            if (mounted) {
              // Fetch silently in the background without a loading spinner
              _fetchCemeterySpaces(showLoadingIndicator: false);
            }
          },
          onError: (e) => print("Spaces stream error: $e"),
        );
  }

  Future<void> _updateSpaceStatus(String spaceId, SpaceStatus newStatus) async {
    if (!mounted) return;
    try {
      await Supabase.instance.client
          .from('cemetery_spaces')
          // Correctly use .name for enums matching PostgreSQL ENUM labels
          .update({'status': newStatus.name}).eq('id', spaceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Space status updated to ${newStatus.displayName}!'),
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

  Color _getSpaceColor(SpaceStatus status) {
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
      default:
        return Colors.grey.shade300;
    }
  }

  void _showSpaceActionsDialog(CemeterySpace space) {
    List<SpaceStatus> possibleNewStatuses =
        SpaceStatus.values.where((s) => s != SpaceStatus.unknown).toList();

    SpaceStatus? selectedStatusForDialog = space.status;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: AppStyles.cardBorderRadius),
              title: Text("Manage Space: ${space.spaceIdentifier}",
                  style: AppStyles.titleStyle),
              contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: possibleNewStatuses.map((newStatus) {
                    return RadioListTile<SpaceStatus>(
                      title: Text(newStatus.displayName,
                          style: AppStyles.regularText),
                      value: newStatus,
                      groupValue: selectedStatusForDialog,
                      onChanged: (SpaceStatus? value) {
                        setDialogState(() {
                          selectedStatusForDialog = value;
                        });
                      },
                      activeColor: AppColors.activeTab,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text("Cancel", style: AppStyles.bodyText2),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: AppColors.buttonText,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppStyles.buttonBorderRadius),
                  ),
                  onPressed: (selectedStatusForDialog != null &&
                          selectedStatusForDialog != space.status)
                      ? () {
                          Navigator.of(dialogContext).pop();
                          _updateSpaceStatus(
                              space.id, selectedStatusForDialog!);
                        }
                      : null,
                  child: const Text("Update Status",
                      style: AppStyles.buttonTextStyle),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    if (widget.cemeteryId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined,
                  size: 60, color: AppColors.secondaryText),
              const SizedBox(height: 16),
              Text('No Cemetery Assigned', style: AppStyles.titleStyle),
              const SizedBox(height: 8),
              Text(
                'This account is not assigned to manage a specific cemetery.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyText2,
              ),
            ],
          ),
        ),
      );
    }
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.activeTab));
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
                onPressed: _fetchAndSubscribe,
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.appBar),
              )
            ],
          ),
        ),
      );
    }
    if (_spaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_off_outlined,
                color: AppColors.secondaryText, size: 60),
            const SizedBox(height: 16),
            Text('No Spaces Found', style: AppStyles.titleStyle),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'There are no spaces in "${widget.cemeteryName ?? 'this cemetery'}" matching the "${_filterStatus?.displayName ?? 'All'}" filter.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyText2,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetchCemeterySpaces(showLoadingIndicator: false),
      color: AppColors.appBar,
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 8.0, bottom: 70),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 700
              ? 6
              : (MediaQuery.of(context).size.width > 500 ? 4 : 3),
          childAspectRatio: 1.1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _spaces.length,
        itemBuilder: (context, index) {
          final space = _spaces[index];
          return GestureDetector(
            onTap: () => _showSpaceActionsDialog(space),
            child: Card(
              elevation: 1.5,
              color: _getSpaceColor(space.status),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: Colors.black.withOpacity(0.1), width: 0.5),
              ),
              child: Tooltip(
                message:
                    "ID: ${space.spaceIdentifier}\nStatus: ${space.status.displayName}",
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        space.spaceIdentifier,
                        style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        space.status.displayName,
                        style: TextStyle(
                            color: AppColors.primaryText.withOpacity(0.9),
                            fontSize: 10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppStyles.pagePadding.copyWith(top: 8.0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.cemeteryId != null)
            DropdownButtonFormField<SpaceStatus?>(
              decoration: InputDecoration(
                labelText: 'Filter by Status',
                border: OutlineInputBorder(
                    borderRadius: AppStyles.buttonBorderRadius),
                isDense: true,
                filled: true,
                fillColor: AppColors.cardBackground,
                prefixIcon: const Icon(Icons.filter_list_alt, size: 20),
              ),
              value: _filterStatus,
              hint: const Text('All Statuses'),
              items: _buildFilterOptions(),
              onChanged: (SpaceStatus? newValue) {
                setState(() => _filterStatus = newValue);
                // Changing the filter requires a full reload with a spinner.
                _fetchCemeterySpaces(showLoadingIndicator: true);
              },
            ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
