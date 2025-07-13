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
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.1),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2E7BE9),
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              tabAlignment: TabAlignment.fill,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  text: 'Tháng',
                  icon: Icon(Icons.calendar_month, size: 18),
                ),
                Tab(
                  text: 'Tuần',
                  icon: Icon(Icons.view_week, size: 18),
                ),
                Tab(
                  text: 'Ngày',
                  icon: Icon(Icons.today, size: 18),
                ),
              ],
            ),
          ),
        ),
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
        backgroundColor: const Color(0xFF2E7BE9),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.event_note, size: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.grey.shade700),
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
          ),
          Text(
            DateFormat('MMMM yyyy', 'vi_VN').format(_focusedDate),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.grey.shade700),
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
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: weekDays.map((day) {
          return Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected
                    ? const Color(0xFF2E7BE9)
                    : isToday
                        ? const Color(0xFF2E7BE9).withOpacity(0.1)
                        : Colors.white,
                boxShadow: isSelected || isToday
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2E7BE9).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                border: isToday && !isSelected
                    ? Border.all(
                        color: const Color(0xFF2E7BE9),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Số ngày
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isCurrentMonth
                              ? (isToday
                                  ? const Color(0xFF2E7BE9)
                                  : Colors.grey.shade800)
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
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : _getEventColor(event),
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
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : _getPrimaryEventColor(events),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${events.length}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ] else
                    const SizedBox(
                        height: 8), // Placeholder khi không có events
                ],
              ),
            ),
          );
        },
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.grey.shade700),
              onPressed: () {
                setState(() {
                  _selectedDate =
                      _selectedDate.subtract(const Duration(days: 7));
                  _focusedDate = _selectedDate;
                });
                _loadCalendarData();
              },
            ),
          ),
          Text(
            '${DateFormat('dd/MM').format(startOfWeek)} - ${DateFormat('dd/MM/yyyy').format(startOfWeek.add(const Duration(days: 6)))}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.grey.shade700),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 7));
                  _focusedDate = _selectedDate;
                });
                _loadCalendarData();
              },
            ),
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
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(7, (index) {
                final date = startOfWeek.add(Duration(days: index));
                final events = calendarProvider.getEventsForDay(date);
                final isToday = _isSameDay(date, DateTime.now());
                final isSelected = _isSameDay(date, _selectedDate);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Date header
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2E7BE9)
                                  : isToday
                                      ? const Color(0xFF2E7BE9).withOpacity(0.1)
                                      : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: const Color(0xFF2E7BE9),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? const Color(0xFF2E7BE9)
                                          : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Events list
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            child: events.isEmpty
                                ? Center(
                                    child: Icon(
                                      Icons.event_busy,
                                      color: Colors.grey.shade300,
                                      size: 24,
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: events.length,
                                    itemBuilder: (context, eventIndex) {
                                      final event = events[eventIndex];
                                      return GestureDetector(
                                        onTap: () => _showEventDetails(event),
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getEventColor(event),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getEventColor(event)
                                                    .withOpacity(0.3),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                DateFormat('HH:mm')
                                                    .format(event.startTime),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                event.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                              if (event.location?.isNotEmpty ==
                                                  true) ...[
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      color: Colors.white70,
                                                      size: 8,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Expanded(
                                                      child: Text(
                                                        event.location!,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 9,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.grey.shade700),
              onPressed: () {
                setState(() {
                  _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1));
                  _focusedDate = _selectedDate;
                });
                _loadCalendarData();
              },
            ),
          ),
          Text(
            DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(_selectedDate),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.grey.shade700),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                  _focusedDate = _selectedDate;
                });
                _loadCalendarData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(CalendarProvider calendarProvider) {
    final events = calendarProvider.getEventsForDay(_selectedDate);

    if (events.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Không có sự kiện nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hôm nay bạn rảnh rỗi',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sắp xếp events theo thời gian
    events.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2E7BE9).withOpacity(0.1),
                  const Color(0xFF2E7BE9).withOpacity(0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2E7BE9).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7BE9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_note,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch trình hôm nay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        '${events.length} cuộc họp đã lên lịch',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7BE9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${events.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Events list
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isFirstEvent = index == 0;
                final isLastEvent = index == events.length - 1;

                return Container(
                  margin: EdgeInsets.only(
                    bottom: isLastEvent ? 0 : 16,
                  ),
                  child: GestureDetector(
                    onTap: () => _showEventDetails(event),
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                        border: Border.all(
                          color: _getEventColor(event).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time & Color indicator
                          Column(
                            children: [
                              Container(
                                width: 4,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _getEventColor(event),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEventColor(event).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('HH:mm').format(event.startTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getEventColor(event),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 16),

                          // Event content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Time duration
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                // Location if available
                                if (event.location?.isNotEmpty == true) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          event.location!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Participants count if available
                                if (event.participantIds.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.group,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${event.participantIds.length} người tham gia',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
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
                              color: _getEventColor(event),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              event.priority
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
