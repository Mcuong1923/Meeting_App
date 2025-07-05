import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:metting_app/providers/notification_provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/models/notification_model.dart';
import 'package:metting_app/constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadNotifications() {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      notificationProvider.loadNotifications(authProvider.userModel!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kPrimaryColor,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () => _markAllAsRead(),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Đánh dấu tất cả'),
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimaryColor,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Tất cả'),
              ),
              const PopupMenuItem(
                value: 'unread',
                child: Text('Chưa đọc'),
              ),
              const PopupMenuItem(
                value: 'meeting',
                child: Text('Cuộc họp'),
              ),
              const PopupMenuItem(
                value: 'urgent',
                child: Text('Khẩn cấp'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kPrimaryColor,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chưa đọc'),
            Tab(text: 'Quan trọng'),
          ],
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    provider.error,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(
                  _getFilteredNotifications(provider.notifications)),
              _buildNotificationList(provider.unreadNotifications),
              _buildNotificationList(provider
                      .getNotificationsByPriority(NotificationPriority.high) +
                  provider
                      .getNotificationsByPriority(NotificationPriority.urgent)),
            ],
          );
        },
      ),
    );
  }

  List<NotificationModel> _getFilteredNotifications(
      List<NotificationModel> notifications) {
    switch (_selectedFilter) {
      case 'unread':
        return notifications.where((n) => n.isUnread).toList();
      case 'meeting':
        return notifications
            .where((n) =>
                n.type == NotificationType.meetingApproval ||
                n.type == NotificationType.meetingApprovalResult ||
                n.type == NotificationType.meetingReminder ||
                n.type == NotificationType.meetingInvitation ||
                n.type == NotificationType.meetingCancelled ||
                n.type == NotificationType.meetingUpdated)
            .toList();
      case 'urgent':
        return notifications
            .where((n) =>
                n.priority == NotificationPriority.urgent ||
                n.priority == NotificationPriority.high)
            .toList();
      default:
        return notifications;
    }
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có thông báo',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thông báo mới sẽ xuất hiện ở đây',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: notification.isUnread ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isUnread
              ? BorderSide(color: kPrimaryColor.withOpacity(0.3), width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _onNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    _buildNotificationIcon(notification),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: notification.isUnread
                                  ? Colors.black87
                                  : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildPriorityChip(notification.priority),
                              const SizedBox(width: 8),
                              Text(
                                notification.typeDisplayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (notification.isUnread) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: notification.isUnread
                        ? Colors.black87
                        : Colors.grey[600],
                    height: 1.4,
                  ),
                ),

                // Actions
                if (notification.type == NotificationType.meetingApproval) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _handleApprovalAction(notification, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Từ chối'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _handleApprovalAction(notification, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Phê duyệt'),
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

  Widget _buildNotificationIcon(NotificationModel notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.meetingApproval:
        icon = Icons.approval;
        color = Colors.orange;
        break;
      case NotificationType.meetingApprovalResult:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.meetingReminder:
        icon = Icons.access_time;
        color = Colors.blue;
        break;
      case NotificationType.meetingCancelled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case NotificationType.meetingUpdated:
        icon = Icons.update;
        color = Colors.purple;
        break;
      case NotificationType.meetingInvitation:
        icon = Icons.event_available;
        color = Colors.teal;
        break;
      case NotificationType.roomMaintenance:
        icon = Icons.build;
        color = Colors.amber;
        break;
      case NotificationType.roleChange:
        icon = Icons.admin_panel_settings;
        color = Colors.indigo;
        break;
      case NotificationType.systemUpdate:
        icon = Icons.system_update;
        color = Colors.cyan;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildPriorityChip(NotificationPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case NotificationPriority.urgent:
        color = Colors.red;
        text = 'Khẩn cấp';
        break;
      case NotificationPriority.high:
        color = Colors.orange;
        text = 'Cao';
        break;
      case NotificationPriority.normal:
        color = Colors.blue;
        text = 'Bình thường';
        break;
      case NotificationPriority.low:
        color = Colors.grey;
        text = 'Thấp';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  void _onNotificationTap(NotificationModel notification) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    // Mark as read
    if (notification.isUnread) {
      provider.markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.meetingApproval:
      case NotificationType.meetingApprovalResult:
      case NotificationType.meetingReminder:
      case NotificationType.meetingInvitation:
      case NotificationType.meetingCancelled:
      case NotificationType.meetingUpdated:
        if (notification.meetingId != null) {
          // Navigate to meeting details
          _navigateToMeeting(notification.meetingId!);
        }
        break;
      case NotificationType.roomMaintenance:
        if (notification.roomId != null) {
          // Navigate to room details
          _navigateToRoom(notification.roomId!);
        }
        break;
      default:
        // Show notification details
        _showNotificationDetails(notification);
    }
  }

  void _navigateToMeeting(String meetingId) {
    // TODO: Navigate to meeting details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chuyển đến cuộc họp: $meetingId')),
    );
  }

  void _navigateToRoom(String roomId) {
    // TODO: Navigate to room details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chuyển đến phòng: $roomId')),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Loại: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(notification.typeDisplayName),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Ưu tiên: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(notification.priorityDisplayName),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Thời gian: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(DateFormat('dd/MM/yyyy HH:mm')
                    .format(notification.createdAt)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (notification.isUnread)
            TextButton(
              onPressed: () {
                Provider.of<NotificationProvider>(context, listen: false)
                    .markAsRead(notification.id);
                Navigator.pop(context);
              },
              child: const Text('Đánh dấu đã đọc'),
            ),
        ],
      ),
    );
  }

  void _handleApprovalAction(NotificationModel notification, bool approve) {
    // TODO: Implement approval action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'Đã phê duyệt' : 'Đã từ chối'),
        backgroundColor: approve ? Colors.green : Colors.red,
      ),
    );
  }

  void _markAllAsRead() {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      provider.markAllAsRead(authProvider.userModel!.id);
    }
  }
}
