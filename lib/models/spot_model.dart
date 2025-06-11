// lib/models/spot_model.dart
import 'package:flutter/foundation.dart' show immutable; // For @immutable

// Enum for the status of a cemetery spot.
// Keep this concise and ensure string values match what's stored in Supabase.
enum SpotStatus {
  available,
  booked,
  used,
  pendingApproval,
  maintenance, // Example: Added a potential new status
  unknown; // Fallback for unexpected status strings from DB

  // Helper to get a display string (optional, can also be done in UI)
  String get displayName {
    switch (this) {
      case SpotStatus.available:
        return 'Available';
      case SpotStatus.booked:
        return 'Booked';
      case SpotStatus.used:
        return 'Used';
      case SpotStatus.pendingApproval:
        return 'Pending Approval';
      case SpotStatus.maintenance:
        return 'Under Maintenance';
      case SpotStatus.unknown:
        return 'Unknown Status';
    }
  }

  // Helper to get the string value for storing in Supabase
  String toJson() =>
      name; // 'name' gives the enum value as a string, e.g., "available"

  // Helper to create SpotStatus from a string (e.g., from Supabase)
  static SpotStatus fromJson(String? statusString) {
    if (statusString == null) return SpotStatus.unknown;
    try {
      return SpotStatus.values.byName(statusString.toLowerCase());
    } catch (_) {
      // If the string from DB doesn't match any enum value
      return SpotStatus.unknown;
    }
  }
}

@immutable // Indicates that instances of this class are immutable once created
class CemeterySpot {
  // Primary Key from the 'cemetery_spots' table in Supabase (typically a UUID).
  // This is essential for uniquely identifying the record for updates/deletes.
  final String databaseId;

  // User-facing identifier for the spot within a specific cemetery (e.g., "LA01", "A-102").
  // This comes from your 'spot_identifier' column in Supabase.
  final String spotIdentifier;

  // Foreign Key linking this spot to a specific cemetery in the 'cemeteries' table.
  final String cemeteryId;

  // The current status of the spot.
  final SpotStatus status;

  // The type of plot (e.g., "Permanent", "Temporary", "Adult", "Child").
  // Nullable as it might not always be set or applicable.
  final String? plotType;

  // You can add other relevant fields from your 'cemetery_spots' table here as needed:
  // final String? dimensions;
  // final String? notes;
  // final DateTime? lastStatusUpdate; // If you track when the status was last changed

  const CemeterySpot({
    required this.databaseId,
    required this.spotIdentifier,
    required this.cemeteryId,
    required this.status,
    this.plotType,
    // this.dimensions,
    // this.notes,
    // this.lastStatusUpdate,
  });

  // Factory constructor to create a CemeterySpot instance from a JSON map (e.g., data from Supabase).
  factory CemeterySpot.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['cemetery_id'] == null) {
      // Or handle more gracefully depending on your app's needs
      throw FormatException(
        "Required fields 'id' or 'cemetery_id' are missing in CemeterySpot JSON: $json",
      );
    }
    return CemeterySpot(
      databaseId:
          json['id'] as String, // Assuming your PK column in Supabase is 'id'
      spotIdentifier:
          json['spot_identifier'] as String? ?? 'N/A', // User-visible ID
      cemeteryId: json['cemetery_id'] as String,
      status: SpotStatus.fromJson(
        json['status'] as String?,
      ), // Use the helper for safer parsing
      plotType: json['plot_type'] as String?,
      // dimensions: json['dimensions'] as String?,
      // notes: json['notes'] as String?,
      // lastStatusUpdate: json['last_status_update'] != null
      //     ? DateTime.tryParse(json['last_status_update'] as String)
      //     : null,
    );
  }

  // Method to convert a CemeterySpot instance to a JSON map,
  // useful for sending data to Supabase (e.g., for updates).
  // Only include fields that you intend to update.
  Map<String, dynamic> toJsonForUpdate() {
    return {
      // 'id': databaseId, // Typically, you don't update the PK. Use .eq('id', databaseId) in Supabase.
      // 'spot_identifier': spotIdentifier, // Usually not updated, or handled carefully.
      // 'cemetery_id': cemeteryId, // Usually not updated.
      'status': status.toJson(), // Use the helper to get the string value
      'plot_type': plotType,
      // 'dimensions': dimensions,
      // 'notes': notes,
      // 'updated_at': DateTime.now().toIso8601String(), // If you manage updated_at on client
    };
  }

  // Optional: A copyWith method for easily creating modified instances (good for state management).
  CemeterySpot copyWith({
    String? databaseId,
    String? spotIdentifier,
    String? cemeteryId,
    SpotStatus? status,
    String? plotType,
    // Add other fields here
  }) {
    return CemeterySpot(
      databaseId: databaseId ?? this.databaseId,
      spotIdentifier: spotIdentifier ?? this.spotIdentifier,
      cemeteryId: cemeteryId ?? this.cemeteryId,
      status: status ?? this.status,
      plotType: plotType ?? this.plotType,
      // ... and for other fields
    );
  }

  // Optional: Override '==' and 'hashCode' for proper object comparison if you store these in Sets or use them as Map keys.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CemeterySpot &&
          runtimeType == other.runtimeType &&
          databaseId == other.databaseId &&
          spotIdentifier == other.spotIdentifier &&
          cemeteryId == other.cemeteryId;

  @override
  int get hashCode =>
      databaseId.hashCode ^ spotIdentifier.hashCode ^ cemeteryId.hashCode;

  get id => null;

  get dbId => null;

  get sectionName => null;

  @override
  String toString() {
    return 'CemeterySpot(dbId: $databaseId, id: $spotIdentifier, cemeteryId: $cemeteryId, status: $status, plotType: $plotType)';
  }
}

// IMPORTANT: Remove the old `getSampleSpotsForCemetery` function from this file.
// Data fetching (even sample data for UI development) should ideally be handled
// in a service layer or directly within the widget's state for temporary purposes,
// not as a global function in a model file if it's meant to be replaced by backend calls.
//
// If you still need sample data for UI development *before* Supabase is fully integrated
// for fetching spots, consider placing such a function in a separate test_data.dart file
// or within the initState of the page that needs it.
