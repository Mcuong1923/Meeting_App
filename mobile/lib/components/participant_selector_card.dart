import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../components/participant_selection_widget.dart';

class ParticipantSelectorCard extends StatelessWidget {
  final List<UserModel> selectedParticipants;
  final List<UserModel> availableParticipants;
  final String? selectedDepartmentName;
  final String? selectedTeamName;
  final MeetingType meetingType;
  final bool isLoading;
  final ValueChanged<List<UserModel>> onParticipantsChanged;
  final VoidCallback? onTap;
  final String? errorText;

  const ParticipantSelectorCard({
    Key? key,
    required this.selectedParticipants,
    required this.availableParticipants,
    this.selectedDepartmentName,
    this.selectedTeamName,
    required this.meetingType,
    this.isLoading = false,
    required this.onParticipantsChanged,
    this.onTap,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? Colors.grey[800]! : Colors.purple[50]!,
            isDark ? Colors.grey[850]! : Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: errorText != null
              ? Colors.red.withOpacity(0.5)
              : isDark
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey[200]!,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _showParticipantSelector(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people,
                        color: Colors.purple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Người tham gia',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nhấn để chọn người tham gia',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.purple,
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selected count and source
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedParticipants.length} người',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_getSourceText().isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getSourceText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Participants preview
                if (selectedParticipants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildParticipantsPreview(context),
                ],

                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsPreview(BuildContext context) {
    final theme = Theme.of(context);
    final displayParticipants = selectedParticipants.take(3).toList();
    final remainingCount =
        selectedParticipants.length - displayParticipants.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đã chọn:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...displayParticipants.map(
                (participant) => _buildParticipantChip(context, participant)),
            if (remainingCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '+$remainingCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantChip(BuildContext context, UserModel participant) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: _getRoleColor(participant.role),
            child: Text(
              participant.displayName.isNotEmpty
                  ? participant.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            participant.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.director:
        return Colors.orange;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.employee:
        return Colors.green;
      case UserRole.guest:
        return Colors.grey;
    }
  }

  String _getSourceText() {
    switch (meetingType) {
      case MeetingType.department:
        return selectedDepartmentName ?? 'Phòng ban';
      case MeetingType.team:
        return selectedTeamName ?? 'Nhóm';
      case MeetingType.company:
        return 'Công ty';
      case MeetingType.personal:
        return 'Cá nhân';
    }
  }

  Future<void> _showParticipantSelector(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Chọn người tham gia',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Participant selection widget
              Expanded(
                child: ParticipantSelectionWidget(
                  availableParticipants: availableParticipants,
                  selectedParticipants: selectedParticipants,
                  onSelectionChanged: (participants) {
                    onParticipantsChanged(participants);
                  },
                  showRoleFilter: true,
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Xác nhận (${selectedParticipants.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
