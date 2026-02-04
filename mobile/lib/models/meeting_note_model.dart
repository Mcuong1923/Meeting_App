import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingNote {
  final String id;
  final String meetingId;
  final String content;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  MeetingNote({
    required this.id,
    required this.meetingId,
    required this.content,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeetingNote.fromMap(Map<String, dynamic> map, String id) {
    return MeetingNote(
      id: id,
      meetingId: map['meetingId'] ?? '',
      content: map['content'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'meetingId': meetingId,
      'content': content,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MeetingNote copyWith({
    String? id,
    String? meetingId,
    String? content,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingNote(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
