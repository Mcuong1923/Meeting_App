import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String id;
  final String name;
  final String description;
  final String? managerId;
  final String? managerName;
  final List<String> memberIds;
  final List<String> teamIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalData;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.description,
    this.managerId,
    this.managerName,
    this.memberIds = const [],
    this.teamIds = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.additionalData,
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return DepartmentModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      managerId: map['managerId'],
      managerName: map['managerName'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
      teamIds: List<String>.from(map['teamIds'] ?? []),
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
      'managerId': managerId,
      'managerName': managerName,
      'memberIds': memberIds,
      'teamIds': teamIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalData': additionalData,
    };
  }

  DepartmentModel copyWith({
    String? id,
    String? name,
    String? description,
    String? managerId,
    String? managerName,
    List<String>? memberIds,
    List<String>? teamIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      memberIds: memberIds ?? this.memberIds,
      teamIds: teamIds ?? this.teamIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'DepartmentModel(id: $id, name: $name, memberCount: ${memberIds.length})';
  }
}
