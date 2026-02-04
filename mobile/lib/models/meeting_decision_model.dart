import 'package:cloud_firestore/cloud_firestore.dart';

enum DecisionReaction {
  agree,    // 👍 Tán thành
  disagree, // 👎 Không tán thành
  neutral,  // 😐 Không ý kiến
}

class MeetingDecision {
  final String id;
  final String meetingId;
  final String content;
  final String createdBy;
  final String createdByName;
  
  // Reactions: userId -> reaction type
  final Map<String, DecisionReaction> reactions;
  
  // Final decision status
  final bool isFinal;
  final String? finalizedBy;
  final String? finalizedByName;
  final DateTime? finalizedAt;
  
  // Linked Task ID
  final String? taskId;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  MeetingDecision({
    required this.id,
    required this.meetingId,
    required this.content,
    required this.createdBy,
    required this.createdByName,
    this.reactions = const {},
    this.isFinal = false,
    this.finalizedBy,
    this.finalizedByName,
    this.finalizedAt,
    this.taskId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeetingDecision.fromMap(Map<String, dynamic> map, String id) {
    // Parse reactions map
    Map<String, DecisionReaction> reactionsMap = {};
    if (map['reactions'] != null) {
      (map['reactions'] as Map<String, dynamic>).forEach((userId, reactionStr) {
        reactionsMap[userId] = DecisionReaction.values.firstWhere(
          (r) => r.toString() == 'DecisionReaction.$reactionStr',
          orElse: () => DecisionReaction.neutral,
        );
      });
    }

    return MeetingDecision(
      id: id,
      meetingId: map['meetingId'] ?? '',
      content: map['content'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      reactions: reactionsMap,
      isFinal: map['isFinal'] ?? false,
      finalizedBy: map['finalizedBy'],
      finalizedByName: map['finalizedByName'],
      finalizedAt: map['finalizedAt'] != null
          ? (map['finalizedAt'] as Timestamp).toDate()
          : null,
      taskId: map['taskId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    // Convert reactions to map of strings
    Map<String, String> reactionsMap = {};
    reactions.forEach((userId, reaction) {
      reactionsMap[userId] = reaction.toString().split('.').last;
    });

    return {
      'meetingId': meetingId,
      'content': content,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'reactions': reactionsMap,
      'isFinal': isFinal,
      'finalizedBy': finalizedBy,
      'finalizedByName': finalizedByName,
      'finalizedAt': finalizedAt != null ? Timestamp.fromDate(finalizedAt!) : null,
      'taskId': taskId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  int getReactionCount(DecisionReaction type) {
    return reactions.values.where((r) => r == type).length;
  }

  DecisionReaction? getUserReaction(String userId) {
    return reactions[userId];
  }

  MeetingDecision copyWith({
    String? id,
    String? meetingId,
    String? content,
    String? createdBy,
    String? createdByName,
    Map<String, DecisionReaction>? reactions,
    bool? isFinal,
    String? finalizedBy,
    String? finalizedByName,
    DateTime? finalizedAt,
    String? taskId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingDecision(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      reactions: reactions ?? this.reactions,
      isFinal: isFinal ?? this.isFinal,
      finalizedBy: finalizedBy ?? this.finalizedBy,
      finalizedByName: finalizedByName ?? this.finalizedByName,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      taskId: taskId ?? this.taskId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
