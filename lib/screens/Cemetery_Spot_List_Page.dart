// lib/screens/cemetery_spot_list_page.dart
import 'package:cmc/screens/space_booking_details_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../models/cemetery_model.dart';
import '../models/spot_model.dart'; // Your spot model (which no longer has getSampleSpotsForCemetery)
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

// Access global Supabase client instance (ensure it's initialized in main.dart)
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

  @override
  void initState() {
    super.initState();
    _fetchCemeterySpotsFromSupabase(); // Call the Supabase fetching method
  }

  Future<void> _fetchCemeterySpotsFromSupabase() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch spots from your 'cemetery_spots' table in Supabase
      final List<dynamic> response = await supabase
          .from(
            'cemetery_spots',
          ) // MAKE SURE 'cemetery_spots' IS YOUR ACTUAL TABLE NAME
          .select() // Select all columns, or be specific: 'id, spot_identifier, status, plot_type, cemetery_id'
          .eq(
            'cemetery_id',
            widget.cemetery.id,
          ) // Filter by the passed cemetery's ID
          .order(
            'spot_identifier',
            ascending: true,
          ); // Example: order by the spot's display ID

      // The 'response' variable here is a List<Map<String, dynamic>> if successful

      if (mounted) {
        setState(() {
          // Map the Supabase data to your CemeterySpot model
          _spots = response.map((data) => CemeterySpot.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // print("Error fetching spots from Supabase: $e");
        setState(() {
          _errorMessage =
              "Failed to load spots. Please try again. (${e.toString()})";
          _isLoading = false;
          _spots = []; // Clear spots on error
        });
      }
    }
  }

  // ... (Your existing _getColorForStatus, _getTextColorForStatus, _onSpotSelected, _buildLegendItem methods are fine)
  Color _getColorForStatus(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return Colors.green.shade300;
      case SpotStatus.pendingApproval:
        return Colors.yellow.shade700;
      case SpotStatus.booked:
        return const Color.fromARGB(255, 68, 40, 6);
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
      default:
        return "N/A";
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
                selectedSpot: spot,
              ),
        ),
      ).then((bookingResult) {
        if (bookingResult == true && mounted) {
          _fetchCemeterySpotsFromSupabase();
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
                          'No spots are currently listed for ${widget.cemetery.name}.\nThis could be an error or all spots are configured.',
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
                        key: ValueKey(
                          widget.cemetery.id + _spots.length.toString(),
                        ),
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
