// lib/screens/map_booking_page.dart
import 'package:cmc/screens/space_booking_details_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../models/cemetery_model.dart';
import '../models/spot_model.dart'; // For CemeterySpot and SpotStatus
import '../constants/app_colors.dart';
import '../constants/app_styles.dart'; // For navigation

final supabase = Supabase.instance.client;

class MapBookingPage extends StatefulWidget {
  final Cemetery cemetery;

  const MapBookingPage({super.key, required this.cemetery});

  @override
  State<MapBookingPage> createState() => _MapBookingPageState();
}

class _MapBookingPageState extends State<MapBookingPage> {
  List<CemeterySpot> _spots = [];
  bool _isLoading = true;
  String? _errorMessage;
  // CemeterySpot? _selectedSpot; // This state might now belong in SpotBookingDetailsPage

  @override
  void initState() {
    super.initState();
    _fetchCemeterySpotsFromSupabase();
  }

  Future<void> _fetchCemeterySpotsFromSupabase() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<dynamic> response = await supabase
          .from('cemetery_spots')
          .select() // Select all relevant columns for CemeterySpot.fromJson
          .eq('cemetery_id', widget.cemetery.id)
          .order('spot_identifier', ascending: true);

      if (mounted) {
        setState(() {
          _spots = response.map((data) => CemeterySpot.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load spots: ${e.toString()}";
          _isLoading = false;
          _spots = [];
        });
      }
    }
  }

  Color _getColorForStatus(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return Colors.green.shade300;
      case SpotStatus.pendingApproval:
        return Colors.yellow.shade700;
      case SpotStatus.booked:
        return const Color.fromARGB(255, 80, 47, 7);
      case SpotStatus.used:
        return Colors.red.shade700;
    }
  }

  Color _getTextColorForStatus(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
      case SpotStatus.pendingApproval:
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  String _getTextForStatus(SpotStatus status, {bool short = false}) {
    switch (status) {
      case SpotStatus.available:
        return short ? "Free" : "Available";
      case SpotStatus.booked:
        return short ? "Res" : "Booked";
      case SpotStatus.pendingApproval:
        return short ? "Pend" : "Pending";
      case SpotStatus.used:
        return short ? "Occ" : "Used";
      }
  }

  void _onSpotSelected(CemeterySpot spot) {
    if (spot.status == SpotStatus.available) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SpotBookingDetailsPage(
                cemetery: widget.cemetery,
                selectedSpot: spot, // Pass the actual spot object
              ),
        ),
      ).then((bookingResult) {
        if (bookingResult == true && mounted) {
          _fetchCemeterySpotsFromSupabase(); // Refresh
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Spot ${spot.id} is ${_getTextForStatus(spot.status)} and cannot be selected.',
            style: TextStyle(color: _getTextColorForStatus(spot.status)),
          ),
          backgroundColor: _getColorForStatus(spot.status),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildLegendItem(SpotStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _getColorForStatus(status),
              border: Border.all(
                color: Colors.black54.withOpacity(0.5),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _getTextForStatus(status),
            style: AppStyles.caption.copyWith(
              fontSize: 12.5,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If this page is still intended to show the grid of spots and then the booking form *below it*
    // then it needs its own Scaffold, AppBar, and the logic for the form fields, document checklist etc.
    // However, if the flow is CemeteryCard -> CemeterySpotListPage -> SpotBookingDetailsPage,
    // then this MapBookingPage might be redundant or needs a new purpose (e.g., actually showing an interactive map).

    // Assuming this page IS for displaying the grid of spots (like CemeterySpotListPage):
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
          // Legend
          Container(
            color: AppColors.cardBackground,
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 8.0,
            ),
            child: Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem(SpotStatus.available),
                _buildLegendItem(SpotStatus.booked),
                _buildLegendItem(SpotStatus.used),
                _buildLegendItem(SpotStatus.pendingApproval),
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
                _isLoading
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
                          'No spots are currently listed for ${widget.cemetery.name}.',
                          textAlign: TextAlign.center,
                          style: AppStyles.bodyText1.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchCemeterySpotsFromSupabase,
                      color: AppColors.appBar,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(10.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 10 : 7,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 5.0,
                          mainAxisSpacing: 5.0,
                        ),
                        itemCount: _spots.length,
                        itemBuilder: (context, index) {
                          final spot = _spots[index];
                          final textColor = _getTextColorForStatus(spot.status);
                          return GestureDetector(
                            onTap: () => _onSpotSelected(spot),
                            child: Tooltip(
                              message:
                                  '${spot.id}\nStatus: ${_getTextForStatus(spot.status)}\n${spot.plotType != null ? "Type: ${spot.plotType}" : ""}',
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          spot.id,
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
          ),
        ],
      ),
    );
  }
}
