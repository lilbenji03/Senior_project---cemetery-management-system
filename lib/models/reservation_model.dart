import 'package:flutter/foundation.dart' show immutable;

// Enum for payment methods.
// Values should match strings you intend to store in the database.
enum PaymentMethod {
  mpesa,
  card,
  bankTransfer, // Changed 'bank' to be more specific
  cash, // Added for potential on-site payments
  unknown; // Fallback for any other value

  String get displayName {
    switch (this) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.unknown:
      default:
        return 'Unknown Method';
    }
  }

  /// Converts the enum to its string representation for storing in Supabase.
  String toJson() => name; // e.g., "mpesa", "card"

  /// Creates a [PaymentMethod] from a string. Case-insensitive.
  static PaymentMethod fromJson(String? value) {
    if (value == null || value.isEmpty) return PaymentMethod.unknown;
    try {
      // Find the enum value by name, ignoring case.
      return PaymentMethod.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase().trim());
    } catch (_) {
      // If no match is found, return unknown.
      return PaymentMethod.unknown;
    }
  }
}

// Enum for reservation statuses.
// These should align with the 'status' column in your 'reservations' table.
enum ReservationStatus {
  pendingPayment, // Initial state after user expresses interest, before payment
  pendingApproval, // After payment/action, awaiting admin approval
  approved, // Confirmed by admin
  rejected, // Denied by admin
  expired, // Hold time passed without confirmation
  completed, // Burial has occurred
  cancelledByUser, // Cancelled by the user
  cancelledByAdmin, // Cancelled by admin
  unknown,
  paymentPending,
  cancelled,
  pending_Approval,
  cancelled_By_Admin,
  pending; // Fallback for unexpected values from DB

  String get displayName {
    switch (this) {
      case ReservationStatus.pendingPayment:
        return 'Pending Payment';
      case ReservationStatus.pendingApproval:
        return 'Pending Approval';
      case ReservationStatus.approved:
        return 'Approved';
      case ReservationStatus.rejected:
        return 'Rejected';
      case ReservationStatus.expired:
        return 'Expired';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.cancelledByUser:
        return 'Cancelled by User';
      case ReservationStatus.cancelledByAdmin:
        return 'Cancelled by Admin';
      case ReservationStatus.unknown:
      default:
        return 'Unknown';
    }
  }

  /// Converts the enum to its string representation for storing in Supabase.
  String toJson() => name; // e.g., "pendingApproval"

  /// Creates a [ReservationStatus] from a string. Case-insensitive and robust.
  static ReservationStatus fromJson(String? value) {
    if (value == null || value.isEmpty) return ReservationStatus.unknown;
    try {
      // Normalize the input string for better matching against enum names
      String normalizedValue =
          value.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
      return ReservationStatus.values
          .firstWhere((e) => e.name.toLowerCase() == normalizedValue);
    } catch (_) {
      print(
          "Warning: Unknown ReservationStatus string received from DB: '$value'");
      return ReservationStatus.unknown;
    }
  }
}

@immutable
class Reservation {
  final String id;
  final String userId;
  final String cemeteryId;
  final String cemeterySpaceId;
  final String spaceIdentifier; // Denormalized, user-facing ID like "LA01"
  final String cemeteryName; // Denormalized for easier display
  final String plotType; // Denormalized
  final ReservationStatus status;
  final DateTime requestedAt;
  final DateTime createdAt;
  final double estimatedCost;

  // Nullable fields
  final DateTime? approvedAt;
  final DateTime? expiresAt;
  final String? burialPermitNumber;
  final DateTime? selectedBurialDate;
  final String? deceasedName;
  final double? amountPaid;
  final PaymentMethod? paymentMethodUsed;
  final String? paymentReference;
  final DateTime? paymentDate;
  final DateTime? updatedAt;

  // Fields from JOINed 'profiles' table (for admin views)
  final String? userFullName;
  final String? userEmail;
  final String? userPhoneNumber;

