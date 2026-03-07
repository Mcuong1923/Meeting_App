import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:iconly/iconly.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_minutes_provider.dart';
import '../models/user_role.dart';
import '../models/meeting_minutes_model.dart';
import '../constants.dart';
import 'minutes_view_screen.dart';

class MinutesArchiveScreen extends StatefulWidget {
  const MinutesArchiveScreen({super.key});

  @override
  State<MinutesArchiveScreen> createState() => _MinutesArchiveScreenState();
}

class _MinutesArchiveScreenState extends State<MinutesArchiveScreen> {
  String _searchQuery = '';
  bool _showArchived = false;
  final TextEditingController _searchController = TextEditingController();

  // ===== Visual tokens (Light mode, match new design style) =====
  static const Color _screenBg = Color(0xFFF6F8FC);
  static const Color _textPrimary = Color(0xFF101828);
  static const Color _textSecondary = Color(0xFF667085);
  static const Color _placeholder = Color(0xFF98A2B3);
  static const Color _cardBorder = Color(0xFFEAF0F6);
  static const Color _chipBorder = Color(0xFFE4E7EC);

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _cardBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final minutesProvider =
        Provider.of<MeetingMinutesProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user != null) {
      minutesProvider.getAllMinutes(
        userId: user.id,
        isGlobalAdmin: user.role == UserRole.admin,
        showArchived: _showArchived,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        title: const Text(
          'Biên bản cuộc họp',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textPrimary,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: Consumer<MeetingMinutesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<MeetingMinutesModel> minutes = provider.allMinutes;

                // Client-side Filtering (Search only, status is already filtered)
                if (_searchQuery.isNotEmpty) {
                  minutes = minutes.where((m) {
                    final query = _searchQuery.toLowerCase();
                    return m.title.toLowerCase().contains(query) ||
                        m.content.toLowerCase().contains(query);
                  }).toList();
                }

                if (minutes.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: minutes.length,
                  itemBuilder: (context, index) {
                    return _buildMinuteCard(minutes[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _screenBg,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm biên bản...',
          prefixIcon: const Icon(IconlyLight.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: _chipBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: _chipBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.6)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _chipBorder, width: 1),
        ),
        child: Row(
          children: [
            Expanded(child: _buildSegment('Đang hoạt động', false)),
            const SizedBox(width: 6),
            Expanded(child: _buildSegment('Đã lưu trữ', true)),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String label, bool isArchived) {
    final isSelected = _showArchived == isArchived;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _showArchived = isArchived;
          _loadData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? kPrimaryColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? kPrimaryColor.withOpacity(0.35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? kPrimaryColor : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconlyLight.document, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy biên bản nào',
            style: TextStyle(
              fontSize: 16,
              color: _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinuteCard(MeetingMinutesModel minute) {
    // Determine status color/text
    Color statusColor;
    String statusText;
    switch (minute.status) {
      case MinutesStatus.approved:
        statusColor = Colors.green;
        statusText = 'Đã duyệt';
        break;
      case MinutesStatus.pending_approval:
        statusColor = Colors.orange;
        statusText = 'Chờ duyệt';
        break;
      case MinutesStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Đã từ chối';
        break;
      case MinutesStatus.draft:
      default:
        statusColor = Colors.grey;
        statusText = 'Nháp';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MinutesViewScreen(minute: minute),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      IconlyBold.document,
                      color: kPrimaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          minute.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phiên bản v${minute.versionNumber} • Bởi ${minute.createdByName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(IconlyLight.time_circle,
                          size: 14, color: _placeholder),
                      const SizedBox(width: 4),
                      Text(
                        'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(minute.updatedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _placeholder,
                        ),
                      ),
                    ],
                  ),
                  const Icon(IconlyLight.arrow_right_2,
                      size: 16, color: _placeholder),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
