// lib/models/admin_reservation_model.dart
import 'reservation_model.dart'; // For Enums
import 'space_model.dart'; // For Enums

class AdminReservationModel {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String cemeteryId;
  final String cemeterySpaceId;
  final String spaceIdentifier;
  final String cemeteryName;
  final String plotType;
  final ReservationStatus status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? expiresAt;
  final double estimatedCost;
  final double? amountPaid;
  final PaymentMethod? paymentMethodUsed;
  final String? paymentReference;
  final String? burialPermitNumber;
  final DateTime? selectedBurialDate;
  final String? deceasedName;

  // Joined Data from the VIEW
  final String? userFullName;
  final String? userEmail;
  final String? userPhoneNumber;
  final String? managerName;

  AdminReservationModel({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.cemeteryId,
    required this.cemeterySpaceId,
    required this.spaceIdentifier,
    required this.cemeteryName,
    required this.plotType,
    required this.status,
    this.requestedAt,
    this.approvedAt,
    this.expiresAt,
    required this.estimatedCost,
    this.amountPaid,
    this.paymentMethodUsed,
    this.paymentReference,
    this.burialPermitNumber,
    this.selectedBurialDate,
    this.deceasedName,
    this.userFullName,
    this.userEmail,
    this.userPhoneNumber,
    this.managerName,
  });

  factory AdminReservationModel.fromJson(Map<String, dynamic> data) {
    // Helper function for safe date parsing
    DateTime? _parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      return DateTime.tryParse(dateString);
    }

    // Helper function for safe double parsing from any num type
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // This factory is now strict. It expects the VIEW to provide these fields.
    // If a field is missing, it will throw an error during development, which is good.
    return AdminReservationModel(
      id: data['id'],
      createdAt: DateTime.parse(data['created_at']),
      userId: data['user_id'],
      cemeteryId: data['cemetery_id'],
      cemeterySpaceId: data['cemetery_space_id'],
      spaceIdentifier: data['space_identifier'] ?? 'N/A',
      cemeteryName: data['cemetery_name'] ?? 'N/A',
      plotType: data['plot_type'] ?? 'N/A',
      status: ReservationStatus.fromJson(data['status']),
      estimatedCost: _parseDouble(data['estimated_cost']) ?? 0.0,

      // Nullable fields
      requestedAt: _parseDate(data['requested_at']),
      approvedAt: _parseDate(data['approved_at']),
      expiresAt: _parseDate(data['expires_at']),
      selectedBurialDate: _parseDate(data['selected_burial_date']),
      amountPaid: _parseDouble(data['amount_paid']),
      paymentMethodUsed: PaymentMethod.fromJson(data['payment_method']),
      paymentReference: data['payment_reference'],
      burialPermitNumber: data['burial_permit_number'],
      deceasedName: data['deceased_name'],

      // Joined data fields (aliases must match the VIEW)
      userFullName: data['user_full_name'],
      userEmail: data['user_email'],
      userPhoneNumber: data['user_phone_number'],
      managerName: data['manager_name'],
    );
  }
}
