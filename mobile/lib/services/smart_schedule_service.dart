import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'gemini_service.dart';

/// Service điều phối phân tích lịch bận và gợi ý khung giờ họp thông minh.
class SmartScheduleService {
  final FirebaseFirestore _firestore;

  SmartScheduleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─────────────────────── PUBLIC API ───────────────────────

  /// Phân tích lịch bận của danh sách người tham dự trong [targetDate],
  /// sau đó gọi Gemini để gợi ý 3 khung giờ tối ưu.
  ///
  /// [participantIds]  Danh sách userId của người tham dự
  /// [participantNames] Map userId → tên hiển thị (để hiển thị trong prompt)
  /// [targetDate]      Ngày cần tìm giờ họp
  /// [durationMinutes] Thời lượng cuộc họp
  ///
  /// Throws Exception nếu có lỗi Firestore hoặc Gemini.
  Future<List<SuggestedTimeSlot>> suggestTimeSlots({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required DateTime targetDate,
    required int durationMinutes,
  }) async {
    // 1. Lấy các meeting bận của participants trong ngày targetDate
    final busySlots = await _getBusySlots(
      participantIds: participantIds,
      participantNames: participantNames,
      targetDate: targetDate,
    );

    // 2. Gọi Gemini với busy slots đã lấy
    final dateStr = DateFormat('dd/MM/yyyy').format(targetDate);
    return GeminiService.suggestMeetingTimeSlots(
      busySlots: busySlots,
      targetDate: dateStr,
      durationMinutes: durationMinutes,
    );
  }

  // ─────────────────────── PRIVATE ───────────────────────

  /// Query Firestore để lấy các khung giờ bận của participants trong targetDate.
  /// Chỉ tính các meeting có status approved hoặc pending (không tính cancelled/rejected).
  Future<List<Map<String, String>>> _getBusySlots({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required DateTime targetDate,
  }) async {
    if (participantIds.isEmpty) return [];

    final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
    final dayEnd   = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    final List<Map<String, String>> busySlots = [];

    // Firestore whereIn giới hạn 10 items, nên batch nếu cần
    final batches = _chunk(participantIds, 10);

    for (final batch in batches) {
      try {
        // Query meetings mà participantIds chứa bất kỳ người nào trong batch
        final snapshot = await _firestore
            .collection('meetings')
            .where('participantIds', arrayContainsAny: batch)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          // Bỏ qua các trạng thái không block
          final status = (data['status'] ?? '').toString().toLowerCase();
          if (['cancelled', 'rejected', 'expired'].contains(status)) continue;

          // Kiểm tra ngày
          final startTs = data['startTime'];
          final endTs   = data['endTime'];
          if (startTs == null || endTs == null) continue;

          final start = (startTs as Timestamp).toDate();
          final end   = (endTs as Timestamp).toDate();

          // Chỉ lấy meetings trong ngày targetDate
          if (start.isAfter(dayEnd) || end.isBefore(dayStart)) continue;

          // Tìm người tham dự nào bị ảnh hưởng
          final participants = (data['participants'] as List<dynamic>?) ?? [];
          for (final p in participants) {
            final uid  = p['userId']?.toString() ?? '';
            final name = participantNames[uid] ?? p['userName']?.toString() ?? 'Người tham dự';

            if (batch.contains(uid)) {
              busySlots.add({
                'from': _formatHHMM(start),
                'to':   _formatHHMM(end),
                'who':  name,
              });
              break; // Chỉ cần add 1 lần cho mỗi meeting
            }
          }
        }
      } catch (e) {
        // Nếu lỗi 1 batch, bỏ qua và tiếp tục
        debugPrint('[SmartSchedule] Lỗi query batch: $e');
      }
    }

    // Sắp xếp theo giờ bắt đầu
    busySlots.sort((a, b) => (a['from'] ?? '').compareTo(b['from'] ?? ''));

    return busySlots;
  }

  static String _formatHHMM(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return chunks;
  }
}