  const Reservation({
    required this.id,
    required this.userId,
    required this.cemeteryId,
    required this.cemeterySpaceId,
    required this.spaceIdentifier,
    required this.cemeteryName,
    required this.plotType,
    required this.status,
    required this.requestedAt,
    required this.createdAt,
    required this.estimatedCost,
    this.approvedAt,
    this.expiresAt,
    this.burialPermitNumber,
    this.selectedBurialDate,
    this.deceasedName,
    this.amountPaid,
    this.paymentMethodUsed,
    this.paymentReference,
    this.paymentDate,
    this.updatedAt,
    this.userFullName,
    this.userEmail,
    this.userPhoneNumber,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Helper function for safe date parsing
    DateTime? _parseDate(String? dateString) {
      return dateString != null ? DateTime.tryParse(dateString) : null;
    }

    // Extract joined data safely
    final profileData = json['profiles'] as Map<String, dynamic>?;
    final cemeteryData = json['cemeteries'] as Map<String, dynamic>?;
    final spaceData = json['cemetery_spaces'] as Map<String, dynamic>?;

    // Validate critical non-nullable fields from the DB
    if (json['id'] == null ||
        json['user_id'] == null ||
        json['created_at'] == null ||
        json['requested_at'] == null) {
      throw FormatException(
          "Core field (id, user_id, created_at, requested_at) is missing in Reservation JSON: $json");
    }

    return Reservation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cemeteryId: json['cemetery_id'] as String? ?? 'N/A',
      cemeterySpaceId: json['cemetery_space_id'] as String? ?? 'N/A',
      spaceIdentifier: spaceData?['space_identifier'] as String? ??
          json['space_identifier'] as String? ??
          'N/A',
      cemeteryName: cemeteryData?['name'] as String? ??
          json['cemetery_name'] as String? ??
          'Unknown',
      plotType: spaceData?['plot_type'] as String? ??
          json['plot_type'] as String? ??
          'Unknown',
      status: ReservationStatus.fromJson(json['status'] as String?),
      requestedAt: _parseDate(json['requested_at'] as String)!,
      createdAt: _parseDate(json['created_at'] as String)!,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      approvedAt: _parseDate(json['approved_at'] as String?),
      expiresAt: _parseDate(json['expires_at'] as String?),
      burialPermitNumber: json['burial_permit_number'] as String?,
      selectedBurialDate: _parseDate(json['selected_burial_date'] as String?),
      deceasedName: json['deceased_name'] as String?,
      amountPaid: (json['amount_paid'] as num?)?.toDouble(),
      paymentMethodUsed:
          PaymentMethod.fromJson(json['payment_method'] as String?),
      paymentReference: json['payment_reference'] as String?,
      paymentDate: _parseDate(json['payment_date'] as String?),
      updatedAt: _parseDate(json['updated_at'] as String?),
      userFullName: profileData?['full_name'] as String?,
      userEmail: profileData?['email'] as String?,
      userPhoneNumber: profileData?['phone_number'] as String?,
    );
  }

  /// Generates a JSON map for creating a new reservation.
  Map<String, dynamic> toJsonForCreate() {
    return {
      'user_id': userId,
      'cemetery_id': cemeteryId,
      'cemetery_space_id': cemeterySpaceId,
      'space_identifier': spaceIdentifier, // Denormalized at creation time
      'cemetery_name': cemeteryName, // Denormalized at creation time
      'plot_type': plotType, // Denormalized at creation time
      'status': status.toJson(), // Initial status
      'requested_at': requestedAt.toIso8601String(),
      'estimated_cost': estimatedCost,
      if (burialPermitNumber != null && burialPermitNumber!.isNotEmpty)
        'burial_permit_number': burialPermitNumber,
      // 'id', 'created_at', 'updated_at' are handled by the database.
    };
  }

  /// Generates a JSON map for admin/staff to update a reservation.
  Map<String, dynamic> toJsonForAdminUpdate({
    ReservationStatus? newStatus,
    DateTime? newApprovedAt,
    DateTime? newExpiresAt,
  }) {
    final Map<String, dynamic> data = {};
    if (newStatus != null) data['status'] = newStatus.toJson();
    if (newApprovedAt != null)
      data['approved_at'] = newApprovedAt.toIso8601String();
    if (newExpiresAt != null)
      data['expires_at'] = newExpiresAt.toIso8601String();
    // 'updated_at' should be handled by a DB trigger. If not, add it here.
    return data;
  }

  /// Generates a JSON map for user to update limited fields (e.g., cancel).
  Map<String, dynamic> toJsonForUserUpdate({
    ReservationStatus? newStatus, // e.g., for cancellation
  }) {
    final Map<String, dynamic> data = {};
    if (newStatus != null && newStatus == ReservationStatus.cancelledByUser) {
      data['status'] = newStatus.toJson();
    }
    // 'updated_at' should be handled by a DB trigger.
    return data;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reservation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Reservation(id: $id, spaceIdentifier: $spaceIdentifier, status: $status)';
  }
}
