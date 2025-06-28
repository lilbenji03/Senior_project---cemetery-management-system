// lib/screens/services_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For making phone calls
import '../models/grave_care_service_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  // Helper function to launch the phone dialer
  Future<void> _launchPhoneCall(
      String? phoneNumber, BuildContext context) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      // This case is handled by disabling the button, but it's good practice to keep it.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available.')),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not place a call to $phoneNumber'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: ListView.builder(
        padding: AppStyles.pagePadding.copyWith(top: 16, bottom: 24),
        itemCount: sampleGraveCareServices.length,
        itemBuilder: (context, index) {
          final service = sampleGraveCareServices[index];
          return _buildServiceCard(service, context);
        },
      ),
    );
  }

  Widget _buildServiceCard(GraveCareService service, BuildContext context) {
    bool canCall = service.contactPhoneNumber != null &&
        service.contactPhoneNumber!.isNotEmpty;

    return Card(
      elevation: AppStyles.elevationLow,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardBorderRadius),
      color: AppColors.cardBackground,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: AppStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Icon and Name ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(service.icon, size: 36, color: AppColors.appBar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name, style: AppStyles.cardTitleStyle),
                      if (service.providerExample != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Provider: ${service.providerExample}',
                            style: AppStyles.caption
                                .copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),

            // --- Description ---
            Text(service.description,
                style: AppStyles.bodyText1.copyWith(height: 1.4)),
            const SizedBox(height: 16),

            // --- Cost Information ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppStyles.buttonBorderRadius,
                border:
                    Border.all(color: AppColors.secondaryText.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.paid_outlined,
                      color: AppColors.spotsAvailable, size: 20),
                  const SizedBox(width: 8),
                  Text('Est. Cost: ',
                      style: AppStyles.bodyText1
                          .copyWith(fontWeight: FontWeight.w500)),
                  Expanded(
                    child: Text(
                      service.estimatedCostRange,
                      style: AppStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Simplified "Call Provider" Action Button ---
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_forwarded_rounded, size: 18),
                label: const Text('Contact Provider'),
                // The button is disabled if there's no phone number
                onPressed: canCall
                    ? () =>
                        _launchPhoneCall(service.contactPhoneNumber, context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  foregroundColor: AppColors.buttonText,
                  disabledBackgroundColor:
                      AppColors.secondaryText.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppStyles.buttonBorderRadius),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: AppStyles.buttonTextStyle,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
