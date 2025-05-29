import 'dart:io'; // For File type if you implement image picking
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // UNCOMMENT when you add image_picker
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReportType;
  final TextEditingController _detailsController = TextEditingController();
  File? _pickedImageFile; // To store the picked image file
  bool _isSubmitting = false;

  final List<String> _reportTypes = [
    'Maintenance Request', // More descriptive
    'Vandalism / Damage',
    'Safety Concern',
    'General Complaint',
    'Suggestion / Feedback',
    'Other Issue',
  ];

  // UNCOMMENT and implement when using image_picker
  // Future<void> _pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   try {
  //     final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
  //     if (image != null) {
  //       setState(() {
  //         _pickedImageFile = File(image.path);
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error picking image: $e')),
  //       );
  //     }
  //   }
  // }

  void _removeImage() {
    setState(() {
      _pickedImageFile = null;
    });
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Simulate submission delay
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual report submission logic here
      // String reportType = _selectedReportType!;
      // String details = _detailsController.text;
      // File? imageFile = _pickedImageFile;
      // Send this data to your backend or service.

      setState(() => _isSubmitting = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius,
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.spotsAvailable,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text('Report Submitted'),
                ],
              ),
              content: const Text(
                'Thank you for your report. We will review it shortly.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(color: AppColors.appBar),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        // Reset form
        _formKey.currentState!.reset();
        _detailsController.clear();
        setState(() {
          _selectedReportType = null;
          _pickedImageFile = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold or AppBar here, as it's part of MainScreen
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: AppStyles.pagePadding.copyWith(
          top: 20.0,
          bottom: 20.0,
        ), // Added top padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Report an Issue or Suggestion',
                style: AppStyles.cardTitleStyle.copyWith(
                  fontSize: 20,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Please provide details about any maintenance needs, complaints, or suggestions you have regarding the cemetery facilities or services.',
                style: AppStyles.bodyText2.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),

              // Section for Report Type
              _buildSectionContainer(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type of Report',
                    prefixIcon: Icon(Icons.category_outlined),
                    // Using global theme for border, fill, etc.
                  ),
                  value: _selectedReportType,
                  hint: const Text('Select report category'),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.appBar,
                  ),
                  items:
                      _reportTypes.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: AppStyles.bodyText1),
                        );
                      }).toList(),
                  onChanged:
                      (String? newValue) =>
                          setState(() => _selectedReportType = newValue),
                  validator:
                      (value) =>
                          value == null ? 'Please select a report type' : null,
                  style: AppStyles.bodyText1, // For selected item style
                ),
              ),
              const SizedBox(height: 16.0),

              // Section for Details
              _buildSectionContainer(
                child: TextFormField(
                  controller: _detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Description',
                    hintText: 'Please provide as much detail as possible...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true, // Good for multiline
                  ),
                  maxLines: 6,
                  minLines: 4,
                  style: AppStyles.bodyText1,
                  validator:
                      (value) =>
                          (value == null ||
                                  value.isEmpty ||
                                  value.trim().length < 10)
                              ? 'Please enter at least 10 characters for details'
                              : null,
                ),
              ),
              const SizedBox(height: 16.0),

              // Section for Attachment
              _buildSectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attach Photo (Optional)',
                      style: AppStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    GestureDetector(
                      // onTap: _pickImage, // UNCOMMENT when image_picker is integrated
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image picking not yet implemented.'),
                          ),
                        );
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: AppStyles.cardBorderRadius,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child:
                            _pickedImageFile != null
                                ? Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    ClipRRect(
                                      // Ensure image is also rounded if container is
                                      borderRadius: AppStyles.cardBorderRadius,
                                      child: Image.file(
                                        _pickedImageFile!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        onPressed: _removeImage,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.appBar,
                                      size: 36,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Tap to add a photo',
                                      style: AppStyles.bodyText2.copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),

              // Submit Button
              _isSubmitting
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.appBar),
                  )
                  : ElevatedButton.icon(
                    icon: const Icon(Icons.send_outlined, size: 20),
                    label: const Text('Submit Report'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ), // Standard button height
                      // textStyle will come from global theme
                    ),
                    onPressed: _submitReport,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to wrap sections in a Card-like container for visual structure
  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppStyles.cardBorderRadius,
        boxShadow: AppStyles.cardBoxShadow,
      ),
      child: child,
    );
  }
}
