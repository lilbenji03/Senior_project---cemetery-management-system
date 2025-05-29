// lib/models/spot_model.dart

enum SpotStatus {
  available, // Grey
  booked, // Orange (A reservation exists, payment might be pending or confirmed but not yet "used")
  used, // Red (Burial has occurred)
  pendingApproval, // Yellow (User requested, staff needs to approve)
}

class CemeterySpot {
  final String id; // e.g., "A-01", "B-12"
  final String cemeteryId;
  SpotStatus status;
  String? plotType; // 'Permanent' or 'Temporary', can be set after selection
  String? reservedByUserId; // ID of user who booked/reserved
  DateTime?
  reservationExpiry; // If status is booked/pending, when does it expire?
  String? deceasedName; // If status is used

  CemeterySpot({
    required this.id,
    required this.cemeteryId,
    required this.status,
    this.plotType,
    this.reservedByUserId,
    this.reservationExpiry,
    this.deceasedName,
  });
}

// Sample data generator for spots (replace with actual Supabase fetching)
List<CemeterySpot> getSampleSpotsForCemetery(String cemeteryId) {
  List<CemeterySpot> spots = [];
  int totalSpaces = 0;
  if (cemeteryId == '1') totalSpaces = 100; // Lang'ata
  if (cemeteryId == '2') totalSpaces = 80; // Kariokor
  if (cemeteryId == '3') totalSpaces = 150; // City Park

  for (int i = 1; i <= totalSpaces; i++) {
    String section = String.fromCharCode(
      (i % 5) + 65,
    ); // A, B, C, D, E sections
    String spaceNumber = (i % 20 + 1).toString().padLeft(2, '0');
    SpotStatus status;
    if (i <= totalSpaces * 0.5) {
      // 50% available
      status = SpotStatus.available;
    } else if (i <= totalSpaces * 0.7) {
      // 20% booked
      status = SpotStatus.booked;
    } else if (i <= totalSpaces * 0.9) {
      // 20% used
      status = SpotStatus.used;
    } else {
      // 10% pending
      status = SpotStatus.pendingApproval;
    }
    // Ensure that the number of "available" spots matches the Cemetery model's availableSpaces for consistency in this sample
    // This sample generation is very basic. Real data would come from Supabase.
    if (cemeteryId == '1' && i > 50 && status == SpotStatus.available) {
      status = SpotStatus.booked; // Adjust Lang'ata
    }
    if (cemeteryId == '2' && i > 20 && status == SpotStatus.available) {
      status = SpotStatus.booked; // Adjust Kariokor
    }
    if (cemeteryId == '3' && i > 75 && status == SpotStatus.available) {
      status = SpotStatus.booked; // Adjust City Park
    }

    spots.add(
      CemeterySpot(
        id: '$section-$spaceNumber',
        cemeteryId: cemeteryId,
        status: status,
      ),
    );
  }
  return spots;
}
