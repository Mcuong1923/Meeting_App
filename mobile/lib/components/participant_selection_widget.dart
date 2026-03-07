import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class ParticipantSelectionWidget extends StatefulWidget {
  final List<UserModel> availableParticipants;
  final List<UserModel> selectedParticipants;
  final Function(List<UserModel>) onSelectionChanged;
  final String title;
  final bool showSearch;
  final bool showSelectAll;
  final bool showRoleFilter;
  final int? maxHeight;

  const ParticipantSelectionWidget({
    Key? key,
    required this.availableParticipants,
    required this.selectedParticipants,
    required this.onSelectionChanged,
    this.title = 'Chọn người tham gia',
    this.showSearch = true,
    this.showSelectAll = true,
    this.showRoleFilter = false,
    this.maxHeight = 400,
  }) : super(key: key);

  @override
  State<ParticipantSelectionWidget> createState() =>
      _ParticipantSelectionWidgetState();
}

class _ParticipantSelectionWidgetState
    extends State<ParticipantSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();

  // Drill-down state: null = hiện danh sách team, non-null = hiện thành viên team
  String? _selectedTeamName;

  List<UserModel> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    _filteredMembers = [];
  }

  @override
  void didUpdateWidget(ParticipantSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableParticipants != widget.availableParticipants) {
      if (_selectedTeamName != null) _filterMembers();
    }
  }

  // === TEAM GROUPING ===

  /// Trả về map: teamName → danh sách user trong team đó
  Map<String, List<UserModel>> _groupByTeam() {
    final Map<String, List<UserModel>> groups = {};
    for (final user in widget.availableParticipants) {
      // Lấy tên team đầu tiên, hoặc "Không có nhóm" nếu rỗng
      final teamName = (user.teamNames.isNotEmpty)
          ? user.teamNames.first
          : (user.teamId != null ? user.teamId! : 'Không có nhóm');
      groups.putIfAbsent(teamName, () => []).add(user);
    }
    return groups;
  }

  // === FILTER MEMBERS ===

  void _filterMembers() {
    final query = _searchController.text.toLowerCase().trim();
    final teamMembers = _getMembersOfTeam(_selectedTeamName!);
    setState(() {
      _filteredMembers = query.isEmpty
          ? teamMembers
          : teamMembers.where((u) {
              return u.displayName.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query);
            }).toList();
    });
  }

  List<UserModel> _getMembersOfTeam(String teamName) {
    if (teamName == 'Không có nhóm') {
      return widget.availableParticipants
          .where((u) => u.teamNames.isEmpty && u.teamId == null)
          .toList();
    }
    return widget.availableParticipants
        .where((u) => u.teamNames.contains(teamName))
        .toList();
  }

  // === SELECTION HELPERS ===

  bool _isSelected(UserModel user) {
    return widget.selectedParticipants.any((s) => s.id == user.id);
  }

  void _toggleParticipant(UserModel user) {
    final newSelection = List<UserModel>.from(widget.selectedParticipants);
    if (_isSelected(user)) {
      newSelection.removeWhere((s) => s.id == user.id);
    } else {
      newSelection.add(user);
    }
    widget.onSelectionChanged(newSelection);
  }

  void _selectAllInTeam(List<UserModel> members) {
    final newSelection = List<UserModel>.from(widget.selectedParticipants);
    final allSelected = members.every((u) => _isSelected(u));
    if (allSelected) {
      newSelection.removeWhere((s) => members.any((m) => m.id == s.id));
    } else {
      for (final u in members) {
        if (!newSelection.any((s) => s.id == u.id)) newSelection.add(u);
      }
    }
    widget.onSelectionChanged(newSelection);
  }

  int _selectedCountInTeam(List<UserModel> members) {
    return members.where((u) => _isSelected(u)).length;
  }

  // === BUILD ===

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedTeamName != null) _buildMemberView() else _buildTeamView(),
      ],
    );
  }

  // ── TEAM LIST VIEW ──────────────────────────────────────────────────────────

  Widget _buildTeamView() {
    final groups = _groupByTeam();

    if (groups.isEmpty) {
      return _buildEmptyState('Không có thành viên nào');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        final teamName = entry.key;
        final members = entry.value;
        final selected = _selectedCountInTeam(members);

        return _buildTeamTile(
          teamName: teamName,
          memberCount: members.length,
          selectedCount: selected,
          onTap: () {
            setState(() {
              _selectedTeamName = teamName;
              _searchController.clear();
              _filteredMembers = members;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTeamTile({
    required String teamName,
    required int memberCount,
    required int selectedCount,
    required VoidCallback onTap,
  }) {
    final hasSelection = selectedCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasSelection
              ? const Color(0xFF2E7BE9).withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSelection
                ? const Color(0xFF2E7BE9).withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasSelection
                    ? const Color(0xFF2E7BE9).withOpacity(0.15)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.group_outlined,
                size: 20,
                color: hasSelection
                    ? const Color(0xFF2E7BE9)
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$memberCount thành viên'
                    '${hasSelection ? ' · $selectedCount đã chọn' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasSelection
                          ? const Color(0xFF2E7BE9)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── MEMBER VIEW ─────────────────────────────────────────────────────────────

  Widget _buildMemberView() {
    final teamMembers = _getMembersOfTeam(_selectedTeamName!);
    final displayList =
        _searchController.text.isNotEmpty ? _filteredMembers : teamMembers;
    final allSelected = teamMembers.isNotEmpty &&
        teamMembers.every((u) => _isSelected(u));
    final selectedCount = _selectedCountInTeam(teamMembers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back header
        Container(
          color: Colors.transparent,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: const Color(0xFF2E7BE9),
                onPressed: () {
                  setState(() {
                    _selectedTeamName = null;
                    _searchController.clear();
                    _filteredMembers = [];
                  });
                },
              ),
              Expanded(
                child: Text(
                  _selectedTeamName!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '$selectedCount/${teamMembers.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: selectedCount > 0
                        ? const Color(0xFF2E7BE9)
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search + select all
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Column(
            children: [
              // Search
              if (widget.showSearch)
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterMembers(),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),

              // Select all
              if (widget.showSelectAll && teamMembers.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Checkbox(
                      value: allSelected,
                      onChanged: (_) => _selectAllInTeam(teamMembers),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    GestureDetector(
                      onTap: () => _selectAllInTeam(teamMembers),
                      child: Text(
                        'Chọn tất cả nhóm',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Member list
        if (displayList.isEmpty)
          _buildEmptyState('Không tìm thấy thành viên')
        else
          ...displayList.map((user) => _buildParticipantItem(user)),
      ],
    );
  }

  // ── SHARED WIDGETS ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(UserModel user) {
    final isSelected = _isSelected(user);

    return InkWell(
      onTap: () => _toggleParticipant(user),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7BE9).withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF2E7BE9).withOpacity(0.3))
              : Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: _getRoleColor(user.role),
              child: user.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        fit: BoxFit.cover,
                        width: 36,
                        height: 36,
                        errorBuilder: (_, __, ___) => _initialAvatar(user),
                      ),
                    )
                  : _initialAvatar(user),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isNotEmpty ? user.displayName : user.email,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleParticipant(user),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              activeColor: const Color(0xFF2E7BE9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialAvatar(UserModel user) {
    return Text(
      user.displayName.isNotEmpty
          ? user.displayName[0].toUpperCase()
          : user.email.isNotEmpty
              ? user.email[0].toUpperCase()
              : '?',
      style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.director:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.employee:
        return Colors.green;
      case UserRole.guest:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
