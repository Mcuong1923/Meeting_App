import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../models/calendar_model.dart';
import '../models/meeting_model.dart';
import 'meeting_create_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load calendar data sau khi widget được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCalendarData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final calendarProvider =
        Provider.of<CalendarProvider>(context, listen: false);

    print('🔄 CalendarScreen: Loading calendar data...');
    print('🔄 User model is null: ${authProvider.userModel == null}');

    if (authProvider.userModel != null) {
      print('🔄 Loading events for user: ${authProvider.userModel!.id}');
      calendarProvider.loadEvents(
        authProvider.userModel!.id,
        startDate: _focusedDate.subtract(const Duration(days: 30)),
        endDate: _focusedDate.add(const Duration(days: 30)),
      );
    } else {
      print('⚠️ Cannot load calendar data: User not logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch làm việc'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tháng', icon: Icon(Icons.calendar_month, size: 20)),
            Tab(text: 'Tuần', icon: Icon(Icons.view_week, size: 20)),
            Tab(text: 'Ngày', icon: Icon(Icons.today, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedDate = DateTime.now();
              });
              _loadCalendarData();
            },
            tooltip: 'Hôm nay',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCalendarData,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, calendarProvider, child) {
          if (calendarProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMonthView(calendarProvider),
              _buildWeekView(calendarProvider),
              _buildDayView(calendarProvider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MeetingCreateScreen(),
            ),
          ).then((_) {
            // Refresh calendar sau khi tạo meeting
            _loadCalendarData();
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMonthView(CalendarProvider calendarProvider) {
    return Column(
      children: [
        _buildMonthHeader(),
        Expanded(
          child: _buildMonthCalendar(calendarProvider),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month - 1,
                  1,
                );
              });
              _loadCalendarData();
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedDate),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month + 1,
                  1,
                );
              });
              _loadCalendarData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(CalendarProvider calendarProvider) {
    return Column(
      children: [
        _buildWeekDayHeaders(),
        Expanded(
          child: _buildMonthGrid(calendarProvider),
        ),
      ],
    );
  }

  Widget _buildWeekDayHeaders() {
    const weekDays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: weekDays.map((day) {
          return Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthGrid(CalendarProvider calendarProvider) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final startDate =
        firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2, // Tăng tỷ lệ để ô vuông vừa hơn
      ),
      itemCount: 42, // 6 weeks
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final isCurrentMonth = date.month == _focusedDate.month;
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected = _isSameDay(date, _selectedDate);
        final events = calendarProvider.getEventsForDay(date);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });

            // Nếu có events thì hiển thị bottom sheet với details
            if (events.isNotEmpty) {
              _showDayEventsSheet(date, events);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Colors.blue
                    : isToday
                        ? Colors.blue.withOpacity(0.5)
                        : Colors.grey.shade300,
                width: isSelected || isToday ? 2 : 0.5,
              ),
              color: isSelected
                  ? Colors.blue.withOpacity(0.1)
                  : isToday
                      ? Colors.blue.withOpacity(0.05)
                      : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Số ngày
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    color: isCurrentMonth
                        ? (isToday ? Colors.blue : Colors.black87)
                        : Colors.grey.shade400,
                  ),
                ),

                const SizedBox(height: 4),

                // Event indicators
                if (events.isNotEmpty) ...[
                  // Hiển thị dots cho các events (tối đa 3 dots)
                  if (events.length <= 3)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.take(3).map((event) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: _getEventColor(event),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    )
                  // Hiển thị số events nếu > 3
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPrimaryEventColor(events),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${events.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ] else
                  const SizedBox(height: 8), // Placeholder khi không có events
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekView(CalendarProvider calendarProvider) {
    return Column(
      children: [
        _buildWeekHeader(),
        Expanded(
          child: _buildWeekGrid(calendarProvider),
        ),
      ],
    );
  }

  Widget _buildWeekHeader() {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                _focusedDate = _selectedDate;
              });
              _loadCalendarData();
            },
          ),
          Text(
            '${DateFormat('dd/MM').format(startOfWeek)} - ${DateFormat('dd/MM/yyyy').format(startOfWeek.add(const Duration(days: 6)))}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 7));
                _focusedDate = _selectedDate;
              });
              _loadCalendarData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekGrid(CalendarProvider calendarProvider) {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));

    return Column(
      children: [
        _buildWeekDayHeaders(),
        Expanded(
          child: Row(
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final events = calendarProvider.getEventsForDay(date);
              final isToday = _isSameDay(date, DateTime.now());

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    color: isToday
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? Colors.blue : Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _getEventColor(event),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayView(CalendarProvider calendarProvider) {
    return Column(
      children: [
        _buildDayHeader(),
        Expanded(
          child: _buildDaySchedule(calendarProvider),
        ),
      ],
    );
  }

  Widget _buildDayHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                _focusedDate = _selectedDate;
              });
              _loadCalendarData();
            },
          ),
          Text(
            DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
                _focusedDate = _selectedDate;
              });
              _loadCalendarData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(CalendarProvider calendarProvider) {
    final events = calendarProvider.getEventsForDay(_selectedDate);

    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có sự kiện nào trong ngày',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getEventColor(event),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}'),
                if (event.location?.isNotEmpty == true)
                  Text('📍 ${event.location}'),
              ],
            ),
            onTap: () => _showEventDetails(event),
          ),
        );
      },
    );
  }

  Color _getEventColor(CalendarEvent event) {
    // Màu sắc theo meeting status nếu là cuộc họp
    if (event.type == CalendarEventType.meeting && event.color != null) {
      try {
        return Color(int.parse(event.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback to default colors
      }
    }

    // Màu sắc theo priority
    switch (event.priority) {
      case CalendarEventPriority.urgent:
        return Colors.red.shade600;
      case CalendarEventPriority.high:
        return Colors.orange.shade600;
      case CalendarEventPriority.medium:
        return Colors.blue.shade600;
      case CalendarEventPriority.low:
        return Colors.grey.shade600;
    }
  }

  // Lấy màu chính khi có nhiều events (ưu tiên urgent > high > medium > low)
  Color _getPrimaryEventColor(List<CalendarEvent> events) {
    if (events.any((e) => e.priority == CalendarEventPriority.urgent)) {
      return Colors.red.shade600;
    } else if (events.any((e) => e.priority == CalendarEventPriority.high)) {
      return Colors.orange.shade600;
    } else if (events.any((e) => e.priority == CalendarEventPriority.medium)) {
      return Colors.blue.shade600;
    } else {
      return Colors.grey.shade600;
    }
  }

  // Hiển thị bottom sheet với danh sách events của ngày
  void _showDayEventsSheet(DateTime date, List<CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Ngày ${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${events.length} cuộc họp',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Events list
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getEventColor(event).withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Color indicator
                            Container(
                              width: 4,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _getEventColor(event),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Event content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (event.description?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      event.description!,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Priority badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getEventColor(event).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                event.priority
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: _getEventColor(event),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showEventDetails(CalendarEvent event) {
    // Lấy title gốc từ metadata nếu có
    String originalTitle = event.metadata?['originalTitle'] ?? event.title;
    String statusText = '';

    if (event.type == CalendarEventType.meeting && event.metadata != null) {
      String status = event.metadata!['meetingStatus'] ?? '';
      switch (status) {
        case 'pending':
          statusText = '⏳ Chờ duyệt';
          break;
        case 'approved':
          statusText = '✅ Đã duyệt';
          break;
        case 'rejected':
          statusText = '❌ Từ chối';
          break;
        case 'cancelled':
          statusText = '🚫 Đã hủy';
          break;
        case 'completed':
          statusText = '🏁 Hoàn thành';
          break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(originalTitle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusText.isNotEmpty) ...[
              Text(
                statusText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('dd/MM/yyyy HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                ),
              ],
            ),
            if (event.location?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(child: Text(event.location!)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Người tạo: ${event.creatorName}'),
              ],
            ),
            if (event.participantIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${event.participantIds.length} người tham gia'),
                ],
              ),
            ],
            if (event.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              const Text('Mô tả:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(event.description!),
            ],
          ],
        ),
        actions: [
          if (event.type == CalendarEventType.meeting &&
              event.meetingId != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to meeting detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xem chi tiết cuộc họp')),
                );
              },
              child: const Text('Chi tiết'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
