import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config.dart';

class GeminiService {
  static const String _apiKey = AppConfig.geminiApiKey;

  // gemini-3.1-flash-lite-preview: 500 RPD miễn phí (tên API thực tế xác nhận từ ListModels)
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // ─── Retry helper: tự động retry khi gặp 429 (rate limit) ───
  // Free Tier giới hạn RPM → cần chờ đủ lâu giữa các retry
  // Backoff: 5s → 10s → 20s (tổng ~35s chờ trước khi báo lỗi)
  static Future<http.Response> _postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    int delaySeconds = 5;
    while (true) {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 429 || attempt >= maxRetries) {
        return response;
      }

      // 429 — chờ và retry
      attempt++;
      await Future.delayed(Duration(seconds: delaySeconds));
      delaySeconds *= 2; // 5s → 10s → 20s
    }
  }

  // ─────────────────────── TÓM TẮT BIÊN BẢN ───────────────────────

  /// Tóm tắt nội dung biên bản họp
  static Future<String> summarizeMinutes({
    required String title,
    required String content,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Chưa cấu hình API key. Mở services/gemini_service.dart và điền key vào _apiKey.');
    }

    final prompt = '''
Bạn là trợ lý thư ký cuộc họp chuyên nghiệp. Hãy tóm tắt biên bản cuộc họp sau theo cấu trúc rõ ràng bằng tiếng Việt.

Biên bản:
Tiêu đề: $title
Nội dung: $content

Yêu cầu trả về:
1. **Tóm tắt nội dung chính** (2-3 câu)
2. **Các quyết định quan trọng** (danh sách gạch đầu dòng)
3. **Nhiệm vụ cần thực hiện** (nếu có)
4. **Kết luận** (1 câu)

Trả lời ngắn gọn, súc tích, không quá 300 từ.
''';

    final response = await _postWithRetry(
          Uri.parse('$_endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.3,
              'maxOutputTokens': 2048,
              'thinkingConfig': {
                'thinkingBudget': 0,
              },
            },
          }),
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null || text.isEmpty) {
        throw Exception('Gemini trả về kết quả trống.');
      }
      return text;
    } else if (response.statusCode == 400) {
      throw Exception('API key không hợp lệ hoặc request sai định dạng.');
    } else if (response.statusCode == 429) {
      throw Exception('Vượt quá giới hạn request. Vui lòng thử lại sau.');
    } else {
      final err = jsonDecode(response.body);
      throw Exception(
          'Lỗi Gemini ${response.statusCode}: ${err['error']?['message'] ?? 'Unknown'}');
    }
  }

  // ─────────────────────── GỢI Ý AGENDA ───────────────────────

  /// Gợi ý agenda cuộc họp dựa trên tiêu đề, loại và thời lượng
  static Future<String> suggestAgenda({
    required String meetingTitle,
    required String meetingType,
    required int durationMinutes,
    required int participantsCount,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Chưa cấu hình API key.');
    }

    final prompt = '''
Gợi ý agenda cuộc họp bằng tiếng Việt cho:
- Tên: $meetingTitle
- Loại: $meetingType  
- Thời lượng: $durationMinutes phút
- Số người tham dự: $participantsCount người

Trả về danh sách các mục thảo luận với thời gian dự kiến, ngắn gọn dưới 200 từ.
''';

    final response = await _postWithRetry(
          Uri.parse('$_endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.5,
              'maxOutputTokens': 2048,
              'thinkingConfig': {
                'thinkingBudget': 0,
              },
            },
          }),
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text']
              as String? ??
          '';
    } else {
      throw Exception('Lỗi gọi Gemini API: ${response.statusCode}');
    }
  }

  // ─────────────────────── GỢI Ý KHUNG GIỜ HỌP ───────────────────────

  /// Gợi ý khung giờ họp thông minh dựa trên lịch bận của người tham dự.
  ///
  /// [busySlots] Danh sách khung giờ bận:
  ///   {'from': '09:00', 'to': '10:00', 'who': 'Nguyễn Văn A'}
  /// [targetDate]      Ngày họp (dd/MM/yyyy)
  /// [durationMinutes] Thời lượng cuộc họp cần tìm (phút)
  /// [workStart]       Giờ bắt đầu làm việc (default '08:00')
  /// [workEnd]         Giờ kết thúc làm việc (default '18:00')
  ///
  /// Trả về danh sách tối đa 3 [SuggestedTimeSlot].
  static Future<List<SuggestedTimeSlot>> suggestMeetingTimeSlots({
    required List<Map<String, String>> busySlots,
    required String targetDate,
    required int durationMinutes,
    String workStart = '08:00',
    String workEnd = '18:00',
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Chưa cấu hình API key.');
    }

    final busyDescription = busySlots.isEmpty
        ? 'Tất cả mọi người đều rảnh cả ngày.'
        : busySlots
            .map((s) =>
                '- ${s['who'] ?? 'Người tham gia'}: ${s['from']} – ${s['to']}')
            .join('\n');

    final prompt = '''
Bạn là trợ lý lên lịch họp thông minh. Hãy gợi ý 3 khung giờ họp tối ưu bằng tiếng Việt.

**Thông tin:**
- Ngày họp: $targetDate
- Thời lượng cần: $durationMinutes phút
- Giờ làm việc: $workStart – $workEnd
- Các khung giờ bận của người tham dự:
$busyDescription

**Yêu cầu quan trọng:**
Trả về ĐÚNG định dạng JSON sau, không thêm bất kỳ text nào ngoài JSON:
[
  {"start": "HH:MM", "end": "HH:MM", "reason": "Lý do ngắn gọn"},
  {"start": "HH:MM", "end": "HH:MM", "reason": "Lý do ngắn gọn"},
  {"start": "HH:MM", "end": "HH:MM", "reason": "Lý do ngắn gọn"}
]

Quy tắc:
- KHÔNG gợi ý khung giờ trùng hoặc chồng lấp với lịch bận
- Ưu tiên buổi sáng (8h-12h) hoặc đầu giờ chiều (13h-15h)
- end = start + $durationMinutes phút
- Format HH:MM phải hợp lệ (VD: 09:00, 14:30)
''';

    final response = await _postWithRetry(
          Uri.parse('$_endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.2,
              'maxOutputTokens': 2048,
              // Tắt thinking để toàn bộ token dành cho output JSON
              'thinkingConfig': {
                'thinkingBudget': 0,
              },
            },
          }),
        );

    if (response.statusCode != 200) {
      throw Exception('Lỗi Gemini API: ${response.statusCode}');
    }

    final rawText = _extractText(response.body);

    if (rawText.isEmpty) {
      throw Exception('Gemini không trả về kết quả.');
    }

    debugPrint('[GeminiService] Raw response: $rawText');

    return _parseTimeSlots(rawText);
  }

  /// Trích xuất text từ response body của Gemini.
  /// Xử lý multi-part responses (thinking models trả nhiều parts).
  static String _extractText(String responseBody) {
    final data = jsonDecode(responseBody);
    final parts = data['candidates']?[0]?['content']?['parts'] as List<dynamic>?;
    if (parts == null) return '';

    // Duyệt ALL parts, lấy text part cuối cùng (bỏ qua thinking parts)
    String result = '';
    for (final part in parts) {
      final text = part['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        result = text;
      }
    }
    return result;
  }

  /// Parse danh sách [SuggestedTimeSlot] từ JSON text trả về bởi Gemini.
  /// Xử lý nhiều format: markdown code-block, thinking tokens, text thường.
  static List<SuggestedTimeSlot> _parseTimeSlots(String rawText) {
    try {
      String cleaned = rawText.trim();

      // 1. Nếu có ```json ... ```, trích xuất phần trong code block
      final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(cleaned);
      if (codeBlockMatch != null) {
        cleaned = codeBlockMatch.group(1)!.trim();
      }

      // 2. Tìm JSON array pattern: [ ... ]
      final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
      if (arrayMatch != null) {
        cleaned = arrayMatch.group(0)!;
      }

      final List<dynamic> list = jsonDecode(cleaned);
      return list
          .map((item) => SuggestedTimeSlot(
                start: (item['start'] as String? ?? '09:00'),
                end: (item['end'] as String? ?? '10:00'),
                reason: (item['reason'] as String? ?? ''),
              ))
          .toList();
    } catch (e) {
      debugPrint('[GeminiService] Parse error: $e');
      debugPrint('[GeminiService] Raw text was: $rawText');
      throw Exception('Không thể phân tích kết quả từ AI. Vui lòng thử lại.');
    }
  }
}

// ─────────────────────── DATA MODELS ───────────────────────

/// Khung giờ họp được AI gợi ý
class SuggestedTimeSlot {
  final String start; // "HH:MM"
  final String end;   // "HH:MM"
  final String reason;

  const SuggestedTimeSlot({
    required this.start,
    required this.end,
    required this.reason,
  });

  int get startHour   => _parseHour(start);
  int get startMinute => _parseMinute(start);
  int get endHour     => _parseHour(end);
  int get endMinute   => _parseMinute(end);

  static int _parseHour(String t) {
    final p = t.split(':');
    return p.isNotEmpty ? (int.tryParse(p[0]) ?? 9) : 9;
  }

  static int _parseMinute(String t) {
    final p = t.split(':');
    return p.length >= 2 ? (int.tryParse(p[1]) ?? 0) : 0;
  }
}
