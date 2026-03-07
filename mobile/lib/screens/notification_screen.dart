import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:metting_app/providers/notification_provider.dart';
import 'package:metting_app/providers/auth_provider.dart' as app_auth;
import 'package:metting_app/models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  // ===== Visual tokens (Light mode, match new notification design) =====
  static const Color _screenBg = Color(0xFFF6F8FC);
  // "System blue" accent just for Notifications (keep app global primary as-is).
  static const Color _accentBlue = Color(0xFF007AFF);
  static const Color _accentBlue2 = Color(0xFF2F80FF);
  static const Color _textPrimary = Color(0xFF101828);
  static const Color _textSecondary = Color(0xFF667085);
  static const Color _placeholder = Color(0xFF98A2B3);
  static const double _cardRadius = 24;
  static const double _accentWidth = 5;

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
      backgroundColor: _screenBg,
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textPrimary,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return IconButton(
                  onPressed: () => _markAllAsRead(),
                  tooltip: 'Đánh dấu tất cả đã đọc',
                  icon: const Icon(Icons.done_all_rounded, size: 22),
                );
              }
              return const SizedBox();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
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
          labelColor: _accentBlue,
          unselectedLabelColor: _textSecondary,
          indicatorColor: _accentBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            const Tab(text: 'Tất cả'),
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                final showDot = provider.unreadCount > 0;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Chưa đọc'),
                      if (showDot) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'Quan trọng'),
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
            const Text(
              'Không có thông báo',
              style: TextStyle(
                fontSize: 18,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thông báo mới sẽ xuất hiện ở đây',
              style: TextStyle(
                fontSize: 14,
                color: _placeholder,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = notification.isUnread;
    final visual = _getNotificationVisual(notification.type);
    final sender = (notification.senderName ?? '').trim();
    final meta = [
      if (sender.isNotEmpty) sender,
      DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
    ].join(' • ');

    final cardColor = isUnread
        ? Color.alphaBlend(_accentBlue.withOpacity(0.03), Colors.white)
        : Colors.white;
    final cardShadow = isUnread
        ? BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          )
        : BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 8),
          );

    return InkWell(
      onTap: () async {
        if (!notification.isRead) {
          final provider =
              Provider.of<NotificationProvider>(context, listen: false);
          await provider.markAsRead(notification.id);
        }

        if (notification.meetingId != null) {
          Navigator.pushNamed(
            context,
            '/meeting-detail',
            arguments: notification.meetingId,
          );
        }
      },
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [cardShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Stack(
            children: [
              // Left accent strip for unread
              if (isUnread)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: _accentWidth,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_accentBlue2, _accentBlue],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_cardRadius),
                        bottomLeft: Radius.circular(_cardRadius),
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: visual.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        visual.icon,
                        color: visual.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isUnread
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                              ),
                              if (isUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: _accentBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: _textSecondary,
                              fontWeight:
                                  isUnread ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            meta,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _placeholder,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NotificationVisual _getNotificationVisual(NotificationType type) {
    switch (type) {
      case NotificationType.meetingInvitation:
        return const _NotificationVisual(
          icon: Icons.group_add_rounded,
          color: Color(0xFF3B82F6),
        );
      case NotificationType.meetingApprovalResult:
        return const _NotificationVisual(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF22C55E),
        );
      case NotificationType.meetingApproval:
        return const _NotificationVisual(
          icon: Icons.approval_rounded,
          color: Color(0xFFF59E0B),
        );
      case NotificationType.meetingReminder:
      case NotificationType.reminder:
        return const _NotificationVisual(
          icon: Icons.notifications_active_rounded,
          color: Color(0xFFF97316),
        );
      case NotificationType.meetingCancelled:
        return const _NotificationVisual(
          icon: Icons.cancel_rounded,
          color: Color(0xFFEF4444),
        );
      case NotificationType.meetingUpdated:
        return const _NotificationVisual(
          icon: Icons.update_rounded,
          color: Color(0xFF8B5CF6),
        );
      case NotificationType.roomMaintenance:
        return const _NotificationVisual(
          icon: Icons.build_rounded,
          color: Color(0xFFF59E0B),
        );
      case NotificationType.roleChange:
        return const _NotificationVisual(
          icon: Icons.admin_panel_settings_rounded,
          color: Color(0xFF6366F1),
        );
      case NotificationType.error:
        return const _NotificationVisual(
          icon: Icons.error_rounded,
          color: Color(0xFFEF4444),
        );
      case NotificationType.warning:
        return const _NotificationVisual(
          icon: Icons.warning_rounded,
          color: Color(0xFFF59E0B),
        );
      case NotificationType.success:
        return const _NotificationVisual(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF22C55E),
        );
      case NotificationType.system:
        return const _NotificationVisual(
          icon: Icons.settings_rounded,
          color: Color(0xFF64748B),
        );
      default:
        return const _NotificationVisual(
          icon: Icons.notifications_rounded,
          color: Color(0xFF3B82F6),
        );
    }
  }

  void _markAllAsRead() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAllAsRead();
  }
}

class _NotificationVisual {
  final IconData icon;
  final Color color;
  const _NotificationVisual({required this.icon, required this.color});
}
