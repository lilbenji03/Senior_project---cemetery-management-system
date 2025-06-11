// lib/widgets/cemetery_card.dart
import 'package:flutter/material.dart';
import '../models/cemetery_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../screens/cemetery_spot_list_page.dart';

class CemeteryCard extends StatelessWidget {
  final Cemetery cemetery;

  const CemeteryCard({super.key, required this.cemetery});

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
              cemetery.imageUrl,
              height: 150,
              fit: BoxFit.cover,
              loadingBuilder: (
                BuildContext context,
                Widget child,
                ImageChunkEvent? loadingProgress,
              ) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      color: AppColors.appBar,
                    ),
                  ),
                );
              },
              errorBuilder: (
                BuildContext context,
                Object exception,
                StackTrace? stackTrace,
              ) {
                return Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: AppStyles.cardBorderRadius.topLeft,
                      topRight: AppStyles.cardBorderRadius.topRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey[600],
                        size: 40,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Image unavailable',
                        style: AppStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.progressBarTrack,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.progressBarFill,
                      ),
                      minHeight: 10,
                    ),
                  ),
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
                    // Directions button removed
                    ElevatedButton.icon(
                      icon: const Icon(Icons.event_seat_outlined, size: 18),
                      label: const Text('Book Spots'),
                      style: ElevatedButton.styleFrom(
                        // <<--- EXPLICIT STYLING ADDED/CONFIRMED
                        backgroundColor:
                            AppColors.buttonBackground, // Your desired green
                        foregroundColor:
                            AppColors
                                .buttonText, // Your desired text/icon color (e.g., white)
                        textStyle:
                            AppStyles
                                .buttonTextStyle, // Use consistent button text style
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              AppStyles
                                  .buttonBorderRadius, // Use consistent button border radius
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ), // Adjust padding if needed
                      ),
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
