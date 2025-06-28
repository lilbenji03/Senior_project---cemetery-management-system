// lib/widgets/cemetery_card.dart
import 'package:flutter/material.dart';
import '../models/cemetery_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
// Note: The direct import to 'cemetery_space_list_page.dart' is no longer needed here,
// as the parent page will handle the navigation.

class CemeteryCard extends StatelessWidget {
  final Cemetery cemetery;
  // =======================================================================
  // ===                 *** THIS IS THE KEY CHANGE ***                  ===
  // =======================================================================
  // Add a VoidCallback parameter to accept the navigation function from the parent.
  final VoidCallback onBookSpacesPressed;
  // =======================================================================

  const CemeteryCard({
    super.key,
    required this.cemetery,
    required this.onBookSpacesPressed, // Make it a required parameter
  });

  @override
  Widget build(BuildContext context) {
    double progress = cemetery.totalSpaces > 0
        ? (cemetery.totalSpaces - cemetery.availableSpaces) /
            cemetery.totalSpaces
        : 0;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

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
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.appBar,
                    ),
                  ),
                );
              },
              errorBuilder: (context, exception, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: Colors.grey[600], size: 40),
                      const SizedBox(height: 4),
                      Text('Image unavailable',
                          style: AppStyles.caption
                              .copyWith(color: Colors.grey[600])),
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
                    style: AppStyles.caption
                        .copyWith(fontSize: 13, color: AppColors.secondaryText),
                  ),
                ],
                const SizedBox(height: 8.0),
                Text(
                  '${cemetery.availableSpaces} spaces available',
                  style: AppStyles.spotsAvailableStyle,
                ),
                const SizedBox(height: 12.0),
                if (cemetery.totalSpaces > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.progressBarTrack,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.progressBarFill),
                      minHeight: 10,
                    ),
                  ),
                if (cemetery.totalSpaces > 0) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    '${cemetery.totalSpaces - cemetery.availableSpaces} / ${cemetery.totalSpaces} occupied',
                    style: AppStyles.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.secondaryText.withOpacity(0.8)),
                  ),
                ],
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.event_seat_outlined, size: 18),
                      label: const Text('Book Spaces'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBackground,
                        foregroundColor: AppColors.buttonText,
                        textStyle: AppStyles.buttonTextStyle,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppStyles.buttonBorderRadius),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      // =================================================================
                      // ===               *** THIS IS THE KEY CHANGE ***              ===
                      // =================================================================
                      // Instead of handling navigation here, it now calls the function
                      // that was passed in from the parent widget.
                      onPressed: onBookSpacesPressed,
                      // =================================================================
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
