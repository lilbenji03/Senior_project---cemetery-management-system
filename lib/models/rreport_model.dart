// lib/models/report_model.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show immutable;
import '../constants/app_colors.dart'; // Assuming you have this for colors

// Enum for Report Status
enum ReportStatus {
  submitted, // A new report just created by a user.
  underReview, // An admin is actively looking at the report.
  resolved, // The issue has been fixed and confirmed.
  closed, // The issue is closed (e.g., invalid, won't fix).
  escalated, // The issue requires higher-level attention.
  unknown,
  newReport,
  closedWontFix; // Fallback for unexpected status strings.

  String get displayName {
    switch (this) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.closed:
        return 'Closed';
      case ReportStatus.escalated:
        return 'Escalated';
      case ReportStatus.unknown:
      default:
        return 'Unknown';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.submitted:
        return AppColors.statusPending;
      case ReportStatus.underReview:
        return Colors.blue.shade700;
      case ReportStatus.resolved:
        return AppColors.statusApproved;
      case ReportStatus.closed:
        return AppColors.secondaryText;
      case ReportStatus.escalated:
        return AppColors.errorColor;
      case ReportStatus.unknown:
      default:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.submitted:
        return Icons.outbox_rounded;
      case ReportStatus.underReview:
        return Icons.hourglass_top_rounded;
      case ReportStatus.resolved:
        return Icons.check_circle_outline_rounded;
      case ReportStatus.closed:
        return Icons.lock_outline_rounded;
      case ReportStatus.escalated:
        return Icons.gavel_rounded;
      case ReportStatus.unknown:
      default:
        return Icons.help_outline_rounded;
    }
  }

  String toJson() => name;
  static ReportStatus fromJson(String? value) {
    if (value == null || value.isEmpty) return ReportStatus.unknown;
    try {
      String normalizedValue = value.toLowerCase().trim();
      return ReportStatus.values
          .firstWhere((e) => e.name.toLowerCase() == normalizedValue);
    } catch (_) {
      print("Warning: Unknown ReportStatus string received from DB: '$value'");
      return ReportStatus.unknown;
    }
  }
}

// Enum for Report Type
enum ReportType {
  bug,
  contentIssue,
  userMisconduct,
  spaceIncorrect,
  paymentIssue,
  suggestion,
  other,
  unknown;

  String get displayName {
    switch (this) {
      case ReportType.bug:
        return 'Technical Bug';
      case ReportType.contentIssue:
        return 'Content Issue';
      case ReportType.userMisconduct:
        return 'User Misconduct';
      case ReportType.spaceIncorrect:
        return 'Space Information Incorrect';
      case ReportType.paymentIssue:
        return 'Payment Issue';
      case ReportType.suggestion:
        return 'Suggestion / Feedback';
      case ReportType.other:
        return 'Other';
      case ReportType.unknown:
      default:
        return 'Unknown Type';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.bug:
        return Icons.bug_report_outlined;
      case ReportType.contentIssue:
        return Icons.description_outlined;
      case ReportType.userMisconduct:
        return Icons.group_off_outlined;
      case ReportType.spaceIncorrect:
        return Icons.wrong_location_outlined;
      case ReportType.paymentIssue:
        return Icons.payment_outlined;
      case ReportType.suggestion:
        return Icons.lightbulb_outline;
      case ReportType.other:
        return Icons.help_outline;
      case ReportType.unknown:
      default:
        return Icons.report_problem_outlined;
    }
  }

  String toJson() => name;
  static ReportType fromJson(String? value) {
    if (value == null || value.isEmpty) return ReportType.unknown;
    try {
      return ReportType.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase().trim());
    } catch (_) {
      print("Warning: Unknown ReportType string received from DB: '$value'");
      return ReportType.unknown;
    }
  }
}

@immutable
class Report {
  final String id;
  final String?
      userId; // <<< CORRECTED from 'UserId' to follow Dart conventions
  final ReportType type;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;

  final String? cemeteryId;
  final String? cemeterySpaceId;
  final String? reportedByUserFullName;
  final String? reportedByUserEmail;
  final String? cemeteryName;
  final String? spaceIdentifier;
  final DateTime? resolvedAt;
  final String? adminNotes;

  const Report({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.userId, // <<< CORRECTED from 'UserId'
    this.cemeteryId,
    this.cemeterySpaceId,
    this.reportedByUserFullName,
    this.reportedByUserEmail,
    this.cemeteryName,
    this.spaceIdentifier,
    this.resolvedAt,
    this.adminNotes,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(String? dateString) {
      return dateString != null ? DateTime.tryParse(dateString) : null;
    }

    if (json['id'] == null || json['created_at'] == null) {
      throw FormatException(
          "Core field (id, created_at) is missing in Report JSON: $json");
    }

    final profileData = json['profiles'] as Map<String, dynamic>?;
    final cemeteryData = json['cemeteries'] as Map<String, dynamic>?;
    final spaceData = json['cemetery_spaces'] as Map<String, dynamic>?;

    return Report(
      id: json['id'] as String,
      // <<< CORRECTED: Match the key 'user_id' from your database schema
      userId: json['user_id'] as String?,
      cemeteryId: json['cemetery_id'] as String?,
      cemeterySpaceId: json['cemetery_space_id'] as String?,
      type: ReportType.fromJson(json['report_type'] as String?),
      description: json['description'] as String? ?? 'No description provided.',
      status: ReportStatus.fromJson(json['status'] as String?),
      createdAt: _parseDate(json['created_at'] as String)!,
      resolvedAt: _parseDate(json['resolved_at'] as String?),
      adminNotes: json['admin_notes'] as String?,

      reportedByUserFullName: profileData?['full_name'] as String?,
      reportedByUserEmail: profileData?['email'] as String?,
      cemeteryName:
          cemeteryData?['name'] as String? ?? json['cemetery_name'] as String?,
      spaceIdentifier: spaceData?['space_identifier'] as String? ??
          json['space_identifier'] as String?,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      // <<< CORRECTED: Match the key 'user_id' for your database schema
      'user_id': userId,
      if (cemeteryId != null) 'cemetery_id': cemeteryId,
      if (cemeterySpaceId != null) 'cemetery_space_id': cemeterySpaceId,
      'report_type': type.toJson(),
      'description': description,
      'status': ReportStatus.submitted.toJson(),
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'status': status.toJson(),
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    };
  }

  Report copyWith({
    String? id,
    ReportType? type,
    String? description,
    ReportStatus? status,
    DateTime? createdAt,
    String? userId, // <<< CORRECTED from 'reportedByUserId'
    String? cemeteryId,
    String? cemeterySpaceId,
    String? reportedByUserFullName,
    String? reportedByUserEmail,
    String? cemeteryName,
    String? spaceIdentifier,
    DateTime? resolvedAt,
    String? adminNotes,
  }) {
    return Report(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId, // <<< CORRECTED
      cemeteryId: cemeteryId ?? this.cemeteryId,
      cemeterySpaceId: cemeterySpaceId ?? this.cemeterySpaceId,
      reportedByUserFullName:
          reportedByUserFullName ?? this.reportedByUserFullName,
      reportedByUserEmail: reportedByUserEmail ?? this.reportedByUserEmail,
      cemeteryName: cemeteryName ?? this.cemeteryName,
      spaceIdentifier: spaceIdentifier ?? this.spaceIdentifier,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Report && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Report(id: $id, type: $type, status: $status)';
  }
}
