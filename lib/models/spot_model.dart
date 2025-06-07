// lib/models/spot_model.dart
enum SpotStatus { available, booked, used, pendingApproval } // Keep as is

class CemeterySpot {
  final String dbId; // Actual PK from Supabase (e.g., a UUID)
  final String
  id; // User-facing identifier like "LA01", "KA05" (this is 'spot_identifier' from DB)
  final String cemeteryId;
  SpotStatus status;
  String? plotType;
  // Add other fields from your Supabase 'cemetery_spots' table if needed

  CemeterySpot({
    required this.dbId,
    required this.id,
    required this.cemeteryId,
    required this.status,
    this.plotType,
  });

  factory CemeterySpot.fromJson(Map<String, dynamic> json) {
    return CemeterySpot(
      dbId: json['id'] as String, // Assumes your PK column is 'id'
      id: json['spot_identifier'] as String? ?? 'N/A', // The display ID
      cemeteryId: json['cemetery_id'] as String,
      status: SpotStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            (json['status'] as String? ?? 'available').toLowerCase(),
        orElse:
            () =>
                SpotStatus.available, // Default if status from DB is unexpected
      ),
      plotType: json['plot_type'] as String?,
    );
  }
}

// Remove 'getSampleSpotsForCemetery' function from here. It will be fetched.
