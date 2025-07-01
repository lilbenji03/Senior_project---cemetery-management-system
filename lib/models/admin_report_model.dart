// lib/models/admin_report_model.dart

// This enum represents the different types of reports a user can submit.
enum ReportType {
  bug,
  contentIssue,
  userMisconduct,
  spaceIncorrect,
  paymentIssue,
  suggestion,
  other,
  unknown;

  // Converts the enum to a string that the database can understand.
  // Using snake_case is the standard for PostgreSQL.
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
        return name; // 'bug', 'suggestion', 'other'
    }
  }

  // Converts a string from the database into the correct enum case.
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
        print("Warning: Unknown ReportType string received from DB: '$json'");
        return ReportType.unknown;
    }
  }

  // Provides a clean, human-readable name for displaying in the UI.
  String get displayName {
    switch (this) {
      case ReportType.bug:
        return 'Bug Report';
      case ReportType.contentIssue:
        return 'Content Issue';
      case ReportType.userMisconduct:
        return 'User Misconduct';
      case ReportType.spaceIncorrect:
        return 'Incorrect Space Info';
      case ReportType.paymentIssue:
        return 'Payment Issue';
      case ReportType.suggestion:
        return 'Suggestion';
      case ReportType.other:
        return 'Other';
      case ReportType.unknown:
        return 'Unknown Type';
    }
  }
}

// This enum represents the states a report can be in.
// It MUST match the 'report_status_enum' type in your database.
enum ReportStatus {
  newReport,
  underReview,
  resolved,
  closedWontFix,
  escalated,
  unknown;

  // Converts the enum to a string that the database can understand.
  String toJson() {
    switch (this) {
      case ReportStatus.newReport:
        return 'new_report'; // snake_case for the database
      case ReportStatus.underReview:
        return 'under_review'; // snake_case for the database
      case ReportStatus.closedWontFix:
        return 'closed_wont_fix'; // snake_case for the database
      default:
        return name; // 'resolved', 'escalated'
    }
  }

  // Converts a string from the database into the correct enum case.
  static ReportStatus fromJson(String? json) {
    if (json == null) return ReportStatus.unknown;
    switch (json) {
      case 'new_report':
        return ReportStatus.newReport;
      case 'under_review':
        return ReportStatus.underReview;
      case 'resolved':
        return ReportStatus.resolved;
      case 'closed_wont_fix':
        return ReportStatus.closedWontFix;
      case 'escalated':
        return ReportStatus.escalated;
      default:
        print("Warning: Unknown ReportStatus string received from DB: '$json'");
        return ReportStatus.unknown;
    }
  }

  // Provides a clean, human-readable name for displaying in the UI.
  String get displayName {
    switch (this) {
      case ReportStatus.newReport:
        return 'New';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.closedWontFix:
        return 'Closed (Won\'t Fix)';
      case ReportStatus.escalated:
        return 'Escalated';
      case ReportStatus.unknown:
      default:
        return 'Unknown';
    }
  }
}

// The main AdminReportModel class.
class AdminReportModel {
  final String id;
  final DateTime createdAt;
  final ReportType type;
  final String description;
  final ReportStatus status;
  final String? reportedByUserId;
  final String? cemeteryId;
  final String? cemeterySpaceId;
  final String? adminNotes;
  final DateTime? resolvedAt;
  final DateTime? updatedAt;

  // Optional: These fields will be null until you fix the foreign keys.
  final String? reportedByUserFullName;
  final String? reportedByUserEmail;
  final String? cemeteryName;
  final String? spaceIdentifier;

  AdminReportModel({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.description,
    required this.status,
    this.reportedByUserId,
    this.cemeteryId,
    this.cemeterySpaceId,
    this.adminNotes,
    this.resolvedAt,
    this.updatedAt,
    this.reportedByUserFullName,
    this.reportedByUserEmail,
    this.cemeteryName,
    this.spaceIdentifier,
  });

  // Factory constructor to parse the JSON data from Supabase.
  factory AdminReportModel.fromJson(Map<String, dynamic> data) {
    // Safely access nested data from joins (they will be null if join fails)
    final profileData = data['profiles'] as Map<String, dynamic>?;
    final cemeteryData = data['cemeteries'] as Map<String, dynamic>?;
    final spaceData = data['cemetery_spaces'] as Map<String, dynamic>?;

    return AdminReportModel(
      id: data['id'],
      createdAt: DateTime.parse(data['created_at']),
      type: ReportType.fromJson(data['report_type']),
      description: data['description'] ?? '',
      status: ReportStatus.fromJson(data['status']),
      reportedByUserId: data['reported_by_user_id'],
      cemeteryId: data['cemetery_id'],
      cemeterySpaceId: data['cemetery_space_id'],
      adminNotes: data['admin_notes'],
      resolvedAt: DateTime.tryParse(data['resolved_at'] ?? ''),
      updatedAt: DateTime.tryParse(data['updated_at'] ?? ''),

      // These will be null if the joins are not present in your select query
      reportedByUserFullName: profileData?['full_name'],
      reportedByUserEmail: profileData?['email'],
      cemeteryName: cemeteryData?['name'],
      spaceIdentifier: spaceData?['space_identifier'],
    );
  }
}
