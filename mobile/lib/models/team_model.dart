import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String description;
  final String departmentId;
  final String departmentName;
  final String? leaderId;
  final String? leaderName;
  final List<String> memberIds;
  final List<String> memberNames;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalData;

  TeamModel({
    required this.id,
    required this.name,
    required this.description,
    required this.departmentId,
    required this.departmentName,
    this.leaderId,
    this.leaderName,
    this.memberIds = const [],
    this.memberNames = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.additionalData,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map, String id) {
    return TeamModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      departmentId: map['departmentId'] ?? '',
      departmentName: map['departmentName'] ?? '',
      leaderId: map['leaderId'],
      leaderName: map['leaderName'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
      memberNames: List<String>.from(map['memberNames'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalData': additionalData,
    };
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? description,
    String? departmentId,
    String? departmentName,
    String? leaderId,
    String? leaderName,
    List<String>? memberIds,
    List<String>? memberNames,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'TeamModel(id: $id, name: $name, departmentId: $departmentId, memberCount: ${memberIds.length})';
  }
}
