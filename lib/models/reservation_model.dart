// lib/models/reservation_model.dart
// Assuming SpotStatus is here

enum ReservationStatus {
  pendingApproval,
  approved,
  rejected,
  expired,
  paymentPending, // After approval, before payment
  completed, // Paid and finalized
}

class Reservation {
  final String id;
  final String cemeteryName;
  final String spotId;
  final String plotType; // 'Permanent' or 'Temporary'
  final double estimatedCost;
  final ReservationStatus status;
  final DateTime requestedAt;
  DateTime? approvedAt; // When the staff approved it
  DateTime?
      expiresAt; // For approved reservations (e.g., 2 hours after approval)
  String? burialPermitNumber; // From user input

  Reservation({
    required this.id,
    required this.cemeteryName,
    required this.spotId,
    required this.plotType,
    required this.estimatedCost,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.expiresAt,
    this.burialPermitNumber,
  });
}

// --- Sample Data for ReservationPage (for testing) ---
// In a real app, this would come from a service or local storage
List<Reservation> sampleReservations = [
  Reservation(
    id: 'RES001',
    cemeteryName: 'Lang’ata Cemetery',
    spotId: 'LN-B03', // This was marked as pending in spot_model
    plotType: 'Permanent',
    estimatedCost: 30500.00,
    status: ReservationStatus.pendingApproval,
    requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
    burialPermitNumber: 'BP12345',
  ),
  Reservation(
    id: 'RES002',
    cemeteryName: 'Kariokor Cemetery',
    spotId: 'KR-A05',
    plotType: 'Temporary',
    estimatedCost: 7000.00,
    status: ReservationStatus.approved,
    requestedAt: DateTime.now().subtract(const Duration(days: 1)),
    approvedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    expiresAt: DateTime.now().add(
        const Duration(hours: 1, minutes: 30)), // Expires in 1.5 hours from now
    burialPermitNumber: 'BP67890',
  ),
  Reservation(
    id: 'RES003',
    cemeteryName: 'Lang’ata Cemetery',
    spotId: 'LN-D10',
    plotType: 'Permanent',
    estimatedCost: 30500.00,
    status: ReservationStatus.approved,
    requestedAt: DateTime.now().subtract(const Duration(hours: 3)),
    approvedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
    expiresAt: DateTime.now()
        .subtract(const Duration(minutes: 10)), // Expired 10 mins ago
    burialPermitNumber: 'BP11223',
  ),
  Reservation(
    id: 'RES004',
    cemeteryName: 'City Park Cemetery',
    spotId: 'CP-X01',
    plotType: 'Permanent',
    estimatedCost: 28000.00,
    status: ReservationStatus.rejected,
    requestedAt: DateTime.now().subtract(const Duration(days: 2)),
    burialPermitNumber: 'BP33445',
  ),
];
