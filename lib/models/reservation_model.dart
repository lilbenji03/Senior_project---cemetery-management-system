// lib/models/reservation_model.dart
// Ensure PaymentMethod and ReservationStatus enums are defined here.
// If SpotStatus is needed for updates, it should be imported from spot_model.dart

enum PaymentMethod { mpesa, card, bank } // Example

enum ReservationStatus {
  pendingApproval,
  approved,
  rejected,
  expired,
  paymentPending,
  completed,
  cancelled,
}

class Reservation {
  final String id; // Supabase UUID for the reservation
  final String userId; // User who made the reservation
  final String cemeteryId;
  final String cemeterySpotId; // PK of the spot from cemetery_spots
  final String spotIdentifier; // User-facing spot ID like "LA01"
  final String cemeteryName; // Denormalized
  String plotType;
  ReservationStatus status;
  final DateTime requestedAt;
  DateTime? approvedAt;
  DateTime? expiresAt;
  final double estimatedCost; // This is estimated_plot_cost from your DB
  String? burialPermitNumber;
  DateTime? selectedBurialDate;
  String? deceasedName; // For whom the reservation is

  // Fields fetched via JOIN for admin/staff display
  final String? userFullName;
  final String? userEmail;

  // You might add other fields from your 'reservations' table if needed
  // final double? finalTotalCost;
  // final String? paymentMethodUsed; // The string value of PaymentMethod enum
  // final String? staffNotes;

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
    this.selectedBurialDate,
    this.deceasedName,
    this.userFullName, // Can be null if profile data is not joined/found
    this.userEmail, // Can be null
    // this.finalTotalCost,
    // this.paymentMethodUsed,
    // this.staffNotes,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final profileData =
        json['profiles']
            as Map<String, dynamic>?; // Joined data from profiles table

    return Reservation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cemeteryId: json['cemetery_id'] as String,
      cemeterySpotId: json['cemetery_spot_id'] as String, // PK of the spot
      spotIdentifier: json['spot_identifier'] as String? ?? 'N/A',
      cemeteryName: json['cemetery_name'] as String? ?? 'Unknown Cemetery',
      plotType: json['plot_type'] as String? ?? 'Unknown',
      status: ReservationStatus.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['status'] as String? ?? 'pendingApproval').toLowerCase(),
        orElse: () => ReservationStatus.pendingApproval,
      ),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'] as String)
              : null,
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'] as String)
              : null,
      estimatedCost: (json['estimated_plot_cost'] as num?)?.toDouble() ?? 0.0,
      burialPermitNumber: json['burial_permit_number'] as String?,
      selectedBurialDate:
          json['selected_burial_date'] != null
              ? DateTime.parse(json['selected_burial_date'] as String)
              : null,
      deceasedName: json['deceased_name'] as String?,
      userFullName:
          profileData?['full_name'] as String?, // Access joined data safely
      userEmail: profileData?['email'] as String?, // Access joined data safely
      // finalTotalCost: (json['final_total_cost'] as num?)?.toDouble(),
      // paymentMethodUsed: json['payment_method'] as String?,
      // staffNotes: json['staff_notes'] as String?,
    );
  }

  // toJsonForUpdate (if staff update reservations from their view)
  Map<String, dynamic> toJsonForAdminUpdate() {
    // Potentially a different toJson for admin updates
    return {
      'status': status.name, // Use .name for enum string value
      'approved_at': approvedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      // Admin might update these:
      'burial_permit_number': burialPermitNumber,
      'selected_burial_date': selectedBurialDate?.toIso8601String(),
      'deceased_name': deceasedName,
      // 'staff_notes': staffNotes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// Remove sampleReservations from here if fetching from Supabase in ReservationPage
// List<Reservation> sampleReservations = [ ... ];
