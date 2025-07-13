import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingMinutesModel {
  final String id;
  final String meetingId;
  final String content;
  final String createdBy;
  final String createdByName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final String? rejectedByName;
  final String? rejectionReason;
  final DateTime? rejectedAt;

  MeetingMinutesModel({
    required this.id,
    required this.meetingId,
    required this.content,
    required this.createdBy,
    required this.createdByName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedByName,
    this.rejectionReason,
    this.rejectedAt,
  });

  factory MeetingMinutesModel.fromMap(Map<String, dynamic> map, String id) {
    return MeetingMinutesModel(
      id: id,
      meetingId: map['meetingId'] ?? '',
      content: map['content'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      status: map['status'] ?? 'draft',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedBy: map['approvedBy'],
      approvedByName: map['approvedByName'],
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedBy: map['rejectedBy'],
      rejectedByName: map['rejectedByName'],
      rejectionReason: map['rejectionReason'],
      rejectedAt: map['rejectedAt'] != null
          ? (map['rejectedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
