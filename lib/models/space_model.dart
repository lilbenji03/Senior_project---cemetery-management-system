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
        return 'Used';
      case SpaceStatus.pendingApproval:
        return 'Pending Approval';
      case SpaceStatus.maintenance:
        return 'Under Maintenance';
      case SpaceStatus.unknown:
      default:
        return 'Unknown Status';
    }
  }

  /// Converts the enum to its 'snake_case' string representation for storing in Supabase.
  /// This is the standard and most reliable format for PostgreSQL.
  String toJson() {
    switch (this) {
      case SpaceStatus.pendingApproval:
        return 'pending_approval';
      default:
        // For simple enums, .name works fine (e.g., 'available', 'booked')
        return name;
    }
  }

  /// Creates a [SpaceStatus] from a string (e.g., from Supabase).
  /// This version is robust and handles both 'snake_case' and 'camelCase'.
  static SpaceStatus fromJson(String? statusString) {
    if (statusString == null || statusString.isEmpty) {
      return SpaceStatus.unknown;
    }
    // This switch statement explicitly handles all expected variations.
    switch (statusString) {
      case 'available':
        return SpaceStatus.available;
      case 'booked':
        return SpaceStatus.booked;
      case 'used':
        return SpaceStatus.used;
      case 'maintenance':
        return SpaceStatus.maintenance;
      // This is the key: it correctly handles both formats from the database.
      case 'pendingApproval':
      case 'pending_approval':
        return SpaceStatus.pendingApproval;
      default:
        print(
            "Warning: Unknown SpaceStatus string received from DB: '$statusString'");
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
  final String id;

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
    return CemeterySpace(
      id: json['id'] as String,
      spaceIdentifier: json['space_identifier'] as String? ?? 'N/A',
      cemeteryId: json['cemetery_id'] as String,
      status: SpaceStatus.fromJson(
          json['status'] as String?), // Use the robust helper
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
  Map<String, dynamic> toJson() {
    return {
      'space_identifier': spaceIdentifier,
      'cemetery_id': cemeteryId,
      'status': status.toJson(), // Use the robust helper
      if (plotType != null) 'plot_type': plotType,
      if (dimensions != null) 'dimensions': dimensions,
      if (notes != null) 'notes': notes,
    };
  }

  /// Creates a new [CemeterySpace] instance with updated values.
  CemeterySpace copyWith({
    String? id,
    String? spaceIdentifier,
    String? cemeteryId,
    SpaceStatus? status,
    String? plotType,
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

  @override
  String toString() {
    return 'CemeterySpace(id: $id, identifier: $spaceIdentifier, status: $status)';
  }
}
