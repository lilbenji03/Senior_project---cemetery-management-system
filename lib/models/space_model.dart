// lib/models/space_model.dart
import 'package:flutter/foundation.dart' show immutable; // For @immutable

// Enum for the status of a cemetery space.
// Values should match what's stored in your Supabase 'status' column for cemetery_spaces.
enum SpaceStatus {
  available,
  booked,
  used,
  pendingApproval,
  maintenance,
  unknown; // Fallback for unexpected status strings from DB

  /// Provides a user-friendly display name for the status.
  String get displayName {
    switch (this) {
      case SpaceStatus.available:
        return 'Available';
      case SpaceStatus.booked:
        return 'Booked';
      case SpaceStatus.used:
        return 'Used'; // Or "Occupied"
      case SpaceStatus.pendingApproval:
        return 'Pending Approval';
      case SpaceStatus.maintenance:
        return 'Under Maintenance';
      case SpaceStatus.unknown:
      default: // Ensures all cases are handled, including any future additions if not updated here
        return 'Unknown Status';
    }
  }

  /// Converts the enum to its string representation for storing in Supabase.
  /// Uses the enum's 'name' property (e.g., "available", "booked").
  String toJson() => name;

  /// Creates a [SpaceStatus] from a string (e.g., from Supabase).
  /// It's case-insensitive and defaults to [unknown] if the string doesn't match.
  static SpaceStatus fromJson(String? statusString) {
    if (statusString == null || statusString.isEmpty) {
      return SpaceStatus.unknown;
    }
    try {
      // .byName is case-sensitive, so convert to lowercase for robustness
      return SpaceStatus.values.byName(statusString.toLowerCase().trim());
    } catch (_) {
      // If the string from DB doesn't match any enum value
      print(
        "Warning: Unknown SpaceStatus string received from DB: '$statusString'",
      );
      return SpaceStatus.unknown;
    }
  }
}

/// Represents a single cemetery space (formerly spot).
/// Instances of this class should be immutable.
@immutable
class CemeterySpace {
  /// Primary Key from the 'cemetery_spaces' table in Supabase (typically a UUID).
  /// Essential for uniquely identifying the record for updates/deletes.
  final String
      id; // Renamed from databaseId for convention (matches Supabase 'id' column)

  /// User-facing identifier for the space within a specific cemetery (e.g., "LA01", "A-102").
  /// This comes from your 'space_identifier' column in Supabase.
  final String spaceIdentifier;

  /// Foreign Key linking this space to a specific cemetery in the 'cemeteries' table.
  final String cemeteryId;

  /// The current status of the space.
  final SpaceStatus status;

  /// The type of plot (e.g., "Permanent", "Temporary", "Adult", "Child").
  /// Nullable as it might not always be set or applicable.
  final String? plotType;

  /// Optional: Dimensions of the space (e.g., "2m x 1m").
  final String? dimensions;

  /// Optional: Additional notes or description for the space.
  final String? notes;

  /// Optional: Timestamp of when this record was created in the database.
  final DateTime? createdAt;

  /// Optional: Timestamp of when this record was last updated in the database.
  final DateTime? updatedAt;

  const CemeterySpace({
    required this.id,
    required this.spaceIdentifier,
    required this.cemeteryId,
    required this.status,
    this.plotType,
    this.dimensions,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create a [CemeterySpace] instance from a JSON map (e.g., data from Supabase).
  factory CemeterySpace.fromJson(Map<String, dynamic> json) {
    // Basic validation for required fields from the database
    if (json['id'] == null) {
      throw FormatException(
        "Required field 'id' is missing in CemeterySpace JSON: $json",
      );
    }
    if (json['cemetery_id'] == null) {
      throw FormatException(
        "Required field 'cemetery_id' is missing in CemeterySpace JSON: $json",
      );
    }
    if (json['space_identifier'] == null) {
      // Depending on requirements, 'space_identifier' might also be critical.
      // For now, providing a fallback but logging a warning.
      print(
        "Warning: 'space_identifier' is missing in CemeterySpace JSON, using fallback: $json",
      );
    }

    return CemeterySpace(
      id: json['id'] as String,
      spaceIdentifier:
          json['space_identifier'] as String? ?? 'N/A', // User-visible ID
      cemeteryId: json['cemetery_id'] as String,
      status: SpaceStatus.fromJson(
        json['status'] as String?,
      ), // Use the helper for safer parsing
      plotType: json['plot_type'] as String?,
      dimensions: json['dimensions'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Method to convert a [CemeterySpace] instance to a JSON map.
  /// Useful for sending data to Supabase (e.g., for creating or updating spaces).
  /// Only include fields that are intended to be written/updated by the client.
  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Typically not sent when creating, and not updated.
      'space_identifier': spaceIdentifier,
      'cemetery_id': cemeteryId, // Required when creating a new space.
      'status': status.toJson(), // Use the helper to get the string value
      if (plotType != null) 'plot_type': plotType,
      if (dimensions != null) 'dimensions': dimensions,
      if (notes != null) 'notes': notes,
      // 'created_at' and 'updated_at' are usually handled by the database (e.g., DEFAULT NOW()).
    };
  }

  /// Creates a new [CemeterySpace] instance with updated values.
  /// Useful for immutable state updates.
  CemeterySpace copyWith({
    String? id,
    String? spaceIdentifier,
    String? cemeteryId,
    SpaceStatus? status,
    String?
        plotType, // Use ValueGetter<String?>? for nullable fields if you need to set them to null
    String? dimensions,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CemeterySpace(
      id: id ?? this.id,
      spaceIdentifier: spaceIdentifier ?? this.spaceIdentifier,
      cemeteryId: cemeteryId ?? this.cemeteryId,
      status: status ?? this.status,
      plotType: plotType ?? this.plotType,
      dimensions: dimensions ?? this.dimensions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Override '==' and 'hashCode' for proper object comparison,
  /// especially if instances are stored in [Set]s or used as keys in [Map]s.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CemeterySpace &&
        other.id == id &&
        other.spaceIdentifier == spaceIdentifier &&
        other.cemeteryId == cemeteryId &&
        other.status == status &&
        other.plotType == plotType &&
        other.dimensions == dimensions &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        spaceIdentifier,
        cemeteryId,
        status,
        plotType,
        dimensions,
        notes,
        createdAt,
        updatedAt,
      );

  /// Provides a string representation of the [CemeterySpace] instance, useful for debugging.
  @override
  String toString() {
    return 'CemeterySpace(id: $id, spaceIdentifier: $spaceIdentifier, cemeteryId: $cemeteryId, status: $status, plotType: $plotType, dimensions: $dimensions, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

// Ensure any sample data functions are removed from this model file.
// If needed for testing or UI prototyping before backend integration,
// place them in a dedicated `dev_data.dart` or similar, or generate them in widget state.
