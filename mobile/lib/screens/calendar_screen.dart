import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../providers/auth_provider.dart';
import '../models/calendar_model.dart';
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
  bool _fabPressed = false;

  // ===== Visual tokens (Light mode, premium productivity style) =====
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF667085);
  static const Color _muted = Color(0xFF98A2B3);
  static const Color _brandBlue = Color(0xFF1677FF);
  static const Color _brandBlue2 = Color(0xFF2F80FF);
  static const double _rCard = 24;
  static const double _rPill = 20;

  List<BoxShadow> _softShadow({double opacity = 0.06, double blur = 24}) => [
        BoxShadow(
          color: Colors.black.withOpacity(opacity),
          blurRadius: blur,
          offset: const Offset(0, 10),
        ),
      ];

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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        Container(
          color: _bg,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(_rCard),
                  boxShadow: _softShadow(opacity: 0.05, blur: 28),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _brandBlue,
                    borderRadius: BorderRadius.circular(_rPill),
                    boxShadow: _softShadow(opacity: 0.10, blur: 22),
                  ),
                  indicatorPadding: const EdgeInsets.all(6),
                  tabAlignment: TabAlignment.fill,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: _textSecondary,
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
              Expanded(
                child: Consumer<CalendarProvider>(
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
              ),
            ],
          ),
        ),

        // Floating action button overlay, not affecting layout height
        Positioned(
          right: 20,
          bottom: 20 + bottomInset,
          child: _GradientFab(
            pressed: _fabPressed,
            colors: const [_brandBlue2, _brandBlue],
            onTapDown: (_) => setState(() => _fabPressed = true),
            onTapCancel: () => setState(() => _fabPressed = false),
            onTapUp: (_) => setState(() => _fabPressed = false),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MeetingCreateScreen()),
              ).then((_) => _loadCalendarData());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView(CalendarProvider calendarProvider) {
    return Column(
      children: [
        _buildMonthHeader(),
        Expanded(child: _buildMonthScroll(calendarProvider)),
      ],
    );
  }

  Widget _buildMonthScroll(CalendarProvider calendarProvider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: Column(
        children: [
          _buildMonthCalendar(calendarProvider),
          const SizedBox(height: 18),
          _buildSelectedDaySection(calendarProvider),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    // Responsive scale
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    final hPadding = (16 * scale).clamp(12.0, 24.0);
    final vPadding = (12 * scale).clamp(10.0, 18.0);
    final titleFontSize = (20 * scale).clamp(16.0, 24.0);
    final iconSize = (24 * scale).clamp(20.0, 28.0);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_rCard),
        boxShadow: _softShadow(opacity: 0.05, blur: 24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_left,
                  color: const Color(0xFF344054), size: iconSize),
              constraints: BoxConstraints(minWidth: 40 * scale, minHeight: 40 * scale),
              padding: EdgeInsets.all(6 * scale),
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
          Flexible(
            child: Text(
              DateFormat('MMMM yyyy', 'vi_VN').format(_focusedDate),
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_right,
                  color: const Color(0xFF344054), size: iconSize),
              constraints: BoxConstraints(minWidth: 40 * scale, minHeight: 40 * scale),
              padding: EdgeInsets.all(6 * scale),
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
        const SizedBox(height: 10),
        _buildMonthGrid(calendarProvider),
      ],
    );
  }

  Widget _buildWeekDayHeaders() {
    const weekDays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    
    // Responsive scale
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    final margin = (16 * scale).clamp(12.0, 20.0);
    final fontSize = (13 * scale).clamp(11.0, 15.0);
    final height = (40 * scale).clamp(36.0, 50.0);
    
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Row(
        children: weekDays.map((day) {
          return Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  color: _textSecondary,
                  letterSpacing: 0.3,
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
    final startDate =
        firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));

    // Responsive scale
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    final spacing = (10 * scale).clamp(8.0, 14.0);
    
    // Responsive sizes for day cells
    final dayFontSize = (14 * scale).clamp(12.0, 16.0);
    final dotSize = (4 * scale).clamp(3.0, 6.0);
    final daySize = (44 * scale).clamp(38.0, 52.0);
    
    // Calculate cell height precisely:
    // daySize (circle) + spacing (4*scale) + max(dotSize or badge height ~16*scale) + extra buffer
    // Badge với text có thể cao hơn dotSize, nên dùng max để đảm bảo
    final badgeHeight = (18 * scale).clamp(16.0, 22.0); // Height của badge khi có >3 events (bao gồm padding)
    final maxBottomHeight = badgeHeight > dotSize ? badgeHeight : dotSize;
    // Thêm buffer lớn hơn để đảm bảo không overflow (8*scale thay vì 6*scale)
    final cellHeight = daySize + (4 * scale) + maxBottomHeight + (8 * scale);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 2 * scale, bottom: 2 * scale),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisExtent: cellHeight,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
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
              height: cellHeight,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: daySize,
                    height: daySize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? _brandBlue
                          : isToday
                              ? _brandBlue.withOpacity(0.10)
                              : Colors.transparent,
                      border: isToday && !isSelected
                          ? Border.all(color: _brandBlue, width: 1.5)
                          : null,
                      boxShadow: isSelected
                          ? _softShadow(opacity: 0.14, blur: 22)
                          : const [],
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: dayFontSize,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isCurrentMonth
                                  ? (isToday ? _brandBlue : _textPrimary)
                                  : _textSecondary.withOpacity(0.45),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  if (events.isNotEmpty)
                    (events.length <= 3)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: events.take(3).map((event) {
                              return Container(
                                width: dotSize,
                                height: dotSize,
                                margin: EdgeInsets.symmetric(
                                    horizontal: 1.0 * scale),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.9)
                                      : _getEventColor(event),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6 * scale, vertical: 2 * scale),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.22)
                                  : _getPrimaryEventColor(events),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${events.length}',
                              style: TextStyle(
                                fontSize: (9 * scale).clamp(8.0, 11.0),
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.95),
                                height: 1.1,
                              ),
                            ),
                          )
                  else
                    SizedBox(height: dotSize),
                ],
              ),
            ),
          );
        },
    );
  }

  Widget _buildSelectedDaySection(CalendarProvider calendarProvider) {
    final events = calendarProvider.getEventsForDay(_selectedDate);
    events.sort((a, b) => a.startTime.compareTo(b.startTime));

    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final dayLabel = isToday
        ? 'HÔM NAY'
        : DateFormat('EEEE', 'vi_VN').format(_selectedDate).toUpperCase();
    final label = '$dayLabel - ${_selectedDate.day} THÁNG ${_selectedDate.month}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: _textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFEAEFF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(_rCard),
              boxShadow: _softShadow(opacity: 0.04, blur: 18),
            ),
            child: const Text(
              'Chưa có cuộc họp nào trong ngày này.',
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Column(
            children: [
              for (final e in events) ...[
                _buildCompactEventCard(e),
                const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildCompactEventCard(CalendarEvent event) {
    final color = _getEventColor(event);
    final start = DateFormat('HH:mm').format(event.startTime);
    final end = DateFormat('HH:mm').format(event.endTime);

    return InkWell(
      onTap: () => _showEventDetails(event),
      borderRadius: BorderRadius.circular(_rCard),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(_rCard),
          boxShadow: _softShadow(opacity: 0.05, blur: 22),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_rCard),
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(_rCard),
                    bottomLeft: Radius.circular(_rCard),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              start,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              end,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _textSecondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 16,
                                    color: _textSecondary.withOpacity(0.75)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    (event.location?.isNotEmpty == true)
                                        ? event.location!
                                        : 'Chưa có địa điểm',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF667085)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _startOfWeek(DateTime d) =>
      d.subtract(Duration(days: d.weekday % 7));

  Widget _buildWeekView(CalendarProvider calendarProvider) {
    return Column(
      children: [
        _buildWeekHeaderPremium(),
        _buildWeekPills(calendarProvider),
        Expanded(
          child: _buildTimelineForDay(
            calendarProvider.getEventsForDay(_selectedDate),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekHeaderPremium() {
    final title = 'Tháng ${_selectedDate.month}, ${_selectedDate.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
          ),
          _navPill(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                _focusedDate = _selectedDate;
              });
              _loadCalendarData();
            },
          ),
          const SizedBox(width: 10),
          _navPill(
            icon: Icons.chevron_right_rounded,
            onTap: () {
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

  Widget _navPill({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _softShadow(opacity: 0.04, blur: 18),
        ),
        child: Icon(icon, color: const Color(0xFF344054)),
      ),
    );
  }

  Widget _buildWeekPills(CalendarProvider calendarProvider) {
    final start = _startOfWeek(_selectedDate);
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          for (final d in days) ...[
            Expanded(child: _weekPill(d, calendarProvider)),
            if (d != days.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _weekPill(DateTime date, CalendarProvider calendarProvider) {
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final events = calendarProvider.getEventsForDay(date);
    final hasEvents = events.isNotEmpty;
    final dow = DateFormat('E', 'vi_VN').format(date).toUpperCase();

    return InkWell(
      onTap: () => setState(() => _selectedDate = date),
      borderRadius: BorderRadius.circular(_rCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _brandBlue : _card,
          borderRadius: BorderRadius.circular(_rCard),
          boxShadow: isSelected
              ? _softShadow(opacity: 0.14, blur: 24)
              : _softShadow(opacity: 0.03, blur: 12),
          border: (!isSelected && isToday)
              ? Border.all(color: _brandBlue.withOpacity(0.35), width: 1.2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dow,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : _textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (hasEvents)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : _getPrimaryEventColor(events),
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineForDay(
    List<CalendarEvent> rawEvents, {
    bool richCards = false,
  }) {
    final events = [...rawEvents]..sort((a, b) => a.startTime.compareTo(b.startTime));
    const int startHour = 7;
    const int endHour = 20;
    const double hourHeight = 74;
    const double timeColWidth = 58;

    const totalHeight = (endHour - startHour) * hourHeight;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // Hour grid
            Positioned.fill(
              child: Column(
                children: List.generate(endHour - startHour, (i) {
                  final hour = startHour + i;
                  final label = '${hour.toString().padLeft(2, '0')}:00';
                  return SizedBox(
                    height: hourHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: timeColWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _muted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Color(0xFFEAEFF6),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // Vertical guide line
            Positioned(
              left: timeColWidth + 12,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: const Color(0xFFEAEFF6)),
            ),

            // Events
            for (final e in events)
              _positionedEventBlock(
                event: e,
                startHour: startHour,
                hourHeight: hourHeight,
                left: timeColWidth + 20,
                rich: richCards,
              ),
          ],
        ),
      ),
    );
  }

  Widget _positionedEventBlock({
    required CalendarEvent event,
    required int startHour,
    required double hourHeight,
    required double left,
    required bool rich,
  }) {
    final startMin = (event.startTime.hour * 60 + event.startTime.minute) - (startHour * 60);
    final endMin = (event.endTime.hour * 60 + event.endTime.minute) - (startHour * 60);
    final clampedStart = startMin.clamp(0, 24 * 60);
    final clampedEnd = endMin.clamp(0, 24 * 60);
    final top = (clampedStart / 60.0) * hourHeight;
    final height = ((clampedEnd - clampedStart) / 60.0) * hourHeight;
    // Rich cards (Day view) có thêm participant bar + event pill → cần 145px
    // Normal cards (Week view) cần 88px
    final double minH = rich ? 145.0 : 88.0;
    final blockH = height < minH ? minH : height;

    final color = _getEventColor(event);
    final bg = Color.alphaBlend(color.withOpacity(0.14), Colors.white);

    return Positioned(
      left: left,
      right: 0,
      top: top,
      height: blockH,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(_rCard),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(_rCard),
            boxShadow: _softShadow(opacity: 0.06, blur: 22),
          ),
          clipBehavior: Clip.hardEdge,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_rCard),
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(_rCard),
                      bottomLeft: Radius.circular(_rCard),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                maxLines: rich ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (rich) ...[
                              const SizedBox(width: 10),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.more_horiz_rounded,
                                    size: 20, color: Color(0xFF475467)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: rich ? _brandBlue : _textSecondary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (event.location?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16,
                                  color: _textSecondary.withOpacity(0.8)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  event.location!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (rich) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _participantStack(event.participantIds.length),
                              const Spacer(),
                              _eventPill(event),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _participantStack(int count) {
    if (count <= 0) return const SizedBox();

    final shown = count >= 2 ? 2 : 1;
    final extra = count - shown;

    return SizedBox(
      height: 26,
      child: Row(
        children: [
          for (int i = 0; i < shown; i++)
            Align(
              widthFactor: 0.72,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0EA5E9).withOpacity(0.18),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 14, color: Color(0xFF0F172A)),
              ),
            ),
          if (extra > 0)
            Align(
              widthFactor: 0.72,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.70),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _eventPill(CalendarEvent e) {
    final String label;
    final Color color = _getEventColor(e);

    if (e.isAllDay) {
      label = 'ALL';
    } else if (e.priority == CalendarEventPriority.urgent ||
        e.priority == CalendarEventPriority.high) {
      label = 'Quan trọng';
    } else if (e.type == CalendarEventType.meeting) {
      label = 'Bắt buộc';
    } else {
      label = e.typeDisplayName;
    }

    final bg = Color.alphaBlend(color.withOpacity(0.14), Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDayView(CalendarProvider calendarProvider) {
    final events = calendarProvider.getEventsForDay(_selectedDate);
    return Column(
      children: [
        _buildDayHeaderPremium(),
        Expanded(
          child: events.isEmpty
              ? _buildEmptyDayState()
              : _buildTimelineForDay(events, richCards: false),
        ),
      ],
    );
  }

  Widget _buildDayHeaderPremium() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final title = DateFormat("EEEE, d 'Tháng' M", 'vi_VN').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          _navPill(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                _focusedDate = _selectedDate;
              });
              _loadCalendarData();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (isToday)
                  const Text(
                    'HÔM NAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: _textSecondary,
                    ),
                  )
                else
                  const SizedBox(height: 13),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _navPill(
            icon: Icons.chevron_right_rounded,
            onTap: () {
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

  Widget _buildEmptyDayState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(_rCard),
          boxShadow: _softShadow(opacity: 0.05, blur: 22),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded,
                size: 42, color: Color(0xFF98A2B3)),
            SizedBox(height: 12),
            Text(
              'Không có cuộc họp nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Bạn đang rảnh trong hôm nay.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ],
        ),
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

    // Màu theo loại sự kiện (ưu tiên style nhất quán như mock)
    switch (event.type) {
      case CalendarEventType.meeting:
        return const Color(0xFF1677FF);
      case CalendarEventType.personal:
        return const Color(0xFFF97316);
      case CalendarEventType.reminder:
        return const Color(0xFF06B6D4);
      case CalendarEventType.deadline:
        return const Color(0xFFEF4444);
      case CalendarEventType.maintenance:
        return const Color(0xFFF59E0B);
      case CalendarEventType.holiday:
        return const Color(0xFF22C55E);
      case CalendarEventType.other:
        break;
    }

    // Fallback theo priority
    switch (event.priority) {
      case CalendarEventPriority.urgent:
        return const Color(0xFFEF4444);
      case CalendarEventPriority.high:
        return const Color(0xFFF97316);
      case CalendarEventPriority.medium:
        return const Color(0xFF1677FF);
      case CalendarEventPriority.low:
        return const Color(0xFF64748B);
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

  Widget _buildDetailRow({
    required Widget icon,
    required String label,
    String? value,
    bool isOrganizer = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: icon,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOrganizer) ...[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ] else ...[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showEventDetails(CalendarEvent event) {
    String statusText = '';
    Color statusColor = const Color(0xFF22C55E);
    IconData statusIcon = Icons.check;

    if (event.type == CalendarEventType.meeting && event.metadata != null) {
      String status = event.metadata!['meetingStatus'] ?? '';
      switch (status) {
        case 'pending':
          statusText = 'Chờ duyệt';
          statusColor = const Color(0xFFF59E0B);
          statusIcon = Icons.schedule;
          break;
        case 'approved':
          statusText = 'Đã duyệt';
          statusColor = const Color(0xFF22C55E);
          statusIcon = Icons.check;
          break;
        case 'rejected':
          statusText = 'Từ chối';
          statusColor = const Color(0xFFEF4444);
          statusIcon = Icons.close;
          break;
        case 'cancelled':
          statusText = 'Đã hủy';
          statusColor = const Color(0xFF64748B);
          statusIcon = Icons.cancel_outlined;
          break;
        case 'completed':
          statusText = 'Hoàn thành';
          statusColor = const Color(0xFF22C55E);
          statusIcon = Icons.check_circle;
          break;
      }
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Text(
                  'Meeting Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status
                    if (statusText.isNotEmpty) ...[
                      _buildDetailRow(
                        icon: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                        ),
                        label: statusText,
                        value: null,
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Date & Time
                    _buildDetailRow(
                      icon: const Icon(Icons.access_time_rounded,
                          size: 20, color: _textSecondary),
                      label: DateFormat('dd/MM/yyyy').format(event.startTime),
                      value: '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                    ),
                    const SizedBox(height: 20),
                    
                    // Location
                    if (event.location?.isNotEmpty == true) ...[
                      _buildDetailRow(
                        icon: const Icon(Icons.location_on_rounded,
                            size: 20, color: _textSecondary),
                        label: event.location!,
                        value: null,
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Organizer
                    _buildDetailRow(
                      icon: const Icon(Icons.person_outline_rounded,
                          size: 20, color: _textSecondary),
                      label: 'NGƯỜI TẠO',
                      value: event.creatorName,
                      isOrganizer: true,
                    ),
                    const SizedBox(height: 20),
                    
                    // Participants
                    if (event.participantIds.isNotEmpty) ...[
                      _buildDetailRow(
                        icon: const Icon(Icons.people_outline_rounded,
                            size: 20, color: _textSecondary),
                        label: '${event.participantIds.length} người tham gia',
                        value: null,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                    if (event.type == CalendarEventType.meeting &&
                        event.meetingId != null) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Navigate to meeting detail screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Xem chi tiết cuộc họp')),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Chi tiết',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _brandBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Legacy header button was used when CalendarScreen had its own AppBar.
// Kept here commented for potential future standalone use.

class _GradientFab extends StatelessWidget {
  final bool pressed;
  final List<Color> colors;
  final GestureTapDownCallback? onTapDown;
  final GestureTapCancelCallback? onTapCancel;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback onTap;

  const _GradientFab({
    required this.pressed,
    required this.colors,
    required this.onTap,
    this.onTapDown,
    this.onTapCancel,
    this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    final scale = pressed ? 0.96 : 1.0;

    return GestureDetector(
      onTap: onTap,
      onTapDown: onTapDown,
      onTapCancel: onTapCancel,
      onTapUp: onTapUp,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: scale,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1677FF).withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

