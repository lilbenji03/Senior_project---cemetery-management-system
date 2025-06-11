// lib/screens/cemetery_spot_list_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cemetery_model.dart';
import '../models/spot_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'space_booking_details_page.dart';

final supabase = Supabase.instance.client;

class CemeterySpotListPage extends StatefulWidget {
  final Cemetery cemetery;
  const CemeterySpotListPage({super.key, required this.cemetery});

  @override
  State<CemeterySpotListPage> createState() => _CemeterySpotListPageState();
}

class _CemeterySpotListPageState extends State<CemeterySpotListPage> {
  List<CemeterySpot> _spots = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _spotsSubscription;

  SpotStatus? _selectedFilterStatus;
  List<CemeterySpot> _filteredSpots = [];

  @override
  void initState() {
    super.initState();
    _initializeAndSubscribeToSpots();
  }

  Future<void> _initializeAndSubscribeToSpots() async {
    // ... (Keep this method as it was, fetching from Supabase and setting up the stream)
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<dynamic> initialData = await supabase
          .from('cemetery_spots')
          .select()
          .eq('cemetery_id', widget.cemetery.id)
          .order('spot_identifier', ascending: true);
      if (mounted) {
        _updateSpotsList(
          initialData.map((data) => CemeterySpot.fromJson(data)).toList(),
        );
        _isLoading = false;
      }
      _spotsSubscription = supabase
          .from('cemetery_spots')
          .stream(primaryKey: ['id'])
          .eq('cemetery_id', widget.cemetery.id)
          .order('spot_identifier', ascending: true)
          .listen(
            (List<Map<String, dynamic>> data) {
              if (mounted) {
                _updateSpotsList(
                  data.map((item) => CemeterySpot.fromJson(item)).toList(),
                );
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _errorMessage = "Realtime error: ${error.toString()}";
                  _isLoading = false;
                });
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load spots: ${e.toString()}";
          _isLoading = false;
          _spots = [];
          _filteredSpots = [];
        });
      }
    }
  }

  void _updateSpotsList(List<CemeterySpot> newSpots) {
    setState(() {
      _spots = newSpots;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_selectedFilterStatus == null) {
      _filteredSpots = List.from(_spots);
    } else {
      _filteredSpots =
          _spots.where((spot) => spot.status == _selectedFilterStatus).toList();
    }
  }

  void _onFilterChanged(SpotStatus? newStatus) {
    setState(() {
      _selectedFilterStatus = newStatus;
      _applyFilter();
    });
  }

  @override
  void dispose() {
    _spotsSubscription?.cancel();
    super.dispose();
  }

  Color _getColorForStatus(SpotStatus status) {
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
        return Colors.blueGrey.shade300;
      case SpotStatus.unknown:
        return Colors.black26;
    }
  }

  Color _getTextColorForStatus(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
      case SpotStatus.pendingApproval:
      case SpotStatus.maintenance:
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  String _getTextForStatus(SpotStatus status, {bool short = false}) {
    // Use the displayName from the enum for consistency
    if (short) {
      switch (status) {
        case SpotStatus.available:
          return "Free";
        case SpotStatus.booked:
          return "Res";
        case SpotStatus.used:
          return "Occ";
        case SpotStatus.pendingApproval:
          return "Pend";
        case SpotStatus.maintenance:
          return "Maint";
        case SpotStatus.unknown:
          return "N/A";
      }
    }
    return status.displayName;
  }

  void _onSpotSelected(CemeterySpot spot) {
    if (spot.status == SpotStatus.available) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SpotBookingDetailsPage(
                cemetery: widget.cemetery,
                selectedSpot: spot,
              ),
        ),
      ).then((bookingResult) {
        if (bookingResult == true && mounted) {
          _initializeAndSubscribeToSpots(); // Refresh data after booking attempt
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Spot ${spot.spotIdentifier} is ${_getTextForStatus(spot.status)} and cannot be selected.',
              style: TextStyle(color: _getTextColorForStatus(spot.status)),
            ), // Use spotIdentifier
            backgroundColor: _getColorForStatus(spot.status),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Widget _buildLegendItem(SpotStatus status) {
    return GestureDetector(
      onTap: () => _onFilterChanged(status),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getColorForStatus(status),
                border: Border.all(
                  color: Colors.black54.withOpacity(0.5),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow:
                    _selectedFilterStatus == status
                        ? [
                          BoxShadow(
                            color: AppColors.appBar.withOpacity(0.5),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ]
                        : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _getTextForStatus(status),
              style: AppStyles.caption.copyWith(
                fontSize: 13,
                color: AppColors.secondaryText,
                fontWeight:
                    _selectedFilterStatus == status
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Book Spot: ${widget.cemetery.name}',
          style: AppStyles.appBarTitleStyle,
        ),
        backgroundColor: AppColors.appBar,
        elevation: AppStyles.elevationLow,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.cardBackground,
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 8.0,
            ),
            child: Column(
              children: [
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.center,
                  children:
                      SpotStatus.values
                          .where((s) => s != SpotStatus.unknown)
                          .map((status) => _buildLegendItem(status))
                          .toList(),
                ),
                if (_selectedFilterStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ActionChip(
                      avatar: Icon(
                        Icons.clear,
                        size: 16,
                        color: AppColors.appBar,
                      ),
                      label: Text(
                        'Clear Filter (${_getTextForStatus(_selectedFilterStatus!)})',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.appBar,
                        ),
                      ),
                      onPressed: () => _onFilterChanged(null),
                      backgroundColor: AppColors.appBar.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.progressBarTrack,
          ),
          Expanded(
            child:
                _isLoading && _spots.isEmpty
                    ? const Center(
                      child: CircularProgressIndicator(color: AppColors.appBar),
                    )
                    : _errorMessage != null
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No spots are currently listed for ${widget.cemetery.name}.\nThis could be an error or all spots are configured.',
                          textAlign: TextAlign.center,
                          style: AppStyles.bodyText1.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    )
                    : _filteredSpots.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No spots match the filter: "${_getTextForStatus(_selectedFilterStatus!)}".',
                          textAlign: TextAlign.center,
                          style: AppStyles.bodyText1.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    )
                    : GridView.builder(
                      key: ValueKey(
                        widget.cemetery.id +
                            (_selectedFilterStatus?.toString() ?? "all") +
                            _spots.length.toString(),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 600 ? 10 : 7,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 5.0,
                        mainAxisSpacing: 5.0,
                      ),
                      itemCount: _filteredSpots.length, // Use filtered list
                      itemBuilder: (context, index) {
                        final spot = _filteredSpots[index]; // Use filtered list
                        final textColor = _getTextColorForStatus(spot.status);
                        return GestureDetector(
                          onTap: () => _onSpotSelected(spot),
                          child: Tooltip(
                            // CORRECTED: Use spot.spotIdentifier
                            message:
                                '${spot.spotIdentifier}\nStatus: ${_getTextForStatus(spot.status)}\n${spot.plotType != null ? "Type: ${spot.plotType}" : ""}',
                            child: Card(
                              elevation: 1.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              color: _getColorForStatus(spot.status),
                              child: Container(
                                padding: const EdgeInsets.all(2.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.3),
                                    width: 0.6,
                                  ),
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        spot.spotIdentifier, // <--- CORRECTED: Was spot.id
                                        style: TextStyle(
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        _getTextForStatus(
                                          spot.status,
                                          short: true,
                                        ),
                                        style: TextStyle(
                                          fontSize: 7.0,
                                          color: textColor.withOpacity(0.9),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
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
