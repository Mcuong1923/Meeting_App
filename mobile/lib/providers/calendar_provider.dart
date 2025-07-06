import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metting_app/models/calendar_model.dart';
import 'package:metting_app/models/meeting_model.dart';
import 'package:metting_app/models/user_model.dart';
import 'package:metting_app/models/room_model.dart';

class CalendarProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CalendarEvent> _events = [];
  CalendarViewConfig _viewConfig = CalendarViewConfig(
    focusedDay: DateTime.now(),
    firstDay: DateTime.now().subtract(const Duration(days: 365)),
    lastDay: DateTime.now().add(const Duration(days: 365)),
  );

  bool _isLoading = false;
  String _error = '';
  DateTime _selectedDate = DateTime.now();
  List<ScheduleConflict> _conflicts = [];

  // Getters
  List<CalendarEvent> get events => _events;
  CalendarViewConfig get viewConfig => _viewConfig;
  bool get isLoading => _isLoading;
  String get error => _error;
  DateTime get selectedDate => _selectedDate;
  List<ScheduleConflict> get conflicts => _conflicts;

  /// Load events cho user trong khoảng thời gian
  Future<void> loadEvents(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      _setLoading(true);
      _setError('');

      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now().add(const Duration(days: 60));

      // Clear existing events để tránh duplicate
      _events.clear();
      _conflicts.clear();

      // Load meetings
      await _loadMeetingEvents(userId, startDate, endDate);

      // Load other calendar events
      await _loadCalendarEvents(userId, startDate, endDate);

      // Detect conflicts
      _detectConflicts();

      notifyListeners();
      print('✅ Loaded ${_events.length} calendar events');
    } catch (e) {
      print('❌ Error loading events: $e');
      _setError('Lỗi tải sự kiện: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load meeting events
  Future<void> _loadMeetingEvents(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      print('🔄 Loading meeting events for user: $userId');
      print('🔄 Date range: $startDate to $endDate');

      // Load all meetings trong time range
      QuerySnapshot snapshot = await _firestore
          .collection('meetings')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      print('🔄 Found ${snapshot.docs.length} meetings in time range');

      List<CalendarEvent> meetingEvents = [];

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        MeetingModel meeting =
            MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

        // Kiểm tra nếu user là creator hoặc participant
        bool isCreator = meeting.creatorId == userId;
        bool isParticipant =
            meeting.participants.any((p) => p.userId == userId);

        if (isCreator || isParticipant) {
          CalendarEvent event = CalendarEvent.fromMeeting(meeting);
          meetingEvents.add(event);
          print('✅ Added meeting to calendar: ${meeting.title}');
        }
      }

      _events.addAll(meetingEvents);
      print('✅ Loaded ${meetingEvents.length} meeting events for calendar');
    } catch (e) {
      print('❌ Error loading meeting events: $e');
    }
  }

  /// Load other calendar events
  Future<void> _loadCalendarEvents(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('calendar_events')
          .where('creatorId', isEqualTo: userId)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      List<CalendarEvent> calendarEvents = snapshot.docs
          .map((doc) =>
              CalendarEvent.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      _events.addAll(calendarEvents);
    } catch (e) {
      print('❌ Error loading calendar events: $e');
    }
  }

  /// Tạo calendar event mới
  Future<String?> createEvent(CalendarEvent event) async {
    try {
      _setLoading(true);
      _setError('');

      DocumentReference docRef =
          await _firestore.collection('calendar_events').add(event.toMap());

      CalendarEvent newEvent = event.copyWith(id: docRef.id);
      _events.add(newEvent);
      _detectConflicts();
      notifyListeners();

      print('✅ Created calendar event: ${event.title}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating event: $e');
      _setError('Lỗi tạo sự kiện: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Cập nhật calendar event
  Future<void> updateEvent(CalendarEvent event) async {
    try {
      _setLoading(true);
      _setError('');

      await _firestore
          .collection('calendar_events')
          .doc(event.id)
          .update(event.toMap());

      int index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        _detectConflicts();
        notifyListeners();
      }

      print('✅ Updated calendar event: ${event.title}');
    } catch (e) {
      print('❌ Error updating event: $e');
      _setError('Lỗi cập nhật sự kiện: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Xóa calendar event
  Future<void> deleteEvent(String eventId) async {
    try {
      _setLoading(true);
      _setError('');

      await _firestore.collection('calendar_events').doc(eventId).delete();

      _events.removeWhere((e) => e.id == eventId);
      _detectConflicts();
      notifyListeners();

      print('✅ Deleted calendar event: $eventId');
    } catch (e) {
      print('❌ Error deleting event: $e');
      _setError('Lỗi xóa sự kiện: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get events cho một ngày cụ thể
  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return isSameDay(event.startTime, day) ||
          (event.isAllDay && isSameDay(event.startTime, day)) ||
          (event.startTime.isBefore(day) && event.endTime.isAfter(day));
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get events cho một tuần
  List<CalendarEvent> getEventsForWeek(DateTime startOfWeek) {
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _events.where((event) {
      return event.startTime.isBefore(endOfWeek) &&
          event.endTime.isAfter(startOfWeek);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get events theo loại
  List<CalendarEvent> getEventsByType(CalendarEventType type) {
    return _events.where((event) => event.type == type).toList();
  }

  /// Kiểm tra availability cho time slot
  bool isTimeSlotAvailable(DateTime startTime, DateTime endTime,
      {String? excludeEventId}) {
    for (CalendarEvent event in _events) {
      if (excludeEventId != null && event.id == excludeEventId) continue;

      if (event.startTime.isBefore(endTime) &&
          event.endTime.isAfter(startTime)) {
        return false;
      }
    }
    return true;
  }

  /// Tìm time slots available
  List<TimeSlot> findAvailableTimeSlots(
    DateTime date,
    Duration duration, {
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? excludeEventId,
  }) {
    startTime ??= const TimeOfDay(hour: 8, minute: 0);
    endTime ??= const TimeOfDay(hour: 18, minute: 0);

    List<TimeSlot> availableSlots = [];
    DateTime currentTime = DateTime(
        date.year, date.month, date.day, startTime.hour, startTime.minute);

    DateTime dayEnd =
        DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

    while (currentTime.add(duration).isBefore(dayEnd) ||
        currentTime.add(duration).isAtSameMomentAs(dayEnd)) {
      DateTime slotEnd = currentTime.add(duration);

      if (isTimeSlotAvailable(currentTime, slotEnd,
          excludeEventId: excludeEventId)) {
        availableSlots.add(TimeSlot(
          startTime: currentTime,
          endTime: slotEnd,
          isAvailable: true,
        ));
      }

      currentTime =
          currentTime.add(const Duration(minutes: 30)); // 30-minute intervals
    }

    return availableSlots;
  }

  /// Detect scheduling conflicts
  void _detectConflicts() {
    _conflicts.clear();

    for (int i = 0; i < _events.length; i++) {
      for (int j = i + 1; j < _events.length; j++) {
        CalendarEvent event1 = _events[i];
        CalendarEvent event2 = _events[j];

        if (_eventsConflict(event1, event2)) {
          ConflictSeverity severity = _getConflictSeverity(event1, event2);
          _conflicts.add(ScheduleConflict(
            event1: event1,
            event2: event2,
            description: _getConflictDescription(event1, event2),
            severity: severity,
          ));
        }
      }
    }
  }

  /// Check if two events conflict
  bool _eventsConflict(CalendarEvent event1, CalendarEvent event2) {
    return event1.startTime.isBefore(event2.endTime) &&
        event1.endTime.isAfter(event2.startTime);
  }

  /// Get conflict severity
  ConflictSeverity _getConflictSeverity(
      CalendarEvent event1, CalendarEvent event2) {
    // Same location conflict
    if (event1.location == event2.location && event1.location != null) {
      return ConflictSeverity.critical;
    }

    // High priority events
    if (event1.isUrgent || event2.isUrgent) {
      return ConflictSeverity.high;
    }

    // Meeting conflicts
    if (event1.type == CalendarEventType.meeting &&
        event2.type == CalendarEventType.meeting) {
      return ConflictSeverity.medium;
    }

    return ConflictSeverity.low;
  }

  /// Get conflict description
  String _getConflictDescription(CalendarEvent event1, CalendarEvent event2) {
    if (event1.location == event2.location && event1.location != null) {
      return 'Trùng địa điểm: ${event1.location}';
    }

    if (event1.type == CalendarEventType.meeting &&
        event2.type == CalendarEventType.meeting) {
      return 'Trùng lịch họp';
    }

    return 'Trùng thời gian';
  }

  /// Suggest optimal meeting time
  List<TimeSlot> suggestMeetingTimes(
    DateTime date,
    Duration duration,
    List<String> participantIds, {
    TimeOfDay? preferredStartTime,
    TimeOfDay? preferredEndTime,
  }) {
    // TODO: Implement smart scheduling based on participants' availability
    return findAvailableTimeSlots(
      date,
      duration,
      startTime: preferredStartTime,
      endTime: preferredEndTime,
    );
  }

  /// Update calendar view config
  void updateViewConfig(CalendarViewConfig newConfig) {
    _viewConfig = newConfig;
    notifyListeners();
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Helper method to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get events count for a day (for calendar markers)
  int getEventCountForDay(DateTime day) {
    return getEventsForDay(day).length;
  }

  /// Check if day has important events
  bool hasImportantEvents(DateTime day) {
    return getEventsForDay(day).any((event) =>
        event.priority == CalendarEventPriority.high ||
        event.priority == CalendarEventPriority.urgent);
  }

  /// Get next upcoming event
  CalendarEvent? getNextUpcomingEvent() {
    final now = DateTime.now();
    final upcomingEvents = _events
        .where((event) => event.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return upcomingEvents.isNotEmpty ? upcomingEvents.first : null;
  }

  /// Get today's events
  List<CalendarEvent> getTodaysEvents() {
    return getEventsForDay(DateTime.now());
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    if (error.isNotEmpty) {
      print('❌ CalendarProvider Error: $error');
    }
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  /// Clear events
  void clearEvents() {
    _events.clear();
    _conflicts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
