// lib/widgets/cemetery_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- IMPORT URL LAUNCHER
import '../models/cemetery_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../screens/cemetery_spot_list_page.dart';

class CemeteryCard extends StatelessWidget {
  final Cemetery cemetery;

  const CemeteryCard({super.key, required this.cemetery});

  // Helper function to launch maps
  Future<void> _launchMapsUrl(
    BuildContext context,
    double? lat,
    double? lon,
    String cemeteryName,
  ) async {
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location coordinates not available for $cemeteryName.',
          ),
        ),
      );
      return;
    }

    // Universal Google Maps URL for directions from current location
    // saddr (source address) is implicitly current location if not specified on mobile
    // daddr (destination address) is the latitude,longitude
    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';

    // For iOS, you might prefer to offer Apple Maps if available
    // final String appleMapsUrl = 'https://maps.apple.com/?daddr=$lat,$lon&dirflg=d';

    final Uri uri = Uri.parse(googleMapsUrl); // Default to Google Maps

    // Alternative using platform check (more robust)
    // String mapUrl;
    // if (Platform.isIOS) {
    //   mapUrl = 'https://maps.apple.com/?daddr=$lat,$lon&dirflg=d&q=$cemeteryName';
    // } else { // Android and other platforms
    //   mapUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving';
    // }
    // final Uri uri = Uri.parse(mapUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch maps to $cemeteryName. Please ensure you have a map application installed.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress =
        cemetery.totalSpots > 0
            ? (cemetery.totalSpots - cemetery.availableSpots) /
                cemetery.totalSpots
            : 0;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    const String fallbackImageUrl =
        'https://via.placeholder.com/400x200.png?text=No+Image+Available';

    return Card(
      elevation: AppStyles.elevationLow,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: AppStyles.cardBorderRadius.topLeft,
              topRight: AppStyles.cardBorderRadius.topRight,
            ),
            child: Image.network(
              /* ... image loading as before ... */ cemetery.imageUrl,
            ),
          ),
          Padding(
            padding: AppStyles.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cemetery.name, style: AppStyles.cardTitleStyle),
                if (cemetery.locationDescription != null &&
                    cemetery.locationDescription!.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    cemetery.locationDescription!,
                    style: AppStyles.caption.copyWith(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: 8.0),
                Text(
                  '${cemetery.availableSpots} spots available',
                  style: AppStyles.spotsAvailableStyle,
                ),
                const SizedBox(height: 12.0),
                if (cemetery.totalSpots > 0)
                  ClipRRect(/* ... progress bar ... */),
                if (cemetery.totalSpots > 0) const SizedBox(height: 4.0),
                if (cemetery.totalSpots > 0)
                  Text(
                    '${cemetery.totalSpots - cemetery.availableSpots} / ${cemetery.totalSpots} occupied',
                    style: AppStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.secondaryText.withOpacity(0.8),
                    ),
                  ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.directions_outlined, size: 20),
                      label: const Text('Directions'),
                      onPressed: () {
                        // Use the helper function to launch maps
                        _launchMapsUrl(
                          context,
                          cemetery.latitude,
                          cemetery.longitude,
                          cemetery.name,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.event_seat_outlined, size: 18),
                      label: const Text('Book Spot'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    CemeterySpotListPage(cemetery: cemetery),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
