import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingTaskStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
}

enum TaskStatusEnum {
  pending,    // Chưa bắt đầu
  inProgress, // Đang thực hiện
  completed,  // Hoàn thành
}

class MeetingTask {
  final String id;
  final String meetingId;
  final String title;
  final String? description;
  
  // Assignee info
  final String assigneeId;
  final String assigneeName;
  final String? assigneeAvatar;
  final String assigneeRole;
  
  // Task details
  final DateTime deadline;
  final String status;
  final String priority;
  final int progress;
  
  // New Fields
  final List<TaskSubtask> subtasks;
  final List<TaskComment> comments;
  final List<TaskHistory> history;
  
  // Metadata
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  MeetingTask({
    required this.id,
    required this.meetingId,
    required this.title,
    this.description,
    required this.assigneeId,
    required this.assigneeName,
    this.assigneeAvatar,
    required this.assigneeRole,
    required this.deadline,
    this.status = MeetingTaskStatus.pending,
    this.priority = 'medium',
    this.progress = 0,
    this.subtasks = const [],
    this.comments = const [],
    this.history = const [],
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory MeetingTask.fromMap(Map<String, dynamic> map, String id) {
    return MeetingTask(
      id: id,
      meetingId: map['meetingId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      assigneeId: map['assigneeId'] ?? '',
      assigneeName: map['assigneeName'] ?? '',
      assigneeAvatar: map['assigneeAvatar'],
      assigneeRole: map['assigneeRole'] ?? '',
      deadline: (map['deadline'] as Timestamp).toDate(),
      status: map['status'] ?? MeetingTaskStatus.pending,
      priority: map['priority'] ?? 'medium',
      progress: map['progress'] ?? 0,
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((e) => TaskSubtask.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      comments: (map['comments'] as List<dynamic>?)
              ?.map((e) => TaskComment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
       history: (map['history'] as List<dynamic>?)
              ?.map((e) => TaskHistory.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'meetingId': meetingId,
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assigneeAvatar': assigneeAvatar,
      'assigneeRole': assigneeRole,
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'priority': priority,
      'progress': progress,
      'subtasks': subtasks.map((e) => e.toMap()).toList(),
      'comments': comments.map((e) => e.toMap()).toList(),
      'history': history.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  // Helper methods
  bool get isOverdue => DateTime.now().isAfter(deadline) && status != 'completed';
  
  String getStatusText() {
    switch (status) {
      case MeetingTaskStatus.pending:
        return 'Chưa bắt đầu';
      case MeetingTaskStatus.inProgress:
        return 'Đang thực hiện';
      case MeetingTaskStatus.completed:
        return 'Hoàn thành';
      default:
        return 'Không xác định';
      }
  }

  MeetingTask copyWith({
    String? id,
    String? meetingId,
    String? title,
    String? description,
    String? assigneeId,
    String? assigneeName,
    String? assigneeAvatar,
    String? assigneeRole,
    DateTime? deadline,
    String? status,
    String? priority,
    int? progress,
    List<TaskSubtask>? subtasks,
    List<TaskComment>? comments,
    List<TaskHistory>? history,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return MeetingTask(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatar: assigneeAvatar ?? this.assigneeAvatar,
      assigneeRole: assigneeRole ?? this.assigneeRole,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      subtasks: subtasks ?? this.subtasks,
      comments: comments ?? this.comments,
      history: history ?? this.history,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class TaskSubtask {
  final String id;
  final String title;
  final bool isCompleted;

  TaskSubtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  factory TaskSubtask.fromMap(Map<String, dynamic> map) {
    return TaskSubtask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }
  
  TaskSubtask copyWith({
     String? id,
     String? title,
     bool? isCompleted,
  }) {
    return TaskSubtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class TaskComment {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  TaskComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory TaskComment.fromMap(Map<String, dynamic> map) {
    return TaskComment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}


class TaskHistory {
  final String id;
  final String action; // e.g., 'Updated status', 'Commented'
  final String description;
  final String createdBy;
  final DateTime createdAt;

  TaskHistory({
    required this.id,
     required this.action,
    required this.description,
    required this.createdBy,
    required this.createdAt,
  });

   factory TaskHistory.fromMap(Map<String, dynamic> map) {
    return TaskHistory(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
