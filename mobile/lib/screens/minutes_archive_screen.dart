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
      backgroundColor: kScaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Biên bản cuộc họp',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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
                        (m.content?.toLowerCase().contains(query) ?? false);
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
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm biên bản...',
          prefixIcon: const Icon(IconlyLight.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChoiceChip('Đang hoạt động', false),
          const SizedBox(width: 8),
          _buildChoiceChip('Đã lưu trữ', true),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isArchived) {
    final isSelected = _showArchived == isArchived;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _showArchived = isArchived;
          _loadData();
        });
      },
      selectedColor: kPrimaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? kPrimaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? kPrimaryColor : Colors.grey.shade300,
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
          Text(
            'Không tìm thấy biên bản nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MinutesViewScreen(minute: minute),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
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
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phiên bản v${minute.versionNumber} • Bởi ${minute.createdByName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
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
                      Icon(IconlyLight.time_circle,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(minute.updatedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  Icon(IconlyLight.arrow_right_2,
                      size: 16, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
