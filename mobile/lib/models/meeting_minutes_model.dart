import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of meeting minutes
enum MinutesStatus {
  draft,            // Bản nháp
  pending_approval, // Chờ duyệt (Previously 'pending')
  approved,         // Đã duyệt
  rejected,         // Bị từ chối
}

class MeetingMinutesModel {
  final String id;
  final String meetingId;
  final String title;
  final String content;
  final int versionNumber;
  final MinutesStatus status;
  
  // Creator info
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  
  // Last updater info
  final String updatedBy;
  final String updatedByName;
  final DateTime updatedAt;
  
  // Approval info
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? approvalComment;
  
  // Rejection info
  final String? rejectedBy;
  final String? rejectedByName;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  
  // Submission info
  final String? submissionNote;
  final DateTime? submittedAt;
  
  // Archive info
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archivedBy;
  final String? archivedByName;

  MeetingMinutesModel({
    required this.id,
    required this.meetingId,
    required this.title,
    required this.content,
    required this.versionNumber,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedByName,
    required this.updatedAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.approvalComment,
    this.rejectedBy,
    this.rejectedByName,
    this.rejectionReason,
    this.rejectedAt,
    this.submissionNote,
    this.submittedAt,
    this.isArchived = false,
    this.archivedAt,
    this.archivedBy,
    this.archivedByName,
  });

  factory MeetingMinutesModel.fromMap(Map<String, dynamic> map, String id) {
    return MeetingMinutesModel(
      id: id,
      meetingId: map['meetingId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      versionNumber: map['versionNumber'] ?? 1,
      status: _parseStatus(map['status']),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? map['createdBy'] ?? '',
      updatedByName: map['updatedByName'] ?? map['createdByName'] ?? '',
      updatedAt: _parseTimestamp(map['updatedAt']) ?? DateTime.now(),
      approvedBy: map['approvedBy'],
      approvedByName: map['approvedByName'],
      approvedAt: _parseTimestamp(map['approvedAt']),
      approvalComment: map['approvalComment'],
      rejectedBy: map['rejectedBy'],
      rejectedByName: map['rejectedByName'],
      rejectionReason: map['rejectionReason'],
      rejectedAt: _parseTimestamp(map['rejectedAt']),
      submissionNote: map['submissionNote'],
      submittedAt: _parseTimestamp(map['submittedAt']),
      isArchived: map['isArchived'] ?? false,
      archivedAt: _parseTimestamp(map['archivedAt']),
      archivedBy: map['archivedBy'],
      archivedByName: map['archivedByName'],
    );
  }

  static MinutesStatus _parseStatus(dynamic value) {
    if (value == null) return MinutesStatus.draft;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'pending':
      case 'pending_approval':
        return MinutesStatus.pending_approval;
      case 'approved':
        return MinutesStatus.approved;
      case 'rejected':
        return MinutesStatus.rejected;
      default:
        return MinutesStatus.draft;
    }
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'meetingId': meetingId,
      'title': title,
      'content': content,
      'versionNumber': versionNumber,
      'status': status.name,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvalComment': approvalComment,
      'rejectedBy': rejectedBy,
      'rejectedByName': rejectedByName,
      'rejectionReason': rejectionReason,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'submissionNote': submissionNote,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'archivedBy': archivedBy,
      'archivedByName': archivedByName,
    };
  }

  MeetingMinutesModel copyWith({
    String? id,
    String? meetingId,
    String? title,
    String? content,
    int? versionNumber,
    MinutesStatus? status,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    String? updatedBy,
    String? updatedByName,
    DateTime? updatedAt,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? approvalComment,
    String? rejectedBy,
    String? rejectedByName,
    String? rejectionReason,
    DateTime? rejectedAt,
    String? submissionNote,
    DateTime? submittedAt,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedBy,
    String? archivedByName,
  }) {
    return MeetingMinutesModel(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      title: title ?? this.title,
      content: content ?? this.content,
      versionNumber: versionNumber ?? this.versionNumber,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      approvalComment: approvalComment ?? this.approvalComment,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedByName: rejectedByName ?? this.rejectedByName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      submissionNote: submissionNote ?? this.submissionNote,
      submittedAt: submittedAt ?? this.submittedAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      archivedByName: archivedByName ?? this.archivedByName,
    );
  }

  // Helper getters
  bool get isDraft => status == MinutesStatus.draft;
  bool get isPending => status == MinutesStatus.pending_approval;
  bool get isApproved => status == MinutesStatus.approved;
  bool get isRejected => status == MinutesStatus.rejected;
  
  /// Can be edited (only DRAFT status)
  bool get canEdit => isDraft;
  
  /// Can be deleted (only DRAFT status)
  bool get canDelete => isDraft;
  
  /// Can submit for approval (only DRAFT status)
  bool get canSubmit => isDraft;
  
  /// Can be approved (only PENDING status)
  bool get canApprove => isPending;

  /// Get status display text in Vietnamese
  String get statusText {
    switch (status) {
      case MinutesStatus.draft:
        return 'Bản nháp';
      case MinutesStatus.pending_approval:
        return 'Chờ duyệt';
      case MinutesStatus.approved:
        return 'Đã duyệt';
      case MinutesStatus.rejected:
        return 'Từ chối';
    }
  }
}
