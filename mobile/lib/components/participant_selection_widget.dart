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
  List<UserModel> _filteredParticipants = [];
  UserRole? _selectedRoleFilter;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _filteredParticipants = widget.availableParticipants;
    _updateSelectAllState();
  }

  @override
  void didUpdateWidget(ParticipantSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableParticipants != widget.availableParticipants) {
      _filteredParticipants = widget.availableParticipants;
      _filterParticipants();
    }
    if (oldWidget.selectedParticipants != widget.selectedParticipants) {
      _updateSelectAllState();
    }
  }

  void _filterParticipants() {
    String searchQuery = _searchController.text.toLowerCase();

    setState(() {
      _filteredParticipants = widget.availableParticipants.where((user) {
        bool matchesSearch = searchQuery.isEmpty ||
            user.displayName.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery);

        bool matchesRole =
            _selectedRoleFilter == null || user.role == _selectedRoleFilter;

        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _updateSelectAllState() {
    setState(() {
      _selectAll = _filteredParticipants.isNotEmpty &&
          _filteredParticipants.every((user) => widget.selectedParticipants
              .any((selected) => selected.id == user.id));
    });
  }

  void _toggleSelectAll() {
    List<UserModel> newSelection = List.from(widget.selectedParticipants);

    if (_selectAll) {
      // Deselect all filtered participants
      for (UserModel user in _filteredParticipants) {
        newSelection.removeWhere((selected) => selected.id == user.id);
      }
    } else {
      // Select all filtered participants
      for (UserModel user in _filteredParticipants) {
        if (!newSelection.any((selected) => selected.id == user.id)) {
          newSelection.add(user);
        }
      }
    }

    widget.onSelectionChanged(newSelection);
  }

  void _toggleParticipant(UserModel user) {
    List<UserModel> newSelection = List.from(widget.selectedParticipants);

    bool isSelected = newSelection.any((selected) => selected.id == user.id);

    if (isSelected) {
      newSelection.removeWhere((selected) => selected.id == user.id);
    } else {
      newSelection.add(user);
    }

    widget.onSelectionChanged(newSelection);
  }

  bool _isSelected(UserModel user) {
    return widget.selectedParticipants
        .any((selected) => selected.id == user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7BE9).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: const Color(0xFF2E7BE9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7BE9),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.selectedParticipants.length}/${widget.availableParticipants.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Search và Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                if (widget.showSearch)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _filterParticipants(),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên hoặc email...',
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey.shade500),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Controls row
                Row(
                  children: [
                    // Select All checkbox
                    if (widget.showSelectAll &&
                        _filteredParticipants.isNotEmpty)
                      Expanded(
                        child: CheckboxListTile(
                          title: Text(
                            'Chọn tất cả',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          value: _selectAll,
                          onChanged: (_) => _toggleSelectAll(),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),

                    // Role filter
                    if (widget.showRoleFilter)
                      Expanded(
                        child: DropdownButton<UserRole?>(
                          value: _selectedRoleFilter,
                          hint: const Text('Lọc theo vai trò'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Tất cả vai trò'),
                            ),
                            ...UserRole.values.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(_getRoleDisplayName(role)),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRoleFilter = value;
                              _filterParticipants();
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Participants list
          Container(
            constraints: BoxConstraints(
              maxHeight: widget.maxHeight?.toDouble() ?? 400,
            ),
            child: _filteredParticipants.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredParticipants.length,
                    itemBuilder: (context, index) {
                      final user = _filteredParticipants[index];
                      return _buildParticipantItem(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy người tham gia phù hợp',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(UserModel user) {
    final isSelected = _isSelected(user);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2E7BE9).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF2E7BE9), width: 1)
            : null,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => _toggleParticipant(user),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleColor(user.role),
              child: user.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                      ),
                    )
                  : Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getRoleDisplayName(user.role),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getRoleColor(user.role),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.director:
        return 'Giám đốc';
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.employee:
        return 'Nhân viên';
      case UserRole.guest:
        return 'Khách';
    }
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
