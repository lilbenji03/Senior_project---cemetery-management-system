// lib/models/reservation_model.dart
enum ReservationStatus {
  pendingApproval,
  approved,
  rejected,
  expired,
  paymentPending,
  completed,
  cancelled,
}

enum PaymentMethod { mpesa, card, bank } // Already in your ReservationPage

class Reservation {
  final String id; // Supabase UUID
  final String userId;
  final String cemeteryId;
  final String cemeterySpotId; // PK of the spot from cemetery_spots table
  final String spotIdentifier; // User-facing spot ID like "LA01"
  final String cemeteryName; // Denormalized for convenience
  String plotType;
  ReservationStatus status;
  DateTime requestedAt;
  DateTime? approvedAt;
  DateTime? expiresAt; // For payment window
  double estimatedCost; // Plot cost
  String? burialPermitNumber;
  // Add other fields like selected services, total cost etc.

  Reservation({
    required this.id,
    required this.userId,
    required this.cemeteryId,
    required this.cemeterySpotId,
    required this.spotIdentifier,
    required this.cemeteryName,
    required this.plotType,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.expiresAt,
    required this.estimatedCost,
    this.burialPermitNumber,
  });

  // fromJson and toJson would be useful here
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cemeteryId: json['cemetery_id'] as String,
      cemeterySpotId: json['cemetery_spot_id'] as String,
      spotIdentifier: json['spot_identifier'] as String? ?? 'N/A',
      cemeteryName: json['cemetery_name'] as String? ?? 'N/A',
      plotType: json['plot_type'] as String? ?? 'Unknown',
      status: ReservationStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            (json['status'] as String? ?? 'pendingApproval').toLowerCase(),
        orElse: () => ReservationStatus.pendingApproval,
      ),
      requestedAt:
          DateTime.tryParse(json['requested_at'] as String? ?? '') ??
          DateTime.now(),
      approvedAt: DateTime.tryParse(json['approved_at'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      estimatedCost: (json['estimated_plot_cost'] as num?)?.toDouble() ?? 0.0,
      burialPermitNumber: json['burial_permit_number'] as String?,
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    // For creating a new reservation
    return {
      'user_id': userId,
      'cemetery_id': cemeteryId,
      'cemetery_spot_id': cemeterySpotId,
      'spot_identifier': spotIdentifier,
      'cemetery_name': cemeteryName,
      'plot_type': plotType,
      'status': status.toString().split('.').last, // Store enum as string
      'requested_at': requestedAt.toIso8601String(),
      'estimated_plot_cost': estimatedCost,
      'burial_permit_number': burialPermitNumber,
      // expires_at and approved_at usually set by backend/staff
    };
  }
}
// Remove sampleReservations from here if it was in your model file