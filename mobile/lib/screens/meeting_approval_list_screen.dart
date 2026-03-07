import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/notification_provider.dart';
import '../models/meeting_model.dart';

class MeetingApprovalListScreen extends StatefulWidget {
  const MeetingApprovalListScreen({Key? key}) : super(key: key);

  @override
  State<MeetingApprovalListScreen> createState() =>
      _MeetingApprovalListScreenState();
}

class _MeetingApprovalListScreenState extends State<MeetingApprovalListScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final meetingProvider = Provider.of<MeetingProvider>(context);
    final currentUser = authProvider.userModel;

    // Filter only pending meetings that current user THỰC SỰ có quyền duyệt
    final pendingMeetings = meetingProvider.meetings.where((m) {
      if (m.approvalStatus != MeetingApprovalStatus.pending) return false;
      if (currentUser == null) return false;
      // Không hiển thị cuộc họp do chính mình tạo
      if (m.creatorId == currentUser.id) return false;

      if (currentUser.isSuperAdmin || currentUser.isAdmin) {
        return true;
      } else if (currentUser.isDirector) {
        return m.approvalLevel == MeetingApprovalLevel.department ||
            m.approvalLevel == MeetingApprovalLevel.company;
      } else if (currentUser.isManager) {
        return m.approvalLevel == MeetingApprovalLevel.team;
      }
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phê duyệt cuộc họp',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              'Kiểm tra và xử lý yêu cầu',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : pendingMeetings.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingMeetings.length,
                  itemBuilder: (context, index) {
                    final meeting = pendingMeetings[index];
                    return _buildApprovalCard(meeting);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có yêu cầu nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tất cả cuộc họp đã được xử lý',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(MeetingModel meeting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C1B47).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF2C1B47),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tạo bởi: ${meeting.creatorName}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFF5D48A)),
                  ),
                  child: const Text(
                    'Chờ duyệt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB87400),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEDEDF2)),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.access_time_rounded,
                  '${DateFormat('HH:mm').format(meeting.startTime)} - ${DateFormat('HH:mm').format(meeting.endTime)}',
                  DateFormat('dd/MM/yyyy').format(meeting.startTime),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  meeting.locationType == MeetingLocationType.virtual
                      ? 'Online'
                      : 'Offline',
                  meeting.physicalLocation ?? 'Chưa có địa điểm',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.people_outline,
                  'Người tham gia',
                  '${meeting.participants.length} người',
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleRejection(meeting),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD84343),
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                      backgroundColor: const Color(0xFFFFEBEE),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Từ chối',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApproval(meeting),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C1B47),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Phê duyệt',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF2C1B47).withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF2C1B47)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B2B2B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleApproval(MeetingModel meeting) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C1B47).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF2C1B47),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xác nhận phê duyệt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn phê duyệt cuộc họp "${meeting.title}"?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirm dialog

              if (authProvider.userModel != null) {
                final success = await meetingProvider.approveMeeting(
                  meeting.id,
                  authProvider.userModel!,
                  notificationProvider: notificationProvider,
                );

                if (success && mounted) {
                  _showSuccessOverlay(
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF2E7D32),
                    title: 'Phê duyệt thành công!',
                    subtitle: 'Cuộc họp "${meeting.title}" đã được duyệt',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C1B47),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Phê duyệt',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị toast nhỏ ở dưới màn hình, tự động biến mất
  void _showSuccessOverlay({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _BottomToastWidget(
        icon: icon,
        color: color,
        title: title,
        subtitle: subtitle,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  void _handleRejection(MeetingModel meeting) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Từ chối cuộc họp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do từ chối:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Lý do...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do từ chối'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context); // Close dialog

              if (authProvider.userModel != null) {
                final success = await meetingProvider.rejectMeeting(
                  meeting.id,
                  authProvider.userModel!,
                  reason: reasonController.text.trim(),
                  notificationProvider: notificationProvider,
                );

                if (success && mounted) {
                  _showSuccessOverlay(
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFE53935),
                    title: 'Đã từ chối cuộc họp',
                    subtitle: '"${meeting.title}" đã bị từ chối',
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Toast nhỏ ở dưới màn hình - slide up, tự động biến mất
// ============================================================
class _BottomToastWidget extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onDismiss;

  const _BottomToastWidget({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onDismiss,
  });

  @override
  State<_BottomToastWidget> createState() => _BottomToastWidgetState();
}

class _BottomToastWidgetState extends State<_BottomToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Slide: lên nhanh → giữ → trượt xuống
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 1.5), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, 1.5))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 16,
      ),
    ]).animate(_controller);

    // Fade: hiện nhanh → giữ → mờ dần
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 74,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 16,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Tông màu nhạt pastel từ color gốc
    final bgColor = widget.color.withOpacity(0.08);
    final accentColor = widget.color;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: 20,
          right: 20,
          bottom: bottomPadding + 28,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: accentColor.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Viền trái accent
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Icon nền pastel
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nội dung
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
