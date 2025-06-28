// lib/screens/all_spaces_list_page.dart
// (Assuming you've renamed the file from map_booking_page.dart)
import 'dart:async';
import 'package:cmc/screens/space_booking_details_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cemetery_model.dart';
import '../models/space_model.dart'; // Ensured this points to your refactored space_model.dart
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

final supabase = Supabase.instance.client;

class AllSpacesListPage extends StatefulWidget {
  final Cemetery cemetery;

  const AllSpacesListPage({super.key, required this.cemetery});

  @override
  State<AllSpacesListPage> createState() => _AllSpacesListPageState();
}

class _AllSpacesListPageState extends State<AllSpacesListPage> {
  List<CemeterySpace> _spaces = []; // Changed from CemeterySpot
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>?
      _spacesSubscription; // For potential realtime updates

  SpaceStatus? _selectedFilterStatus;
  List<CemeterySpace> _filteredSpaces = [];

  @override
  void initState() {
    super.initState();
    _fetchCemeterySpacesFromSupabase();
    _subscribeToSpaceChanges(); // Optional: Add if you want realtime updates
  }

  Future<void> _fetchCemeterySpacesFromSupabase() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<dynamic> response = await supabase
          .from(
              'cemetery_spaces') // Assuming your table is named 'cemetery_spaces'
          .select()
          .eq('cemetery_id', widget.cemetery.id)
          .order('space_identifier',
              ascending: true); // Uses 'space_identifier'

