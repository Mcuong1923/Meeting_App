import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/meeting_model.dart';
import '../providers/organization_provider.dart';

class ParticipantSuggestionService {
  final OrganizationProvider _organizationProvider;

  ParticipantSuggestionService(this._organizationProvider);

  /// Suggest participants dựa trên meeting type và selection
  Future<List<UserModel>> getSuggestedParticipants({
    required MeetingType meetingType,
    String? selectedDepartmentId,
    String? selectedTeamId,
    String? currentUserId,
  }) async {
    try {
      List<UserModel> suggestions = [];

      switch (meetingType) {
        case MeetingType.department:
          if (selectedDepartmentId != null) {
            suggestions = await _organizationProvider.getSuggestedParticipants(
              meetingType,
              departmentId: selectedDepartmentId,
              currentUserId: currentUserId,
            );
          }
          break;

        case MeetingType.team:
          if (selectedTeamId != null) {
            suggestions = await _organizationProvider.getSuggestedParticipants(
              meetingType,
              teamId: selectedTeamId,
              currentUserId: currentUserId,
            );
          }
          break;

        case MeetingType.company:
          suggestions = await _organizationProvider.getSuggestedParticipants(
            meetingType,
            currentUserId: currentUserId,
          );
          break;

        case MeetingType.personal:
          // Personal meeting không tự động suggest
          suggestions = [];
          break;
      }

      return suggestions;
    } catch (e) {
      debugPrint('❌ Error getting suggested participants: $e');
      return [];
    }
  }

  /// Convert UserModel thành MeetingParticipant
  List<MeetingParticipant> convertToMeetingParticipants(
    List<UserModel> users, {
    String defaultRole = 'participant',
    bool isRequired = true,
  }) {
    return users.map((user) {
      return MeetingParticipant(
        userId: user.id,
        userName: user.displayName,
        userEmail: user.email,
        role: defaultRole,
        isRequired: isRequired,
        hasConfirmed: false,
      );
    }).toList();
  }

  /// Lọc participants theo role
  List<UserModel> filterParticipantsByRole(
    List<UserModel> participants,
    List<UserRole> allowedRoles,
  ) {
    return participants
        .where((user) => allowedRoles.contains(user.role))
        .toList();
  }

  /// Lọc participants theo department
  List<UserModel> filterParticipantsByDepartment(
    List<UserModel> participants,
    String departmentId,
  ) {
    return participants
        .where((user) => user.departmentId == departmentId)
        .toList();
  }

  /// Lọc participants theo team
  List<UserModel> filterParticipantsByTeam(
    List<UserModel> participants,
    String teamName,
  ) {
    return participants
        .where((user) => user.teamNames.contains(teamName))
        .toList();
  }

  /// Search participants by name or email
  List<UserModel> searchParticipants(
    List<UserModel> participants,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return participants;

    final lowerQuery = searchQuery.toLowerCase();
    return participants.where((user) {
      return user.displayName.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Sắp xếp participants theo role hierarchy
  List<UserModel> sortParticipantsByRole(List<UserModel> participants) {
    const roleOrder = {
      UserRole.admin: 1,
      UserRole.director: 2,
      UserRole.manager: 3,
      UserRole.employee: 4,
      UserRole.guest: 5,
    };

    participants.sort((a, b) {
      int roleComparison =
          (roleOrder[a.role] ?? 6).compareTo(roleOrder[b.role] ?? 6);
      if (roleComparison != 0) return roleComparison;

      // Nếu role giống nhau, sắp xếp theo tên
      return a.displayName.compareTo(b.displayName);
    });

    return participants;
  }

  /// Get default meeting participants based on meeting type
  Future<List<UserModel>> getDefaultParticipants({
    required MeetingType meetingType,
    required UserModel currentUser,
  }) async {
    try {
      List<UserModel> defaultParticipants = [];

      switch (meetingType) {
        case MeetingType.department:
          if (currentUser.departmentId != null) {
            defaultParticipants =
                await _organizationProvider.getSuggestedParticipants(
              meetingType,
              departmentId: currentUser.departmentId!,
              currentUserId: currentUser.id,
            );
          }
          break;

        case MeetingType.team:
          // Lấy team đầu tiên của user
          if (currentUser.teamNames.isNotEmpty) {
            final firstTeam = currentUser.teamNames.first;
            final teamId = '${currentUser.departmentId}_$firstTeam';

            defaultParticipants =
                await _organizationProvider.getSuggestedParticipants(
              meetingType,
              teamId: teamId,
              currentUserId: currentUser.id,
            );
          }
          break;

        case MeetingType.company:
          defaultParticipants =
              await _organizationProvider.getSuggestedParticipants(
            meetingType,
            currentUserId: currentUser.id,
          );
          break;

        case MeetingType.personal:
          defaultParticipants = [];
          break;
      }

      return sortParticipantsByRole(defaultParticipants);
    } catch (e) {
      debugPrint('❌ Error getting default participants: $e');
      return [];
    }
  }

  /// Validate participants cho meeting type
  bool validateParticipants({
    required MeetingType meetingType,
    required List<UserModel> participants,
    required UserModel currentUser,
  }) {
    switch (meetingType) {
      case MeetingType.personal:
        return true; // Personal meeting không có giới hạn

      case MeetingType.team:
        // Team meeting nên có ít nhất 2 người (creator + 1 member)
        return participants.isNotEmpty;

      case MeetingType.department:
        // Department meeting nên có ít nhất 2 người
        return participants.isNotEmpty;

      case MeetingType.company:
        // Company meeting nên có ít nhất 3 người
        return participants.length >= 2;
    }
  }

  /// Get meeting participant statistics
  Map<String, int> getParticipantStatistics(List<UserModel> participants) {
    Map<String, int> stats = {
      'total': participants.length,
      'admin': 0,
      'director': 0,
      'manager': 0,
      'employee': 0,
      'guest': 0,
    };

    for (UserModel participant in participants) {
      switch (participant.role) {
        case UserRole.admin:
          stats['admin'] = stats['admin']! + 1;
          break;
        case UserRole.director:
          stats['director'] = stats['director']! + 1;
          break;
        case UserRole.manager:
          stats['manager'] = stats['manager']! + 1;
          break;
        case UserRole.employee:
          stats['employee'] = stats['employee']! + 1;
          break;
        case UserRole.guest:
          stats['guest'] = stats['guest']! + 1;
          break;
      }
    }

    return stats;
  }

  /// Get recommended meeting duration based on participants
  int getRecommendedDuration(List<UserModel> participants) {
    final participantCount = participants.length;

    if (participantCount <= 3) {
      return 30; // 30 phút
    } else if (participantCount <= 8) {
      return 60; // 1 tiếng
    } else if (participantCount <= 15) {
      return 90; // 1.5 tiếng
    } else {
      return 120; // 2 tiếng
    }
  }
}
