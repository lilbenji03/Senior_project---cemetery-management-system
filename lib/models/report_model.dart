// lib/models/report_model.dart
// ★★★ FINAL VERSION, MATCHING YOUR ACTUAL SCHEMA ★★★

import 'package:flutter/material.dart';

// --- ReportType Enum ---
enum ReportType {
  bug,
  contentIssue,
  userMisconduct,
  spaceIncorrect,
  paymentIssue,
  suggestion,
  other,
  unknown;

  String toJson() {
    switch (this) {
      case ReportType.contentIssue:
        return 'content_issue';
      case ReportType.userMisconduct:
        return 'user_misconduct';
      case ReportType.spaceIncorrect:
        return 'space_incorrect';
      case ReportType.paymentIssue:
        return 'payment_issue';
      default:
        return name;
    }
  }

  static ReportType fromJson(String? json) {
    if (json == null) return ReportType.unknown;
    switch (json) {
      case 'bug':
        return ReportType.bug;
      case 'content_issue':
        return ReportType.contentIssue;
      case 'user_misconduct':
        return ReportType.userMisconduct;
      case 'space_incorrect':
        return ReportType.spaceIncorrect;
      case 'payment_issue':
        return ReportType.paymentIssue;
      case 'suggestion':
        return ReportType.suggestion;
      case 'other':
        return ReportType.other;
      default:
        return ReportType.unknown;
    }
  }

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
      default:
        return 'Unknown Type';
    }
  }
}

// --- ReportStatus Enum ---
enum ReportStatus {
  submitted,
  assigned,
  resolved,
  rejected,
  closed,
  unknown;

  String toJson() => name;
  static ReportStatus fromJson(String? json) {
    if (json == null) return ReportStatus.unknown;
    switch (json) {
      case 'submitted':
        return ReportStatus.submitted;
      case 'assigned':
        return ReportStatus.assigned;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      case 'closed':
        return ReportStatus.closed;
      default:
        return ReportStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.assigned:
        return 'Assigned';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
      case ReportStatus.closed:
        return 'Closed';
      default:
        return 'Unknown';
    }
  }
}

// --- ReportModel Class ---
class ReportModel {
  final String id;
  final DateTime createdAt;
  final ReportType type;
  final String description;
  final ReportStatus status;
  final String? userId;
  final String? cemeteryId;
  final String? adminNotes;
  final DateTime? resolvedAt;
  final DateTime? updatedAt;

  // These fields come from the database view
  final String? reportedByUserFullName;
  // final String? reportedByUserEmail; // REMOVED
  final String? cemeteryName;

  ReportModel({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.description,
    required this.status,
    this.userId,
    this.cemeteryId,
    this.adminNotes,
    this.resolvedAt,
    this.updatedAt,
    this.reportedByUserFullName,
    // this.reportedByUserEmail, // REMOVED
    this.cemeteryName,
  });

  factory ReportModel.fromJson(Map<String, dynamic> data) {
    return ReportModel(
      id: data['id'] as String? ?? 'no-id',
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      type: ReportType.fromJson(data['report_type'] as String?),
      description: data['description'] as String? ?? 'No description found.',
      status: ReportStatus.fromJson(data['status'] as String?),
      userId: data['user_id'] as String?,
      cemeteryId: data['cemetery_id'] as String?,
      adminNotes: data['admin_notes'] as String?,
      resolvedAt: DateTime.tryParse(data['resolved_at'] ?? ''),
      updatedAt: DateTime.tryParse(data['updated_at'] ?? ''),
      reportedByUserFullName: data['full_name'] as String?,
      // reportedByUserEmail: data['email'] as String?, // REMOVED
      cemeteryName: data['cemetery_name'] as String?,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'user_id': userId,
      'cemetery_id': cemeteryId,
      'report_type': type.toJson(),
      'description': description,
      'status': ReportStatus.submitted.toJson(),
    };
  }
}