      if (mounted) {
        setState(() {
          _spaces =
              response.map((data) => CemeterySpace.fromJson(data)).toList();
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load spaces: ${e.toString()}";
          _isLoading = false;
          _spaces = [];
          _filteredSpaces = [];
        });
      }
    }
  }

  void _subscribeToSpaceChanges() {
    // Optional: Implement realtime updates if needed for this page
    _spacesSubscription = supabase
        .from(
            'cemetery_spaces') // Assuming your table is named 'cemetery_spaces'
        .stream(primaryKey: ['id'])
        .eq('cemetery_id', widget.cemetery.id)
        .order('space_identifier', ascending: true)
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              _spaces =
                  data.map((item) => CemeterySpace.fromJson(item)).toList();
              _applyFilter(); // Re-apply filter when data changes
            });
          }
        }, onError: (error) {
          if (mounted) {
            // Handle stream error, maybe show a toast or a silent log
            print("Space stream error: $error");
            // Optionally set _errorMessage, but be mindful if initial load was successful
            // setState(() {
            //   _errorMessage = "Realtime update error: ${error.toString()}";
            // });
          }
        });
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilterStatus == null) {
        _filteredSpaces = List.from(_spaces);
      } else {
        _filteredSpaces = _spaces
            .where((space) => space.status == _selectedFilterStatus)
            .toList();
      }
    });
  }

  void _onFilterChanged(SpaceStatus? newStatus) {
    setState(() {
      _selectedFilterStatus = newStatus;
      _applyFilter();
    });
  }

  Color _getColorForStatus(SpaceStatus status) {
    switch (status) {
      case SpaceStatus.available:
        return Colors.green.shade500;
      case SpaceStatus.pendingApproval:
        return Colors.yellow.shade700;
      case SpaceStatus.booked:
        return Colors.orange.shade600;
      case SpaceStatus.used:
        return Colors.red.shade700;
      case SpaceStatus.maintenance:
        return Colors.blueGrey.shade400;
      case SpaceStatus.unknown:
        return Colors.grey.shade500;
    }
  }

  Color _getTextColorForStatus(SpaceStatus status) {
    switch (status) {
      case SpaceStatus.available:
      case SpaceStatus.pendingApproval:
      case SpaceStatus.maintenance:
      case SpaceStatus.unknown:
        return Colors.black87;
      case SpaceStatus.booked:
      case SpaceStatus.used:
        return Colors.white;
      default: // Should not be reached if all enum values are covered
        return Colors.black87;
    }
  }

  String _getTextForStatus(SpaceStatus status, {bool short = false}) {
    if (short) {
      switch (status) {
        case SpaceStatus.available:
          return "Free";
        case SpaceStatus.booked:
          return "Res"; // Reserved
        case SpaceStatus.used:
          return "Occ"; // Occupied
        case SpaceStatus.pendingApproval:
          return "Pend";
        case SpaceStatus.maintenance:
          return "Maint";
        case SpaceStatus.unknown:
          return "N/A";
      }
    }
    // Assuming SpaceStatus enum has a displayName getter
    // e.g., enum SpaceStatus { available; String get displayName => "Available"; }
    return status.displayName;
  }

  void _onSpaceSelected(CemeterySpace space) {
    if (space.status == SpaceStatus.available) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpaceBookingDetailsPage(
            cemetery: widget.cemetery,
            selectedSpace: space,
          ),
        ),
      ).then((bookingResult) {
        if (bookingResult == true && mounted) {
          // Data will refresh via stream if active, or manually if not
          if (_spacesSubscription == null) {
            _fetchCemeterySpacesFromSupabase();
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Space ${space.spaceIdentifier} is ${_getTextForStatus(space.status)} and cannot be selected for booking.',
            style: TextStyle(color: _getTextColorForStatus(space.status)),
          ),
          backgroundColor: _getColorForStatus(space.status),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildLegendItem(SpaceStatus status) {
    bool isSelected = _selectedFilterStatus == status;
    return InkWell(
      onTap: () => _onFilterChanged(status),
      borderRadius:
          BorderRadius.circular(AppStyles.buttonBorderRadius.topLeft.x),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.appBar.withOpacity(0.2)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(AppStyles.buttonBorderRadius.topLeft.x),
          border: isSelected
              ? Border.all(color: AppColors.appBar, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _getColorForStatus(status),
                border: Border.all(
                    color: Colors.black54.withOpacity(0.5), width: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _getTextForStatus(status),
              style: AppStyles.caption.copyWith(
                fontSize: 13,
                color: isSelected ? AppColors.appBar : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _spacesSubscription?.cancel(); // Cancel stream subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'All Spaces: ${widget.cemetery.name}',
          style: AppStyles.appBarTitleStyle,
        ),
        backgroundColor: AppColors.appBar,
        elevation: AppStyles.elevationLow,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.cardBackground,
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            child: Column(
              children: [
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.center,
                  children: SpaceStatus.values
                      .where((s) => s != SpaceStatus.unknown)
                      .map((status) => _buildLegendItem(status))
                      .toList(),
                ),
                if (_selectedFilterStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ActionChip(
                      avatar:
                          Icon(Icons.clear, size: 16, color: AppColors.appBar),
                      label: Text(
                        'Clear Filter (${_getTextForStatus(_selectedFilterStatus!)})',
                        style:
                            AppStyles.caption.copyWith(color: AppColors.appBar),
                      ),
                      onPressed: () => _onFilterChanged(null),
                      backgroundColor: AppColors.appBar.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(
              height: 1, thickness: 0.5, color: AppColors.progressBarTrack),
          Expanded(
            child: _isLoading &&
                    _spaces
                        .isEmpty // Show loading only if spaces haven't loaded yet
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.appBar))
                : _errorMessage != null &&
                        _spaces
                            .isEmpty // Show error if spaces are empty AND error exists
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                style: AppStyles.bodyText1
                                    .copyWith(color: AppColors.errorColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _fetchCemeterySpacesFromSupabase,
                                child: const Text("Retry"),
                              )
                            ],
                          ),
                        ),
                      )
                    : _spaces
                            .isEmpty // No spaces fetched at all (after loading/no error)
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No spaces are currently listed for ${widget.cemetery.name}.',
                                textAlign: TextAlign.center,
                                style: AppStyles.bodyText1
                                    .copyWith(color: AppColors.secondaryText),
                              ),
                            ),
                          )
                        : _filteredSpaces.isEmpty &&
                                _selectedFilterStatus != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'No spaces match the filter: "${_getTextForStatus(_selectedFilterStatus!)}".',
                                    textAlign: TextAlign.center,
                                    style: AppStyles.bodyText1.copyWith(
                                        color: AppColors.secondaryText),
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _fetchCemeterySpacesFromSupabase,
                                color: AppColors.appBar,
                                child: ListView.builder(
                                  itemCount: _filteredSpaces.length,
                                  itemBuilder: (context, index) {
                                    final space = _filteredSpaces[index];
                                    final statusColor =
                                        _getColorForStatus(space.status);
                                    final textColor =
                                        _getTextColorForStatus(space.status);
                                    bool isAvailable =
                                        space.status == SpaceStatus.available;

                                    return Card(
                                      elevation: 1.5,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 6.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        side: BorderSide(
                                          color: isAvailable
                                              ? AppColors.buttonBackground
                                              : statusColor.withOpacity(0.7),
                                          width: isAvailable ? 1.2 : 0.8,
                                        ),
                                      ),
                                      child: ListTile(
                                        tileColor: isAvailable
                                            ? Colors.white
                                            : statusColor.withOpacity(0.05),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 12.0),
                                        leading: CircleAvatar(
                                          backgroundColor: statusColor,
                                          radius: 22,
                                          child: Icon(
                                            isAvailable
                                                ? Icons.check_circle_outline
                                                : space.status ==
                                                        SpaceStatus.booked
                                                    ? Icons.lock_clock_outlined
                                                    : space.status ==
                                                            SpaceStatus.used
                                                        ? Icons
                                                            .person_off_outlined
                                                        : space.status ==
                                                                SpaceStatus
                                                                    .pendingApproval
                                                            ? Icons
                                                                .hourglass_empty_outlined
                                                            : space.status ==
                                                                    SpaceStatus
                                                                        .maintenance
                                                                ? Icons
                                                                    .construction_outlined
                                                                : Icons
                                                                    .event_seat_outlined, // default for unknown
                                            color: textColor,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          'Space: ${space.spaceIdentifier}',
                                          style:
                                              AppStyles.cardTitleStyle.copyWith(
                                            fontSize: 16.5, // Slightly larger
                                            color: isAvailable
                                                ? AppColors.primaryText
                                                : AppColors.secondaryText,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            'Status: ${_getTextForStatus(space.status)}'
                                            '${space.plotType != null ? "\nType: ${space.plotType}" : ""}'
                                            '${space.dimensions != null ? "\nDimensions: ${space.dimensions}" : ""}',
                                            style: AppStyles.caption.copyWith(
                                                fontSize:
                                                    13.5, // Slightly larger
                                                color: statusColor,
                                                fontWeight: FontWeight.w500,
                                                height: 1.3),
                                          ),
                                        ),
                                        trailing: isAvailable
                                            ? Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 18,
                                                color: AppColors.appBar)
                                            : null,
                                        onTap: isAvailable
                                            ? () => _onSpaceSelected(space)
                                            : null,
                                        enabled: isAvailable,
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
