import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconly/iconly.dart';
import '../models/meeting_minutes_model.dart';
import '../constants.dart';
import '../providers/meeting_provider.dart';
import 'meeting_detail_screen.dart';

class MinutesViewScreen extends StatelessWidget {
  final MeetingMinutesModel minute;

  const MinutesViewScreen({
    super.key,
    required this.minute,
  });

  @override
  Widget build(BuildContext context) {
    // Format status
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Chi tiết biên bản'),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.info_square),
            tooltip: 'Xem thông tin cuộc họp',
            onPressed: () => _navigateToMeeting(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title and Version
            Text(
              minute.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'v${minute.versionNumber}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(minute.createdAt),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metadata Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildMetaRow(
                      'Người tạo', minute.createdByName, IconlyLight.profile),
                  const SizedBox(height: 12),
                  _buildMetaRow(
                      'Người cập nhật', minute.updatedByName, IconlyLight.edit),
                  if (minute.approvedBy != null) ...[
                    const SizedBox(height: 12),
                    _buildMetaRow('Người duyệt', minute.approvedByName ?? 'N/A',
                        IconlyLight.tick_square),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content
            const Text(
              'Nội dung biên bản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                minute.content ?? 'Không có nội dung',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Link to Meeting
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _navigateToMeeting(context),
                icon: const Icon(IconlyBold.video),
                label: const Text('Xem cuộc họp liên quan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToMeeting(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingDetailScreen(meetingId: minute.meetingId),
      ),
    );
  }
}
