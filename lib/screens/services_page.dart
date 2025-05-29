// lib/screens/services_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/grave_care_service_model.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final List<GraveCareService> _services = sampleGraveCareServices;

  Future<void> _launchURL(String? urlString) async {
    // ... (your existing _launchURL method - no changes needed here)
    if (urlString == null || urlString.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No link available.')));
      return;
    }
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
    }
  }

  void _requestServiceInquiry(GraveCareService service) {
    // ... (your existing _requestServiceInquiry method - no changes needed here)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController phoneController = TextEditingController();
        final TextEditingController graveIdController = TextEditingController();
        final GlobalKey<FormState> formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: Text('Inquire about ${service.name}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    service.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estimated Cost: ${service.estimatedCostRange}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground.withOpacity(0.5),
                    ),
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Please enter your name'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Your Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground.withOpacity(0.5),
                    ),
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Please enter your phone number'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: graveIdController,
                    decoration: InputDecoration(
                      labelText:
                          'Grave Identifier (e.g., Deceased Name or Plot No.)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground.withOpacity(0.5),
                    ),
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Please provide a grave identifier'
                                : null,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appBar,
                foregroundColor: AppColors.buttonText,
              ),
              child: const Text('Submit Inquiry'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Inquiry for ${service.name} submitted for grave: ${graveIdController.text}. We will contact ${nameController.text} at ${phoneController.text}. (Simulated)',
                      ),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // REMOVED Scaffold and AppBar from here
    return Container(
      // Or directly the ListView
      color: AppColors.background,
      child: ListView.builder(
        padding: AppStyles.pagePadding,
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return Card(
            // ... (rest of your Card and its content - no changes needed inside the Card)
            elevation: AppStyles.elevationMedium,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.cardBorderRadius,
            ),
            child: Padding(
              padding: AppStyles.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: AppStyles.cardTitleStyle),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: AppStyles.bodyText1.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Est. Cost: ${service.estimatedCostRange}',
                    style: AppStyles.spotsAvailableStyle,
                  ),
                  if (service.contactPhoneNumber != null &&
                      service.contactPhoneNumber!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: AppColors.appBar, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap:
                                  () => _launchURL(
                                    'tel:${service.contactPhoneNumber}',
                                  ),
                              child: Text(
                                service.contactPhoneNumber!,
                                style: AppStyles.bodyText1.copyWith(
                                  fontSize: 14,
                                  color: AppColors.appBar,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (service.moreInfoLink != null &&
                          service.moreInfoLink!.isNotEmpty &&
                          service.type != GraveCareServiceType.memorialPage)
                        TextButton.icon(
                          icon: const Icon(
                            Icons.info_outline,
                            color: AppColors.appBar,
                            size: 20,
                          ),
                          label: const Text(
                            'More Info',
                            style: TextStyle(color: AppColors.appBar),
                          ),
                          onPressed: () => _launchURL(service.moreInfoLink),
                        ),
                      if (service.moreInfoLink != null &&
                          service.moreInfoLink!.isNotEmpty &&
                          service.type != GraveCareServiceType.memorialPage)
                        const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBackground,
                            foregroundColor: AppColors.buttonText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () => _requestServiceInquiry(service),
                          child: Text(
                            service.type == GraveCareServiceType.construction ||
                                    service.type ==
                                        GraveCareServiceType.memorialPage ||
                                    service.estimatedCostRange
                                        .toLowerCase()
                                        .contains('varies')
                                ? 'Request Quote/Inquire'
                                : 'Request Service',
                            textAlign: TextAlign.center,
                            style: AppStyles.button,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
